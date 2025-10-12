#!/bin/bash
set -e

# Script to clone target repository with authentication
# Usage: clone-target-repo.sh <target_repo_name> <project_name> <current_repo_name>

TARGET_REPO="$1"
PROJECT_NAME="$2"
CURRENT_REPO="$3"

# Extract organization from collection URI
ORG=$(echo $SYSTEM_COLLECTIONURI | sed 's|https://dev.azure.com/||' | sed 's|/.*||')

# Get working directory from environment or use current directory
WORK_DIR="${SYSTEM_DEFAULTWORKINGDIRECTORY:-$(pwd)}"

if [ "$TARGET_REPO" != "$CURRENT_REPO" ]; then
  echo "🛎️ Cloning target repository: $TARGET_REPO"
  
  # URL encode the project name and repository name
  PROJECT_ENCODED=$(printf '%s' "$PROJECT_NAME" | jq -sRr @uri | tr -d '\n')
  REPO_ENCODED=$(printf '%s' "$TARGET_REPO" | jq -sRr @uri | tr -d '\n')
  
  # Clone with authentication
  git clone "https://build:${AZURE_DEVOPS_PAT}@dev.azure.com/${ORG}/${PROJECT_ENCODED}/_git/${REPO_ENCODED}" target-repo
  cd target-repo
  git config user.email "copilot-cli@azure.com"
  git config user.name "GitHub Copilot CLI"
else
  echo "✅ Using current repository."
  mkdir -p target-repo
  rsync -a --exclude target-repo ./ target-repo/
  cd target-repo
  git config user.email "copilot-cli@azure.com"
  git config user.name "GitHub Copilot CLI"
fi

echo "##vso[task.setvariable variable=TargetRepoDir]${WORK_DIR}/target-repo"
echo "✅ Repository ready at: ${WORK_DIR}/target-repo"
