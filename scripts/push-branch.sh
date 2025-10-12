#!/bin/bash
set -e

# Script to push branch to remote
# Usage: push-branch.sh <organization> <project_name> <repo_name> <branch_name>

ORG="$1"
PROJECT_NAME="$2"
REPO_NAME="$3"
BRANCH_NAME="$4"

echo "🚀 Pushing branch to remote..."

# URL encode the project name and repository name
PROJECT_ENCODED=$(printf '%s' "$PROJECT_NAME" | jq -sRr @uri | tr -d '\n')
REPO_ENCODED=$(printf '%s' "$REPO_NAME" | jq -sRr @uri | tr -d '\n')

# Configure git remote with PAT
git remote set-url origin "https://build:${AZURE_DEVOPS_PAT}@dev.azure.com/${ORG}/${PROJECT_ENCODED}/_git/${REPO_ENCODED}"

git push -u origin "$BRANCH_NAME"

echo "✅ Branch pushed successfully"
