#!/bin/bash

# Script to link a Git branch to an Azure DevOps work item using Azure Boards CLI
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
# Format: vstfs:///Git/Ref/{ProjectId}/{RepositoryId}/GB{BranchName}
ENCODED_BRANCH=$(echo "$BRANCH_NAME" | sed 's/\//%2F/g')
ARTIFACT_URI="vstfs:///Git/Ref/${PROJECT_ID}%2F${REPO_ID}%2FGB${ENCODED_BRANCH}"

echo "🔗 Artifact URI: $ARTIFACT_URI"

# Link the branch to the work item using az boards CLI
echo "🔗 Creating link..."
az boards work-item relation add \
  --org "https://dev.azure.com/${ORG}" \
  --id "$WORK_ITEM_ID" \
  --relation-type "ArtifactLink" \
  --target-url "$ARTIFACT_URI" \
  --output table

echo ""
echo "✅ Branch successfully linked to work item #${WORK_ITEM_ID}"
