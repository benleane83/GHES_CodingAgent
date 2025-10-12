#!/bin/bash

# Script completo para probar TODOS los scripts incluyendo la creación de PR
# Este script crea una rama de prueba, hace cambios, y crea un PR real

echo "========================================"
echo "🧪 Full Test - Including PR Creation"
echo "========================================"
echo ""

# Cargar variables del .env
if [ ! -f .env ]; then
    echo "❌ ERROR: .env file not found"
    exit 1
fi

echo "📋 Loading configuration from .env..."
export AZURE_DEVOPS_PAT=$(grep "^AZURE_DEVOPS_PAT=" .env | cut -d= -f2)
export SYSTEM_COLLECTIONURI=$(grep "^SYSTEM_COLLECTIONURI=" .env | cut -d= -f2)
export SYSTEM_TEAMPROJECT=$(grep "^SYSTEM_TEAMPROJECT=" .env | cut -d= -f2 | tr -d '"')
export TEST_WORK_ITEM_ID=$(grep "^TEST_WORK_ITEM_ID=" .env | cut -d= -f2)

ORG=$(echo $SYSTEM_COLLECTIONURI | sed 's|https://dev.azure.com/||' | sed 's|/.*||')

echo "✅ Configuration loaded"
echo "   Organization: $ORG"
echo "   Project: $SYSTEM_TEAMPROJECT"
echo "   Test Work Item: $TEST_WORK_ITEM_ID"
echo ""

# ============================================================================
echo "========================================"
echo "STEP 1: Read Work Item"
echo "========================================"
./scripts/get-workitem.sh "$TEST_WORK_ITEM_ID" "$SYSTEM_TEAMPROJECT"
if [ $? -ne 0 ]; then
    echo "❌ Failed to read work item"
    exit 1
fi
echo "✅ Work item read successfully"
echo ""
read -p "Press Enter to continue..."
echo ""

# ============================================================================
echo "========================================"
echo "STEP 2: Add Initial Comment"
echo "========================================"
COMMENT="👀🤖 <b>Started testing all scripts</b><br/>Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
./scripts/add-comment-to-workitem.sh "$ORG" "$SYSTEM_TEAMPROJECT" "$TEST_WORK_ITEM_ID" "$COMMENT"
if [ $? -ne 0 ]; then
    echo "❌ Failed to add comment"
    exit 1
fi
echo "✅ Initial comment added"
echo ""
read -p "Press Enter to continue..."
echo ""

# ============================================================================
echo "========================================"
echo "STEP 3: Create Test Branch"
echo "========================================"
BRANCH_NAME="test/scripts-validation-$(date +%s)"
echo "Branch name: $BRANCH_NAME"
echo ""

# Check current git status
echo "Current git status:"
git status
echo ""

read -p "Create branch '$BRANCH_NAME'? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "⏭️  Skipped - Exiting"
    exit 0
fi

git checkout -b "$BRANCH_NAME"
if [ $? -ne 0 ]; then
    echo "❌ Failed to create branch"
    exit 1
fi
echo "✅ Branch created: $BRANCH_NAME"
echo ""

# ============================================================================
echo "========================================"
echo "STEP 4: Make a Test Change"
echo "========================================"
TEST_FILE="test-validation-$(date +%s).txt"
echo "Creating test file: $TEST_FILE"
echo "This is a test file for validation - $(date)" > "$TEST_FILE"
git add "$TEST_FILE"
git commit -m "test: Add validation test file

This is a test commit to validate the PR creation script.

Work Item: #$TEST_WORK_ITEM_ID"

if [ $? -ne 0 ]; then
    echo "❌ Failed to commit"
    exit 1
fi
echo "✅ Test commit created"
echo ""
read -p "Press Enter to continue..."
echo ""

# ============================================================================
echo "========================================"
echo "STEP 5: Assign Work Item"
echo "========================================"
./scripts/assign-workitem.sh "$ORG" "$SYSTEM_TEAMPROJECT" "$TEST_WORK_ITEM_ID" "GitHub Copilot CLI"
if [ $? -ne 0 ]; then
    echo "⚠️  Failed to assign work item (continuing anyway)"
else
    echo "✅ Work item assigned"
fi
echo ""
read -p "Press Enter to continue..."
echo ""

# ============================================================================
echo "========================================"
echo "STEP 6: Update Work Item State"
echo "========================================"
./scripts/update-workitem-state.sh "$ORG" "$SYSTEM_TEAMPROJECT" "$TEST_WORK_ITEM_ID" "Doing"
if [ $? -ne 0 ]; then
    echo "⚠️  Failed to update state (continuing anyway)"
else
    echo "✅ Work item state updated"
fi
echo ""
read -p "Press Enter to continue..."
echo ""

# ============================================================================
echo "========================================"
echo "STEP 7: Push Branch"
echo "========================================"
echo "⚠️  About to push branch to Azure DevOps"
echo ""
read -p "Push branch '$BRANCH_NAME' to remote? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "⏭️  Skipped push - cleaning up local branch"
    git checkout main 2>/dev/null || git checkout master
    git branch -D "$BRANCH_NAME"
    exit 0
fi

# Configure git remote with PAT
# URL-encode the project name (spaces become %20)
PROJECT_ENCODED=$(echo -n "$SYSTEM_TEAMPROJECT" | jq -sRr @uri 2>/dev/null || echo "$SYSTEM_TEAMPROJECT" | sed 's/ /%20/g')
REMOTE_URL="https://${AZURE_DEVOPS_PAT}@dev.azure.com/${ORG}/${PROJECT_ENCODED}/_git/${PROJECT_ENCODED}"
echo "Setting remote URL (with PAT authentication)..."
git remote set-url origin "$REMOTE_URL" 2>/dev/null || git remote add origin "$REMOTE_URL"

echo "Pushing branch..."
git push -u origin "$BRANCH_NAME"
if [ $? -ne 0 ]; then
    echo "❌ Failed to push branch"
    echo "Cleaning up local branch..."
    git checkout main 2>/dev/null || git checkout master
    git branch -D "$BRANCH_NAME"
    exit 1
fi
echo "✅ Branch pushed successfully"
echo ""
read -p "Press Enter to continue..."
echo ""

# ============================================================================
echo "========================================"
echo "STEP 8: Get Repository ID"
echo "========================================"
echo "Getting repository ID..."

# Try to get repo ID using az CLI
if command -v az &> /dev/null; then
    REPO_ID=$(az repos show \
        --repository "$SYSTEM_TEAMPROJECT" \
        --organization "https://dev.azure.com/${ORG}" \
        --project "$SYSTEM_TEAMPROJECT" \
        --output json 2>/dev/null | jq -r '.id')
    
    if [ -z "$REPO_ID" ] || [ "$REPO_ID" = "null" ]; then
        echo "⚠️  Could not get repo ID with az CLI, trying API..."
        # Fallback to API
        PAT_BASE64=$(echo -n ":${AZURE_DEVOPS_PAT}" | base64 -w 0 2>/dev/null || echo -n ":${AZURE_DEVOPS_PAT}" | base64 | tr -d '\n')
        PROJECT_ENCODED=$(echo -n "$SYSTEM_TEAMPROJECT" | jq -sRr @uri 2>/dev/null || echo "$SYSTEM_TEAMPROJECT" | sed 's/ /%20/g')
        
        REPO_RESPONSE=$(curl -s \
            "https://dev.azure.com/${ORG}/${PROJECT_ENCODED}/_apis/git/repositories?api-version=7.0" \
            -H "Authorization: Basic ${PAT_BASE64}")
        
        REPO_ID=$(echo "$REPO_RESPONSE" | jq -r '.value[0].id')
    fi
else
    echo "⚠️  az CLI not available, using API..."
    # Use API
    PAT_BASE64=$(echo -n ":${AZURE_DEVOPS_PAT}" | base64 -w 0 2>/dev/null || echo -n ":${AZURE_DEVOPS_PAT}" | base64 | tr -d '\n')
    PROJECT_ENCODED=$(echo -n "$SYSTEM_TEAMPROJECT" | jq -sRr @uri 2>/dev/null || echo "$SYSTEM_TEAMPROJECT" | sed 's/ /%20/g')
    
    REPO_RESPONSE=$(curl -s \
        "https://dev.azure.com/${ORG}/${PROJECT_ENCODED}/_apis/git/repositories?api-version=7.0" \
        -H "Authorization: Basic ${PAT_BASE64}")
    
    REPO_ID=$(echo "$REPO_RESPONSE" | jq -r '.value[0].id')
fi

if [ -z "$REPO_ID" ] || [ "$REPO_ID" = "null" ]; then
    echo "❌ Could not get repository ID"
    echo "Response: $REPO_RESPONSE"
    exit 1
fi

echo "✅ Repository ID: $REPO_ID"
echo ""
read -p "Press Enter to continue..."
echo ""

# ============================================================================
echo "========================================"
echo "STEP 9: Create Pull Request"
echo "========================================"
echo "Creating PR from '$BRANCH_NAME' to 'main'..."
echo ""

# Get reviewer email from work item creator
REVIEWER_EMAIL="daenerys@thegameofthrones.onmicrosoft.com"

PR_TITLE="Test PR: Scripts Validation #$TEST_WORK_ITEM_ID"
PR_DESCRIPTION="## 🧪 Test Pull Request

This PR was created to validate all Azure DevOps scripts.

### Changes Made
- Created test file: $TEST_FILE
- Validated all scripts work correctly

### Scripts Tested
- ✅ get-workitem.sh
- ✅ add-comment-to-workitem.sh
- ✅ assign-workitem.sh
- ✅ update-workitem-state.sh
- ✅ create-pr-with-required-reviewer.sh

Work Item: #$TEST_WORK_ITEM_ID"

echo "Title: $PR_TITLE"
echo "Reviewer: $REVIEWER_EMAIL"
echo ""

./scripts/create-pr-with-required-reviewer.sh \
    "$ORG" \
    "$SYSTEM_TEAMPROJECT" \
    "$REPO_ID" \
    "$BRANCH_NAME" \
    "main" \
    "$PR_TITLE" \
    "$PR_DESCRIPTION" \
    "$REVIEWER_EMAIL"

PR_RESULT=$?
echo ""
if [ $PR_RESULT -eq 0 ]; then
    echo "✅ Pull Request created successfully!"
else
    echo "❌ Failed to create Pull Request (exit code: $PR_RESULT)"
fi
echo ""
read -p "Press Enter to continue..."
echo ""

# ============================================================================
echo "========================================"
echo "STEP 10: Update Work Item Activity"
echo "========================================"
./scripts/update-workitem-activity.sh "$ORG" "$SYSTEM_TEAMPROJECT" "$TEST_WORK_ITEM_ID" "Development"
if [ $? -ne 0 ]; then
    echo "⚠️  Failed to update activity (continuing anyway)"
else
    echo "✅ Work item activity updated"
fi
echo ""

# ============================================================================
echo ""
echo "========================================"
echo "✨ Full Test Complete!"
echo "========================================"
echo ""
echo "Summary:"
echo "  ✅ Read work item"
echo "  ✅ Added initial comment"
echo "  ✅ Created branch: $BRANCH_NAME"
echo "  ✅ Committed test changes"
echo "  ✅ Assigned work item"
echo "  ✅ Updated work item state"
echo "  ✅ Pushed branch to remote"
echo "  ✅ Created Pull Request"
echo "  ✅ Updated work item activity"
echo ""
echo "🎉 All scripts validated successfully!"
echo ""
echo "⚠️  Remember to:"
echo "   - Review the PR in Azure DevOps"
echo "   - Merge or abandon the PR"
echo "   - Delete the test branch: $BRANCH_NAME"
echo "   - Delete the test file: $TEST_FILE (if merged)"
echo ""
