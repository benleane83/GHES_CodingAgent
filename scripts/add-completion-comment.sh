#!/bin/bash
set -e

# Script to add completion comment to work item
# Usage: add-completion-comment.sh <org> <project> <work_item_id> <created_by> <pr_url>

ORG="$1"
PROJECT="$2"
WORK_ITEM_ID="$3"
CREATED_BY="$4"
PR_URL="$5"

SCRIPTS_DIR="$(dirname "$0")"

echo "💬 Adding completion comment to work item..."

# Get the creator's display name for mention
CREATOR_DISPLAY_NAME=$(echo "$CREATED_BY" | sed 's/<.*//' | xargs)

# Create a rich comment with the completion status and mention
COMMENT="@${CREATOR_DISPLAY_NAME} ✅🤖 <b>GitHub Copilot</b> has completed the implementation<br/><br/>✨ The changes have been implemented and are ready for review.<br/>📬 A Pull Request has been created with the requested changes.<br/><br/>🔗 <a href='${PR_URL}'>View Pull Request</a>"

"$SCRIPTS_DIR/add-comment-to-workitem.sh" "$ORG" "$PROJECT" "$WORK_ITEM_ID" "$COMMENT"

echo "✅ Comment added successfully"
