#!/bin/bash
set -e

# Script to update GitHub issue labels
# Usage: update-issue-labels.sh <issue_number> <action> <labels>
#   action: add or remove
#   labels: comma-separated list of labels

ISSUE_NUMBER="$1"
ACTION="$2"
LABELS="$3"

if [ -z "$ISSUE_NUMBER" ] || [ -z "$ACTION" ] || [ -z "$LABELS" ]; then
  echo "❌ Error: Missing required parameters"
  echo "Usage: update-issue-labels.sh <issue_number> <action> <labels>"
  echo "  action: add or remove"
  echo "  labels: comma-separated list of labels"
  exit 1
fi

if [ -z "$GH_TOKEN" ]; then
  echo "❌ Error: GH_TOKEN environment variable is not set"
  exit 1
fi

echo "🏷️  Updating labels for issue #${ISSUE_NUMBER}..."

if [ "$ACTION" = "add" ]; then
  gh issue edit "$ISSUE_NUMBER" --add-label "$LABELS"
  echo "✅ Labels added: $LABELS"
elif [ "$ACTION" = "remove" ]; then
  gh issue edit "$ISSUE_NUMBER" --remove-label "$LABELS"
  echo "✅ Labels removed: $LABELS"
else
  echo "❌ Error: Invalid action '$ACTION'. Use 'add' or 'remove'"
  exit 1
fi
