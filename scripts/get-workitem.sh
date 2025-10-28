#!/bin/bash

# Script to retrieve information from an Azure DevOps Work Item
# Usage: ./get-workitem.sh <work-item-id> [project]

set -e

# Function to display usage
show_usage() {
    echo "Usage: $0 <work-item-id> [project]"
    echo ""
    echo "Arguments:"
    echo "  work-item-id     : Work Item ID number (required)"
    echo "  project          : Project name (optional, uses System.TeamProject env var if not provided)"
    echo ""
    echo "Environment Variables:"
    echo "  AZURE_DEVOPS_PAT         : Personal Access Token for authentication (required)"
    echo "  SYSTEM_COLLECTIONURI     : Azure DevOps organization URL (required, Azure Pipelines format)"
    echo "  System_CollectionUri     : Azure DevOps organization URL (alternative format)"
    echo "  SYSTEM_TEAMPROJECT       : Project name (Azure Pipelines format, used if project argument not provided)"
    echo "  System_TeamProject       : Project name (alternative format, used if project argument not provided)"
    echo ""
    echo "Examples:"
    echo "  $0 412"
    echo "  $0 412 'GitHub Copilot CLI'"
    echo "  $0 412 'My Project Name'"
    exit 1
}

# Validate arguments
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "❌ Error: Incorrect number of arguments (expected 1-2, got $#)"
    echo ""
    show_usage
fi

WORK_ITEM_ID="$1"

# Get the project (argument or environment variable)
# Azure Pipelines uses SYSTEM_TEAMPROJECT (uppercase)
if [ $# -eq 2 ]; then
    PROJECT="$2"
elif [ -n "$SYSTEM_TEAMPROJECT" ]; then
    PROJECT="$SYSTEM_TEAMPROJECT"
elif [ -n "$System_TeamProject" ]; then
    PROJECT="$System_TeamProject"
else
    echo "❌ Error: Project name not provided and neither SYSTEM_TEAMPROJECT nor System_TeamProject environment variable is set"
    echo ""
    show_usage
fi

# Extract organization from System_CollectionUri or SYSTEM_COLLECTIONURI
# Azure Pipelines uses SYSTEM_COLLECTIONURI (uppercase)
COLLECTION_URI="${System_CollectionUri:-$SYSTEM_COLLECTIONURI}"

if [ -z "$COLLECTION_URI" ]; then
    echo "❌ Error: Neither System_CollectionUri nor SYSTEM_COLLECTIONURI environment variable is set"
    echo "   Example: export SYSTEM_COLLECTIONURI='https://dev.azure.com/myorg/'"
    exit 1
fi

# Extract the organization name from the URL
ORGANIZATION=$(echo "$COLLECTION_URI" | sed -E 's|https://dev\.azure\.com/([^/]+)/?|\1|')

# Validate PAT
if [ -z "$AZURE_DEVOPS_PAT" ]; then
    echo "❌ Error: AZURE_DEVOPS_PAT environment variable is not set"
    echo "   Set it with: export AZURE_DEVOPS_PAT='your-pat-token'"
    exit 1
fi

# URL-encode the project name using jq for better compatibility
# If jq is not available, use sed as fallback
if command -v jq &> /dev/null; then
    PROJECT_ENCODED=$(echo -n "$PROJECT" | jq -sRr @uri)
else
    PROJECT_ENCODED=$(echo "$PROJECT" | sed 's/ /%20/g')
fi

echo "🔍 Retrieving Work Item from Azure DevOps"
echo "=========================================="
echo "Organization: $ORGANIZATION"
echo "Project: $PROJECT"
echo "Project (encoded): $PROJECT_ENCODED"
echo "Work Item ID: $WORK_ITEM_ID"
echo ""

# Encode PAT in Base64 (without line breaks)
# Use -w 0 to avoid line breaks on Linux systems
if base64 --help 2>&1 | grep -q "wrap"; then
    # GNU base64 (Linux)
    PAT_BASE64=$(echo -n ":${AZURE_DEVOPS_PAT}" | base64 -w 0)
else
    # BSD base64 (macOS) or systems without -w
    PAT_BASE64=$(echo -n ":${AZURE_DEVOPS_PAT}" | base64 | tr -d '\n')
fi

# Get the work item
API_URL="https://dev.azure.com/${ORGANIZATION}/${PROJECT_ENCODED}/_apis/wit/workitems/${WORK_ITEM_ID}?api-version=7.0"

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  "$API_URL" \
  -H "Authorization: Basic ${PAT_BASE64}" \
  -H "Content-Type: application/json")

BODY=$(echo "$RESPONSE" | sed -e 's/HTTP_STATUS\:.*//g')
STATUS=$(echo "$RESPONSE" | tr -d '\n' | sed -e 's/.*HTTP_STATUS://')

if [ "$STATUS" -ne 200 ]; then
    echo "❌ Error: Could not retrieve work item (HTTP $STATUS)"
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    exit 1
fi

echo "✅ Work item retrieved successfully!"
echo ""
echo "================================================"
echo "📋 Work Item Details"
echo "================================================"

# Extract key information
TITLE=$(echo "$BODY" | jq -r '.fields["System.Title"]')
STATE=$(echo "$BODY" | jq -r '.fields["System.State"]')
WORK_ITEM_TYPE=$(echo "$BODY" | jq -r '.fields["System.WorkItemType"]')
ASSIGNED_TO=$(echo "$BODY" | jq -r '.fields["System.AssignedTo"].displayName // "Unassigned"')
CREATED_BY=$(echo "$BODY" | jq -r '.fields["System.CreatedBy"].displayName')
CREATED_BY_EMAIL=$(echo "$BODY" | jq -r '.fields["System.CreatedBy"].uniqueName')
CREATED_DATE=$(echo "$BODY" | jq -r '.fields["System.CreatedDate"]')
ACTIVITY=$(echo "$BODY" | jq -r '.fields["Microsoft.VSTS.Common.Activity"] // "Not set"')
DESCRIPTION=$(echo "$BODY" | jq -r '.fields["System.Description"] // "No description"')

echo "ID:              $WORK_ITEM_ID"
echo "Type:            $WORK_ITEM_TYPE"
echo "Title:           $TITLE"
echo "State:           $STATE"
echo "Activity:        $ACTIVITY"
echo "Assigned To:     $ASSIGNED_TO"
echo "Created By:      $CREATED_BY ($CREATED_BY_EMAIL)"
echo "Created Date:    $CREATED_DATE"
echo ""
echo "Description:"
echo "---"
# Remove basic HTML tags for better readability
echo "$DESCRIPTION" | sed 's/<[^>]*>//g' | sed 's/&nbsp;/ /g' | head -20
echo ""
echo "================================================"
echo ""

# Información útil para otros scripts
echo "📝 Extracted Information for Scripts:"
echo "---"
echo "Project:              $PROJECT"
echo "Created By Name:      $CREATED_BY"
echo "Created By Email:     $CREATED_BY_EMAIL"
echo "Work Item Type:       $WORK_ITEM_TYPE"
echo "Current State:        $STATE"
echo "Current Activity:     $ACTIVITY"
echo ""

# Show full JSON response optionally
if [ "$VERBOSE" = "true" ]; then
    echo "================================================"
    echo "📄 Full JSON Response:"
    echo "================================================"
    echo "$BODY" | jq '.'
fi

# Return success
exit 0
