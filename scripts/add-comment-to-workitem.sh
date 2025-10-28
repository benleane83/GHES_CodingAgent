#!/bin/bash

# Script to add a comment to an Azure DevOps Work Item
# Usage: ./add-comment-to-workitem.sh <organization> <project> <work-item-id> <comment-text>

set -e

# Function to display usage
show_usage() {
    echo "Usage: $0 <organization> <project> <work-item-id> <comment-text>"
    echo ""
    echo "Arguments:"
    echo "  organization    : Azure DevOps organization name"
    echo "  project        : Project name (will be URL-encoded automatically)"
    echo "  work-item-id   : Work Item ID number"
    echo "  comment-text   : Comment text (HTML format supported)"
    echo ""
    echo "Environment Variables Required:"
    echo "  AZURE_DEVOPS_PAT : Personal Access Token for authentication"
    echo ""
    echo "Example:"
    echo "  $0 myorg 'My Project' 372 '👀🤖 Started working on this task'"
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
COMMENT_TEXT="$4"

# Validate PAT
if [ -z "$AZURE_DEVOPS_PAT" ]; then
    echo "❌ Error: AZURE_DEVOPS_PAT environment variable is not set"
    echo "   Set it with: export AZURE_DEVOPS_PAT='your-pat-token'"
    exit 1
fi

# URL-encode the project name
PROJECT_ENCODED=$(echo "$PROJECT" | sed 's/ /%20/g')

echo "💬 Adding comment to Azure DevOps Work Item"
echo "============================================"
echo "Organization: $ORGANIZATION"
echo "Project: $PROJECT"
echo "Work Item ID: $WORK_ITEM_ID"
echo "Comment: $COMMENT_TEXT"
echo ""

# Encode PAT in Base64 (without line breaks)
if base64 --help 2>&1 | grep -q "wrap"; then
    PAT_BASE64=$(echo -n ":${AZURE_DEVOPS_PAT}" | base64 -w 0)
else
    PAT_BASE64=$(echo -n ":${AZURE_DEVOPS_PAT}" | base64 | tr -d '\n')
fi

# Endpoint to add comment
API_URL="https://dev.azure.com/${ORGANIZATION}/${PROJECT_ENCODED}/_apis/wit/workItems/${WORK_ITEM_ID}/comments?api-version=7.0-preview.3"

# Request Body
REQUEST_BODY=$(cat <<EOF
{
  "text": "${COMMENT_TEXT}"
}
EOF
)

echo "📝 Adding comment..."
echo "--------------------"

# Make the request
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST \
  "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic ${PAT_BASE64}" \
  -d "$REQUEST_BODY")

# Extract response body and HTTP status
BODY=$(echo "$RESPONSE" | sed -e 's/HTTP_STATUS\:.*//g')
STATUS=$(echo "$RESPONSE" | tr -d '\n' | sed -e 's/.*HTTP_STATUS://')

echo "📊 HTTP Status: $STATUS"
echo ""

if [ "$STATUS" -eq 200 ]; then
    echo "✅ Comment added successfully!"
    echo ""
    COMMENT_ID=$(echo "$BODY" | jq -r '.id')
    echo "📄 Comment ID: $COMMENT_ID"
    echo ""
    echo "============================================"
    echo "🎉 Comment added to Work Item #${WORK_ITEM_ID}"
    echo "============================================"
    exit 0
else
    echo "❌ Error: Could not add comment (HTTP $STATUS)"
    echo "📄 Response:"
    echo "$BODY" | jq '.' || echo "$BODY"
    exit 1
fi
