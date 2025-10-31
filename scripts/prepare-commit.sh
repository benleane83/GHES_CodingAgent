#!/bin/bash
set -e

# Script to prepare commit message and commit changes
# Usage: prepare-commit.sh <issue_number> <issue_title> <creator_username>

ISSUE_NUMBER="$1"
ISSUE_TITLE="$2"
CREATOR_USERNAME="$3"

# Validate required parameters
if [ -z "$ISSUE_NUMBER" ] || [ -z "$ISSUE_TITLE" ] || [ -z "$CREATOR_USERNAME" ]; then
  echo "❌ Error: Missing required parameters"
  echo "Usage: prepare-commit.sh <issue_number> <issue_title> <creator_username>"
  exit 1
fi

# Validate git is configured
if ! git config user.email > /dev/null 2>&1 || ! git config user.name > /dev/null 2>&1; then
  echo "❌ Error: Git user configuration is missing"
  echo "Please configure git with: git config user.name '<name>' && git config user.email '<email>'"
  exit 1
fi

# Validate we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "❌ Error: Not in a git repository"
  exit 1
fi

echo "📝 Preparing commit..."

# GHES mode: Use GitHub username, construct email from username
CREATOR_NAME="$CREATOR_USERNAME"
CREATOR_EMAIL="${CREATOR_USERNAME}@users.noreply.github.com"

echo "👤 Co-author: $CREATOR_NAME <$CREATOR_EMAIL>"

# Add all files except metadata files
git add .

# Exclude metadata files from commit
for file in copilot-summary.md commit-message.md .final-commit-msg.txt .github/copilot-instructions.md; do
  if git ls-files --cached "$file" > /dev/null 2>&1; then
    git reset HEAD "$file" || true
  fi
done

# Check if there are any staged changes
if ! git diff --cached --quiet; then
  echo "✅ Changes staged for commit"
else
  echo "⚠️  No changes staged for commit"
fi

# Prepare final commit message with co-author
if [ -f "commit-message.md" ]; then
  echo "✅ Using Copilot-generated commit message"
  {
    cat commit-message.md
    echo ""
    echo ""
    echo "Co-authored-by: ${CREATOR_NAME} <${CREATOR_EMAIL}>"
  } > .final-commit-msg.txt
else
  echo "⚠️  commit-message.md not found, using default message"
  {
    echo "feat: Implement issue ${ISSUE_NUMBER}"
    echo ""
    echo "${ISSUE_TITLE}"
    echo ""
    echo "Changes implemented by GitHub Copilot CLI"
    echo ""
    echo "Co-authored-by: ${CREATOR_NAME} <${CREATOR_EMAIL}>"
  } > .final-commit-msg.txt
fi

# Verify commit message file was created
if [ ! -f ".final-commit-msg.txt" ]; then
  echo "❌ Error: Failed to create commit message file"
  exit 1
fi

# Create commit with proper error handling
if git diff --cached --quiet; then
  echo "⚠️  No staged changes to commit, skipping git commit"
else
  if git commit -F .final-commit-msg.txt; then
    echo "✅ Changes committed successfully"
  else
    echo "❌ Error: Failed to create commit"
    exit 1
  fi
fi

# Clean up
rm -f .final-commit-msg.txt
