#!/bin/bash

# Pipeline script to create PR with all parameters
# Usage: ./pipeline-create-pr.sh <work-item-id> <work-item-title> <project-name> <repo-name> <source-branch>

set -e

WORK_ITEM_ID=$1
WORK_ITEM_TITLE=$2
PROJECT_NAME=$3
REPO_NAME=$4
SOURCE_BRANCH=$5

echo "📬 Creating Pull Request..."
ORG=$(echo $SYSTEM_COLLECTIONURI | sed 's|https://dev.azure.com/||' | sed 's|/.*||')

# Get repository ID
REPO_ID=$(az repos show \
  --org "https://dev.azure.com/${ORG}" \
  --project "$PROJECT_NAME" \
  --repository "$REPO_NAME" \
  --query id -o tsv)

echo "📊 Repository ID: $REPO_ID"

# Extract creator email
CREATOR_EMAIL=$(./scripts/get-workitem.sh "$WORK_ITEM_ID" "$PROJECT_NAME" | grep "Created By Email:" | sed 's/Created By Email:[[:space:]]*//')

echo "📧 Creator Email: $CREATOR_EMAIL"

# Create PR title
PR_TITLE="AB#${WORK_ITEM_ID}: ${WORK_ITEM_TITLE}"

# Create PR description
PR_DESC=$(cat /tmp/copilot-summary.md)

echo "📝 PR Title: $PR_TITLE"

# Create PR with required reviewer
./scripts/create-pr-with-required-reviewer.sh \
  "$ORG" \
  "$PROJECT_NAME" \
  "$REPO_ID" \
  "copilot/${WORK_ITEM_ID}" \
  "$SOURCE_BRANCH" \
  "$PR_TITLE" \
  "$PR_DESC" \
  "$CREATOR_EMAIL"

echo "✅ Pull Request created successfully"
