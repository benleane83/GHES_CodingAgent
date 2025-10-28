#!/bin/bash

# Script to create a PR in Azure DevOps with a Required Reviewer
# Usage: ./create-pr-with-required-reviewer.sh <organization> <project> <repository-id> <source-branch> <target-branch> <title> <description> <reviewer-email>

set -e

# Function to display usage
show_usage() {
    echo "Usage: $0 <organization> <project> <repository-id> <source-branch> <target-branch> <title> <description> <reviewer-email>"
    echo ""
    echo "Arguments:"
    echo "  organization      : Azure DevOps organization name"
    echo "  project          : Project name (will be URL-encoded automatically)"
    echo "  repository-id    : Repository GUID"
    echo "  source-branch    : Source branch name (e.g., 'copilot/123')"
    echo "  target-branch    : Target branch name (e.g., 'main')"
    echo "  title            : PR title"
    echo "  description      : PR description"
    echo "  reviewer-email   : Email address of the required reviewer"
    echo ""
    echo "Environment Variables Required:"
    echo "  AZURE_DEVOPS_PAT : Personal Access Token for authentication"
    echo ""
    echo "Example:"
    echo "  $0 myorg 'My Project' abc-123 'copilot/123' 'main' 'Fix bug' 'Description here' user@example.com"
    exit 1
}

# Validate arguments
if [ $# -ne 8 ]; then
    echo "❌ Error: Incorrect number of arguments (expected 8, got $#)"
    echo ""
    show_usage
fi

ORGANIZATION="$1"
PROJECT="$2"
REPOSITORY_ID="$3"
SOURCE_BRANCH="$4"
TARGET_BRANCH="$5"
TITLE="$6"
DESCRIPTION="$7"
REVIEWER_EMAIL="$8"

# Validate PAT
if [ -z "$AZURE_DEVOPS_PAT" ]; then
    echo "❌ Error: AZURE_DEVOPS_PAT environment variable is not set"
    echo "   Set it with: export AZURE_DEVOPS_PAT='your-pat-token'"
    exit 1
fi

# URL-encode the project name
PROJECT_ENCODED=$(echo "$PROJECT" | sed 's/ /%20/g')

echo "🔧 Creating Azure DevOps PR with Required Reviewer"
echo "=================================================="
echo "Organization: $ORGANIZATION"
echo "Project: $PROJECT"
echo "Repository ID: $REPOSITORY_ID"
echo "Source Branch: $SOURCE_BRANCH"
echo "Target Branch: $TARGET_BRANCH"
echo "Title: $TITLE"
echo "Reviewer Email: $REVIEWER_EMAIL"
echo ""

# Encode PAT in Base64 (without line breaks)
if base64 --help 2>&1 | grep -q "wrap"; then
    PAT_BASE64=$(echo -n ":${AZURE_DEVOPS_PAT}" | base64 -w 0)
else
    PAT_BASE64=$(echo -n ":${AZURE_DEVOPS_PAT}" | base64 | tr -d '\n')
fi

# Step 1: Get the reviewer's Identity ID
echo "📋 Step 1: Finding reviewer Identity ID..."
echo "-------------------------------------------"

# Get the project team
TEAM_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  "https://dev.azure.com/${ORGANIZATION}/_apis/projects/${PROJECT_ENCODED}/teams?api-version=7.0" \
  -H "Authorization: Basic ${PAT_BASE64}")

TEAM_BODY=$(echo "$TEAM_RESPONSE" | sed -e 's/HTTP_STATUS\:.*//g')
TEAM_STATUS=$(echo "$TEAM_RESPONSE" | tr -d '\n' | sed -e 's/.*HTTP_STATUS://')

if [ "$TEAM_STATUS" -ne 200 ]; then
    echo "❌ Error: Could not get project teams (HTTP $TEAM_STATUS)"
    echo "$TEAM_BODY"
    exit 1
fi

TEAM_ID=$(echo "$TEAM_BODY" | jq -r '.value[0].id')

if [ -z "$TEAM_ID" ] || [ "$TEAM_ID" = "null" ]; then
    echo "❌ Error: Could not find team ID for project"
    exit 1
fi

echo "✅ Team ID: $TEAM_ID"

# Get team members and search by email
MEMBERS_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  "https://dev.azure.com/${ORGANIZATION}/_apis/projects/${PROJECT_ENCODED}/teams/${TEAM_ID}/members?api-version=7.0" \
  -H "Authorization: Basic ${PAT_BASE64}")

MEMBERS_BODY=$(echo "$MEMBERS_RESPONSE" | sed -e 's/HTTP_STATUS\:.*//g')
MEMBERS_STATUS=$(echo "$MEMBERS_RESPONSE" | tr -d '\n' | sed -e 's/.*HTTP_STATUS://')

if [ "$MEMBERS_STATUS" -ne 200 ]; then
    echo "❌ Error: Could not get team members (HTTP $MEMBERS_STATUS)"
    echo "$MEMBERS_BODY"
    exit 1
fi

REVIEWER_ID=$(echo "$MEMBERS_BODY" | jq -r --arg email "$REVIEWER_EMAIL" '.value[] | select(.identity.uniqueName == $email) | .identity.id')

if [ -z "$REVIEWER_ID" ] || [ "$REVIEWER_ID" = "null" ]; then
    echo "❌ Error: Could not find user with email: $REVIEWER_EMAIL"
    echo "   Make sure the user is a member of the project team"
    exit 1
fi

REVIEWER_NAME=$(echo "$MEMBERS_BODY" | jq -r --arg email "$REVIEWER_EMAIL" '.value[] | select(.identity.uniqueName == $email) | .identity.displayName')

echo "✅ Found reviewer: $REVIEWER_NAME"
echo "✅ Identity ID: $REVIEWER_ID"
echo ""

# Step 2: Create the Pull Request in Draft mode with the reviewer as required
echo "📝 Step 2: Creating Pull Request in Draft mode..."
echo "-------------------------------------------"

# Escape quotes in title and description for JSON
TITLE_ESCAPED=$(echo "$TITLE" | sed 's/"/\\"/g')
DESCRIPTION_ESCAPED=$(echo "$DESCRIPTION" | sed 's/"/\\"/g' | sed 's/$/\\n/g' | tr -d '\n' | sed 's/\\n$//')

API_URL="https://dev.azure.com/${ORGANIZATION}/${PROJECT_ENCODED}/_apis/git/repositories/${REPOSITORY_ID}/pullrequests?api-version=7.0"

REQUEST_BODY=$(cat <<EOF
{
  "sourceRefName": "refs/heads/${SOURCE_BRANCH}",
  "targetRefName": "refs/heads/${TARGET_BRANCH}",
  "title": "${TITLE_ESCAPED}",
  "description": "${DESCRIPTION_ESCAPED}",
  "isDraft": true,
  "reviewers": [
    {
      "id": "${REVIEWER_ID}",
      "isRequired": true
    }
  ],
  "labels": [
    {
      "name": "copilot"
    }
  ]
}
EOF
)

CREATE_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST \
  "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic ${PAT_BASE64}" \
  -d "$REQUEST_BODY")

CREATE_BODY=$(echo "$CREATE_RESPONSE" | sed -e 's/HTTP_STATUS\:.*//g')
CREATE_STATUS=$(echo "$CREATE_RESPONSE" | tr -d '\n' | sed -e 's/.*HTTP_STATUS://')

if [ "$CREATE_STATUS" -ne 201 ]; then
    echo "❌ Error: Could not create PR (HTTP $CREATE_STATUS)"
    echo "$CREATE_BODY" | jq '.' 2>/dev/null || echo "$CREATE_BODY"
    exit 1
fi

PR_ID=$(echo "$CREATE_BODY" | jq -r '.pullRequestId')
PR_URL=$(echo "$CREATE_BODY" | jq -r '.url' | sed 's/_apis.*//g' | sed "s/$/pullrequest\/${PR_ID}/")

echo "✅ Pull Request created successfully!"
echo "✅ PR ID: $PR_ID"
echo "✅ PR URL: $PR_URL"
echo ""

# Step 3: Verify that the reviewer is Required
echo "🔍 Step 3: Verifying Required Reviewer status..."
echo "-------------------------------------------"

# Get reviewer information
VERIFY_URL="https://dev.azure.com/${ORGANIZATION}/${PROJECT_ENCODED}/_apis/git/repositories/${REPOSITORY_ID}/pullRequests/${PR_ID}/reviewers?api-version=6.1-preview.1"

VERIFY_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  "$VERIFY_URL" \
  -H "Authorization: Basic ${PAT_BASE64}")

VERIFY_BODY=$(echo "$VERIFY_RESPONSE" | sed -e 's/HTTP_STATUS\:.*//g')
VERIFY_STATUS=$(echo "$VERIFY_RESPONSE" | tr -d '\n' | sed -e 's/.*HTTP_STATUS://')

if [ "$VERIFY_STATUS" -ne 200 ]; then
    echo "⚠️  Warning: Could not verify reviewer status (HTTP $VERIFY_STATUS)"
    echo "$VERIFY_BODY"
else
    REVIEWER_DISPLAY_NAME=$(echo "$VERIFY_BODY" | jq -r --arg id "$REVIEWER_ID" '.value[] | select(.id == $id) | .displayName')
    REVIEWER_IS_REQUIRED=$(echo "$VERIFY_BODY" | jq -r --arg id "$REVIEWER_ID" '.value[] | select(.id == $id) | .isRequired')
    
    echo "✅ Reviewer: $REVIEWER_DISPLAY_NAME"
    echo "✅ Email: $REVIEWER_EMAIL"
    echo "✅ isRequired: $REVIEWER_IS_REQUIRED"
    
    if [ "$REVIEWER_IS_REQUIRED" = "true" ]; then
        echo ""
        echo "✅✅✅ SUCCESS: Reviewer is REQUIRED"
    else
        echo ""
        echo "⚠️  WARNING: Reviewer is NOT required (this shouldn't happen)"
        exit 1
    fi
fi

echo ""
echo "================================================"
echo "🎉 PR created successfully with Required Reviewer!"
echo "================================================"
echo "PR ID: $PR_ID"
echo "PR URL: $PR_URL"
echo "Required Reviewer: $REVIEWER_NAME ($REVIEWER_EMAIL)"
echo ""

# Return the PR ID so it can be used by the caller
echo "$PR_ID"
