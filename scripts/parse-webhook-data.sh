#!/bin/bash
set -e

# Script to parse webhook data and set pipeline variables
# This consolidates the webhook parsing logic from the main pipeline
# Expects variables to be passed as environment variables:
# - EVENT_TYPE, WORK_ITEM_ID, WORK_ITEM_TITLE, WORK_ITEM_STATE, etc.

echo "🔔 Processing webhook payload..."
echo "═══════════════════════════════════════════════════════════"
echo "📋 WEBHOOK INFORMATION"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "🔖 Event Type: $EVENT_TYPE"
echo "🆔 Work Item ID: $WORK_ITEM_ID"
echo "📌 Title: $WORK_ITEM_TITLE"
echo "📊 State: $WORK_ITEM_STATE"
echo "📁 Team Project: $PROJECT_NAME"
echo ""
echo "═══════════════════════════════════════════════════════════"

# Set pipeline variables
echo "##vso[task.setvariable variable=WorkItemId]$WORK_ITEM_ID"
echo "##vso[task.setvariable variable=WorkItemTitle]$WORK_ITEM_TITLE"
echo "##vso[task.setvariable variable=WorkItemType]$WORK_ITEM_TYPE"
echo "##vso[task.setvariable variable=WorkItemState]$WORK_ITEM_STATE"
echo "##vso[task.setvariable variable=WorkItemCreatedBy]$WORK_ITEM_CREATED_BY"
echo "##vso[task.setvariable variable=WorkItemAssignedTo]$WORK_ITEM_ASSIGNED_TO"
echo "##vso[task.setvariable variable=WorkItemDescription]$WORK_ITEM_DESCRIPTION"
echo "##vso[task.setvariable variable=ProjectName]$PROJECT_NAME"

# Extract organization from collection URI
ORG=$(echo $SYSTEM_COLLECTIONURI | sed 's|https://dev.azure.com/||' | sed 's|/.*||')
echo "##vso[task.setvariable variable=Organization]$ORG"
echo "🏢 Organization: $ORG"

# Extract Repository Name from Tags (format: repo:REPO_NAME)
REPO_TAG=$(echo "$WORK_ITEM_TAGS" | grep -oP 'repo:\S+' || true)
if [ -n "$REPO_TAG" ]; then
  TARGET_REPO=$(echo "$REPO_TAG" | sed 's/repo://' | sed 's/;$//')
  echo "🎯 Target repository: $TARGET_REPO"
  echo "##vso[task.setvariable variable=TargetRepoName]$TARGET_REPO"
else
  echo "⚠️  Using current repository"
  echo "##vso[task.setvariable variable=TargetRepoName]$CURRENT_REPO"
fi

# Extract email from CreatedBy field
CREATOR_EMAIL=$(echo "$WORK_ITEM_CREATED_BY" | grep -oP '[\w\.-]+@[\w\.-]+' || echo "$WORK_ITEM_CREATED_BY")
echo "##vso[task.setvariable variable=CreatorEmail]$CREATOR_EMAIL"
echo "📧 Creator Email: $CREATOR_EMAIL"

# Store the pipeline scripts directory
echo "##vso[task.setvariable variable=PipelineScriptsDir]$WORKING_DIR/scripts"
echo "📁 Scripts directory: $WORKING_DIR/scripts"

echo ""
echo "✅ Webhook data parsed successfully"
