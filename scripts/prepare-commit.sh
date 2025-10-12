#!/bin/bash
set -e

# Script to prepare commit message and commit changes
# Usage: prepare-commit.sh <work_item_id> <work_item_title> <project_name>

WORK_ITEM_ID="$1"
WORK_ITEM_TITLE="$2"
PROJECT_NAME="$3"
SCRIPTS_DIR="$(dirname "$0")"

echo "📝 Preparing commit..."

# Extract creator info from work item
CREATOR_INFO=$("$SCRIPTS_DIR/get-workitem.sh" "$WORK_ITEM_ID" "$PROJECT_NAME")
CREATOR_NAME=$(echo "$CREATOR_INFO" | grep "Created By Name:" | sed 's/Created By Name:[[:space:]]*//')
CREATOR_EMAIL=$(echo "$CREATOR_INFO" | grep "Created By Email:" | sed 's/Created By Email:[[:space:]]*//')

echo "👤 Co-author: $CREATOR_NAME <$CREATOR_EMAIL>"

# Add all files except metadata files
git add .
git reset HEAD copilot-summary.md 2>/dev/null || true
git reset HEAD commit-message.md 2>/dev/null || true
git reset HEAD .final-commit-msg.txt 2>/dev/null || true
git reset HEAD .github/copilot-instructions.md 2>/dev/null || true

# Prepare final commit message with co-author
if [ -f "commit-message.md" ]; then
  echo "✅ Using Copilot-generated commit message"
  cat commit-message.md > .final-commit-msg.txt
  echo "" >> .final-commit-msg.txt
  echo "" >> .final-commit-msg.txt
  echo "Co-authored-by: ${CREATOR_NAME} <${CREATOR_EMAIL}>" >> .final-commit-msg.txt
else
  echo "⚠️  commit-message.md not found, using default message"
  cat > .final-commit-msg.txt << EOF
feat: Implement work item ${WORK_ITEM_ID}

${WORK_ITEM_TITLE}

Changes implemented by GitHub Copilot CLI

Co-authored-by: ${CREATOR_NAME} <${CREATOR_EMAIL}>
EOF
fi

# Create commit
git commit -F .final-commit-msg.txt

# Clean up
rm -f .final-commit-msg.txt

echo "✅ Changes committed"
