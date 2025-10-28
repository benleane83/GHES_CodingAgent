#!/bin/bash

# Script to update the state of an Azure DevOps Work Item
# Usage: ./update-workitem-state.sh <organization> <project> <work-item-id> <new-state>

set -e

# Function to display usage
show_usage() {
    echo "Usage: $0 <organization> <project> <work-item-id> <new-state>"
    echo ""
    echo "Arguments:"
    echo "  organization    : Azure DevOps organization name"
    echo "  project        : Project name (will be URL-encoded automatically)"
    echo "  work-item-id   : Work Item ID number"
    echo "  new-state      : New state value (e.g., 'Doing', 'Done', 'To Do')"
    echo ""
    echo "Environment Variables Required:"
    echo "  AZURE_DEVOPS_PAT : Personal Access Token for authentication"
    echo ""
    echo "Example:"
    echo "  $0 myorg 'My Project' 372 'Doing'"
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
NEW_STATE="$4"

# Validate PAT
if [ -z "$AZURE_DEVOPS_PAT" ]; then
    echo "❌ Error: AZURE_DEVOPS_PAT environment variable is not set"
    echo "   Set it with: export AZURE_DEVOPS_PAT='your-pat-token'"
    exit 1
fi

# URL-encode the project name
PROJECT_ENCODED=$(echo "$PROJECT" | sed 's/ /%20/g')

echo "🔄 Updating Work Item state in Azure DevOps"
echo "============================================"
echo "Organization: $ORGANIZATION"
echo "Project: $PROJECT"
echo "Work Item ID: $WORK_ITEM_ID"
echo "New State: $NEW_STATE"
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
    "path": "/fields/System.State",
    "value": "${NEW_STATE}"
  }
]
EOF
)

echo "📝 Updating state..."
echo "--------------------"

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
    echo "✅ State updated successfully!"
    echo ""
    CURRENT_STATE=$(echo "$BODY" | jq -r '.fields["System.State"]')
    echo "📄 Current State: $CURRENT_STATE"
    echo ""
    echo "============================================"
    echo "🎉 Work Item #${WORK_ITEM_ID} is now: ${CURRENT_STATE}"
    echo "============================================"
    exit 0
else
    echo "❌ Error: Could not update state (HTTP $STATUS)"
    echo "📄 Response:"
    echo "$BODY" | jq '.' || echo "$BODY"
    exit 1
fi
