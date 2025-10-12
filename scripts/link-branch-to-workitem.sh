#!/bin/bash

# Script to link a Git branch to an Azure DevOps work item using REST API
# Usage: ./link-branch-to-workitem.sh <work-item-id> <project-name> <repo-name> <branch-name>

set -e

WORK_ITEM_ID=$1
PROJECT_NAME=$2
REPO_NAME=$3
BRANCH_NAME=$4

if [ $# -ne 4 ]; then
    echo "❌ Error: Incorrect number of arguments"
    echo "Usage: $0 <work-item-id> <project-name> <repo-name> <branch-name>"
    exit 1
fi

if [ -z "$AZURE_DEVOPS_PAT" ]; then
    echo "❌ Error: AZURE_DEVOPS_PAT environment variable is not set"
    exit 1
fi

# Get organization from system collection URI
ORG=$(echo $SYSTEM_COLLECTIONURI | sed 's|https://dev.azure.com/||' | sed 's|/.*||')

echo "🔗 Linking branch to work item..."
echo "=================================================="
echo "Organization: $ORG"
echo "Project: $PROJECT_NAME"
echo "Repository: $REPO_NAME"
echo "Branch: $BRANCH_NAME"
echo "Work Item ID: $WORK_ITEM_ID"
echo ""

# Configure Azure CLI to use the PAT
export AZURE_DEVOPS_EXT_PAT=$AZURE_DEVOPS_PAT

# Get repository ID
echo "📊 Getting repository ID..."
REPO_ID=$(az repos show \
  --org "https://dev.azure.com/${ORG}" \
  --project "$PROJECT_NAME" \
  --repository "$REPO_NAME" \
  --query id -o tsv)

if [ -z "$REPO_ID" ] || [ "$REPO_ID" = "null" ]; then
    echo "❌ Error: Could not get repository ID"
    exit 1
fi

echo "✅ Repository ID: $REPO_ID"

# Get project ID
echo "📊 Getting project ID..."
PROJECT_ID=$(az devops project show \
  --org "https://dev.azure.com/${ORG}" \
  --project "$PROJECT_NAME" \
  --query id -o tsv)

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "null" ]; then
    echo "❌ Error: Could not get project ID"
    exit 1
fi

echo "✅ Project ID: $PROJECT_ID"

# Create the artifact URI for the branch
# Format: vstfs:///Git/Ref/{ProjectId}/{RepositoryId}/refs/heads/{BranchName}
ARTIFACT_URI="vstfs:///Git/Ref/${PROJECT_ID}/${REPO_ID}/refs/heads/${BRANCH_NAME}"

echo "🔗 Artifact URI: $ARTIFACT_URI"

# URL encode the project name
PROJECT_ENCODED=$(printf '%s' "$PROJECT_NAME" | jq -sRr @uri | tr -d '\n')

# Link the branch to the work item using REST API
echo "🔗 Creating link using REST API..."
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X PATCH \
  -H "Content-Type: application/json-patch+json" \
  -H "Authorization: Basic $(echo -n ":${AZURE_DEVOPS_PAT}" | base64 | tr -d '\n')" \
  -d "[{\"op\":\"add\",\"path\":\"/relations/-\",\"value\":{\"rel\":\"ArtifactLink\",\"url\":\"${ARTIFACT_URI}\",\"attributes\":{\"name\":\"Branch\"}}}]" \
  "https://dev.azure.com/${ORG}/${PROJECT_ENCODED}/_apis/wit/workitems/${WORK_ITEM_ID}?api-version=7.1-preview.3")

# Extract HTTP status
HTTP_STATUS=$(echo "$RESPONSE" | tr -d '\n' | sed -e 's/.*HTTP_STATUS://')
RESPONSE_BODY=$(echo "$RESPONSE" | sed -e 's/HTTP_STATUS\:.*//g')

if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "✅ Branch successfully linked to work item #${WORK_ITEM_ID}"
else
    echo "❌ Error: Failed to link branch (HTTP $HTTP_STATUS)"
    echo "$RESPONSE_BODY"
    exit 1
fi
