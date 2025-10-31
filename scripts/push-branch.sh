#!/bin/bash
set -e

# Script to push branch to remote (GHES)
# Usage: ./push-branch.sh <branch_name>

BRANCH_NAME="$1"

if [ -z "$BRANCH_NAME" ]; then
  echo "❌ Error: Branch name is required"
  echo "Usage: $0 <branch_name>"
  exit 1
fi

echo "🚀 Pushing branch to remote..."

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

echo "✅ Branch pushed successfully"
