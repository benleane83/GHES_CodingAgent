#!/bin/bash
set -e

# Script to orchestrate work item operations
# Usage: orchestrate-workitem.sh start <work_item_id> <_> <org> <project> <title> <created_by> <_>

COMMAND="$1"
WORK_ITEM_ID="$2"
# $3 is unused (placeholder for PR_ID in old version)
ORG="$4"
PROJECT="$5"
WORK_ITEM_TITLE="$6"
WORK_ITEM_CREATED_BY="$7"
# $8 is unused (placeholder for PR_URL in old version)

SCRIPTS_DIR="$(dirname "$0")"

case "$COMMAND" in
  start)
    echo "🚀 Starting work item operations..."
    
    # Add initial comment
    echo "💬 Adding initial comment..."
    "$SCRIPTS_DIR/add-comment-to-workitem.sh" "$ORG" "$PROJECT" "$WORK_ITEM_ID" \
      "👀🤖 <b>GitHub Copilot</b> started working on this task"
    
    # Assign to Copilot
    echo "👤 Assigning to GitHub Copilot..."
    "$SCRIPTS_DIR/assign-workitem.sh" "$ORG" "$PROJECT" "$WORK_ITEM_ID" "GitHub Copilot CLI"
    
    # Update state to Doing
    echo "🔄 Updating state to 'Doing'..."
    "$SCRIPTS_DIR/update-workitem-state.sh" "$ORG" "$PROJECT" "$WORK_ITEM_ID" "Doing"
    
    echo "✅ Work item initialized successfully"
    ;;
    
  *)
    echo "❌ Unknown command: $COMMAND"
    echo "Usage: orchestrate-workitem.sh start <work_item_id> <_> <org> <project> <title> <created_by> <_>"
    exit 1
    ;;
esac
