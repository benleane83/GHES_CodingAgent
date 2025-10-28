#!/bin/bash

# Script to assign an Azure DevOps Work Item to a user
# Usage: ./assign-workitem.sh <organization> <project> <work-item-id> <assignee-email>

set -e

# Function to display usage
show_usage() {
    echo "Usage: $0 <organization> <project> <work-item-id> <assignee-email>"
    echo ""
    echo "Arguments:"
    echo "  organization    : Azure DevOps organization name"
    echo "  project        : Project name (will be URL-encoded automatically)"
    echo "  work-item-id   : Work Item ID number"
    echo "  assignee-email : Email of the user to assign (use 'GitHub Copilot CLI' for the bot)"
    echo ""
    echo "Environment Variables Required:"
    echo "  AZURE_DEVOPS_PAT : Personal Access Token for authentication"
    echo ""
    echo "Example:"
    echo "  $0 myorg 'My Project' 372 'copilot@example.com'"
    echo "  $0 myorg 'My Project' 372 'GitHub Copilot CLI'"
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
ASSIGNEE="$4"

# Validate PAT
if [ -z "$AZURE_DEVOPS_PAT" ]; then
    echo "❌ Error: AZURE_DEVOPS_PAT environment variable is not set"
    echo "   Set it with: export AZURE_DEVOPS_PAT='your-pat-token'"
    exit 1
fi

# URL-encode the project name
PROJECT_ENCODED=$(echo "$PROJECT" | sed 's/ /%20/g')

echo "👤 Assigning Work Item in Azure DevOps"
echo "======================================="
echo "Organization: $ORGANIZATION"
echo "Project: $PROJECT"
echo "Work Item ID: $WORK_ITEM_ID"
echo "Assignee: $ASSIGNEE"
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
    "path": "/fields/System.AssignedTo",
    "value": "${ASSIGNEE}"
  }
]
EOF
)

echo "📝 Assigning work item..."
echo "-------------------------"

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
    echo "✅ Work item assigned successfully!"
    echo ""
    ASSIGNED_TO=$(echo "$BODY" | jq -r '.fields["System.AssignedTo"].displayName // .fields["System.AssignedTo"]')
    echo "📄 Assigned To: $ASSIGNED_TO"
    echo ""
    echo "======================================="
    echo "🎉 Work Item #${WORK_ITEM_ID} assigned!"
    echo "======================================="
    exit 0
else
    echo "❌ Error: Could not assign work item (HTTP $STATUS)"
    echo "📄 Response:"
    echo "$BODY" | jq '.' || echo "$BODY"
    exit 1
fi
