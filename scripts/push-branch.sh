#!/bin/bash
set -e

# Script to push branch to remote
# Usage (GHES): push-branch.sh <branch_name>
# Usage (ADO): push-branch.sh <organization> <project_name> <repo_name> <branch_name>

if [ $# -eq 1 ]; then
  # GHES mode: single parameter (branch name)
  BRANCH_NAME="$1"
  
  echo "🚀 Pushing branch to remote (GHES mode)..."
  
  if [ -z "$GH_TOKEN" ]; then
    echo "❌ Error: GH_TOKEN environment variable is not set"
    exit 1
  fi
  
  # Configure git remote with GH_TOKEN
  REMOTE_URL=$(git remote get-url origin)
  if [[ "$REMOTE_URL" == https://* ]]; then
    # Extract repo path from HTTPS URL
    REPO_PATH=$(echo "$REMOTE_URL" | sed 's|https://[^/]*/||')
    GITHUB_HOST=$(echo "$REMOTE_URL" | sed 's|https://||' | sed 's|/.*||')
    git remote set-url origin "https://x-access-token:${GH_TOKEN}@${GITHUB_HOST}/${REPO_PATH}"
  fi
  
  git push -u origin "$BRANCH_NAME"
  
elif [ $# -eq 4 ]; then
  # ADO mode: four parameters (backwards compatibility)
  ORG="$1"
  PROJECT_NAME="$2"
  REPO_NAME="$3"
  BRANCH_NAME="$4"
  
  echo "🚀 Pushing branch to remote (ADO mode)..."
  
  # URL encode the project name and repository name
  PROJECT_ENCODED=$(printf '%s' "$PROJECT_NAME" | jq -sRr @uri | tr -d '\n')
  REPO_ENCODED=$(printf '%s' "$REPO_NAME" | jq -sRr @uri | tr -d '\n')
  
  # Configure git remote with PAT
  git remote set-url origin "https://build:${AZURE_DEVOPS_PAT}@dev.azure.com/${ORG}/${PROJECT_ENCODED}/_git/${REPO_ENCODED}"
  
  git push -u origin "$BRANCH_NAME"
  
else
  echo "❌ Error: Invalid number of parameters"
  echo "Usage (GHES): push-branch.sh <branch_name>"
  echo "Usage (ADO): push-branch.sh <organization> <project_name> <repo_name> <branch_name>"
  exit 1
fi

echo "✅ Branch pushed successfully"
