#!/bin/bash

# Script to update the Activity field of an Azure DevOps Work Item
# Usage: ./update-workitem-activity.sh <organization> <project> <work-item-id> <activity>

set -e

# Function to display usage
show_usage() {
    echo "Usage: $0 <organization> <project> <work-item-id> <activity>"
    echo ""
    echo "Arguments:"
    echo "  organization    : Azure DevOps organization name"
    echo "  project        : Project name (will be URL-encoded automatically)"
    echo "  work-item-id   : Work Item ID number"
    echo "  activity       : Activity value"
    echo ""
    echo "Valid Activity values:"
    echo "  - Deployment     : For deployment-related tasks, CI/CD, infrastructure"
    echo "  - Design         : For architectural design, UI/UX design work"
    echo "  - Development    : For coding, implementation, feature development (most common)"
    echo "  - Documentation  : For writing docs, README updates, code comments"
    echo "  - Requirements   : For gathering or defining requirements"
    echo "  - Testing        : For writing tests, QA work, test automation"
    echo ""
    echo "Environment Variables Required:"
    echo "  AZURE_DEVOPS_PAT : Personal Access Token for authentication"
    echo ""
    echo "Example:"
    echo "  $0 myorg 'My Project' 372 'Development'"
    exit 1
}

# Validate arguments
if [ $# -ne 4 ]; then
    echo "❌ Error: Incorrect number of arguments"
    echo ""
    show_usage
fi

ORGANIZATION="$1"
PROJECT="$2"
WORK_ITEM_ID="$3"
ACTIVITY="$4"

# Validate PAT
if [ -z "$AZURE_DEVOPS_PAT" ]; then
    echo "❌ Error: AZURE_DEVOPS_PAT environment variable is not set"
    echo "   Set it with: export AZURE_DEVOPS_PAT='your-pat-token'"
    exit 1
fi

# Validate Activity value
VALID_ACTIVITIES=("Deployment" "Design" "Development" "Documentation" "Requirements" "Testing")
if [[ ! " ${VALID_ACTIVITIES[@]} " =~ " ${ACTIVITY} " ]]; then
    echo "⚠️  Warning: '${ACTIVITY}' may not be a valid Activity value"
    echo "   Valid values: ${VALID_ACTIVITIES[*]}"
    echo ""
fi

# URL-encode the project name
PROJECT_ENCODED=$(echo "$PROJECT" | sed 's/ /%20/g')

echo "📊 Updating Work Item Activity field in Azure DevOps"
echo "====================================================="
echo "Organization: $ORGANIZATION"
echo "Project: $PROJECT"
echo "Work Item ID: $WORK_ITEM_ID"
echo "Activity: $ACTIVITY"
echo ""

# Encode PAT in Base64 (without line breaks)
if base64 --help 2>&1 | grep -q "wrap"; then
    PAT_BASE64=$(echo -n ":${AZURE_DEVOPS_PAT}" | base64 -w 0)
else
    PAT_BASE64=$(echo -n ":${AZURE_DEVOPS_PAT}" | base64 | tr -d '\n')
fi

# Endpoint to update work item
API_URL="https://dev.azure.com/${ORGANIZATION}/${PROJECT_ENCODED}/_apis/wit/workitems/${WORK_ITEM_ID}?api-version=7.0"

# Request Body (JSON Patch format)
REQUEST_BODY=$(cat <<EOF
[
  {
    "op": "add",
    "path": "/fields/Microsoft.VSTS.Common.Activity",
    "value": "${ACTIVITY}"
  }
]
EOF
)

echo "📝 Updating Activity field..."
echo "------------------------------"

# Make the request
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X PATCH \
  "$API_URL" \
  -H "Content-Type: application/json-patch+json" \
  -H "Authorization: Basic ${PAT_BASE64}" \
  -d "$REQUEST_BODY")

# Extract response body and HTTP status
BODY=$(echo "$RESPONSE" | sed -e 's/HTTP_STATUS\:.*//g')
STATUS=$(echo "$RESPONSE" | tr -d '\n' | sed -e 's/.*HTTP_STATUS://')

echo "📊 HTTP Status: $STATUS"
echo ""

if [ "$STATUS" -eq 200 ]; then
    echo "✅ Activity field updated successfully!"
    echo ""
    CURRENT_ACTIVITY=$(echo "$BODY" | jq -r '.fields["Microsoft.VSTS.Common.Activity"]')
    echo "📄 Current Activity: $CURRENT_ACTIVITY"
    echo ""
    echo "====================================================="
    echo "🎉 Work Item #${WORK_ITEM_ID} Activity: ${CURRENT_ACTIVITY}"
    echo "====================================================="
    exit 0
else
    echo "❌ Error: Could not update Activity field (HTTP $STATUS)"
    echo "📄 Response:"
    echo "$BODY" | jq '.' || echo "$BODY"
    exit 1
fi
