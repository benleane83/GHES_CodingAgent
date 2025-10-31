#!/bin/bash

# Post PR review comments to GHES using GitHub API
# Usage: ./post-pr-comment.sh <GHES_HOST> <OWNER> <REPO> <PR_NUMBER> <COMMENTS_DIR> <TOKEN>

echo "💬 Posting PR Review Comments to GHES"
echo "======================================"

# Verify parameters
if [ $# -ne 6 ]; then
    echo "❌ ERROR: Incorrect number of parameters"
    echo "Usage: $0 <GHES_HOST> <OWNER> <REPO> <PR_NUMBER> <COMMENTS_DIR> <TOKEN>"
    echo ""
    echo "Example:"
    echo "$0 'github.company.com' 'myorg' 'myrepo' '42' '/path/to/comments' 'ghp_xxxx'"
    exit 1
fi

# Assign parameters
GHES_HOST="$1"
OWNER="$2"
REPO="$3"
PR_NUMBER="$4"
COMMENTS_DIR="$5"
TOKEN="$6"

echo "📋 Configuration:"
echo "  - GHES Host: $GHES_HOST"
echo "  - Owner: $OWNER"
echo "  - Repository: $REPO"
echo "  - PR Number: $PR_NUMBER"
echo "  - Comments Directory: $COMMENTS_DIR"
echo ""

# Verify comments directory exists
if [ ! -d "$COMMENTS_DIR" ]; then
    echo "❌ ERROR: Directory $COMMENTS_DIR does not exist"
    exit 1
fi

# Get list of markdown files
COMMENT_FILES=($(find "$COMMENTS_DIR" -type f -name "*_analysis.md" | sort))

if [ ${#COMMENT_FILES[@]} -eq 0 ]; then
    echo "⚠️  No analysis markdown files found in $COMMENTS_DIR"
    echo "   (This is normal if Copilot found no issues to report)"
    exit 0
fi

echo "📄 Found ${#COMMENT_FILES[@]} comment files to post"
echo ""

# Determine API base URL
if [[ "$GHES_HOST" == "github.com" ]]; then
    API_BASE="https://api.github.com"
else
    API_BASE="https://$GHES_HOST/api/v3"
fi

echo "🔗 API Base URL: $API_BASE"
echo ""

# Counters
SUCCESSFUL_POSTS=0
FAILED_POSTS=0

# Post each comment file as a review comment
for comment_file in "${COMMENT_FILES[@]}"; do
    filename=$(basename "$comment_file")
    
    echo "=================================================="
    echo "📤 Posting comment: $filename"
    echo "=================================================="
    
    # Read comment content
    COMMENT_CONTENT=$(cat "$comment_file")
    
    # Escape special characters for JSON
    ESCAPED_CONTENT=$(printf '%s' "$COMMENT_CONTENT" | \
        sed 's/\\/\\\\/g' | \
        sed 's/"/\\"/g' | \
        sed ':a;N;$!ba;s/\n/\\n/g')
    
    # Create request body for review comment
    # Use the reviews API to create a review with body comment
    PAYLOAD=$(cat <<EOF
{
  "body": "$ESCAPED_CONTENT",
  "event": "COMMENT"
}
EOF
)
    
    # Post as a pull request review
    REVIEW_URL="$API_BASE/repos/$OWNER/$REPO/pulls/$PR_NUMBER/reviews"
    
    echo "📡 Posting to: $REVIEW_URL"
    echo "📊 Payload size: $(echo "$PAYLOAD" | wc -c) bytes"
    
    # Make the API call
    HTTP_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
        -X POST \
        -H "Authorization: Bearer $TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Content-Type: application/json" \
        -d "$PAYLOAD" \
        "$REVIEW_URL")
    
    # Extract status code
    HTTP_CODE=$(echo "$HTTP_RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
    RESPONSE_BODY=$(echo "$HTTP_RESPONSE" | sed '/HTTP_STATUS:/d')
    
    echo "📡 HTTP Response Code: $HTTP_CODE"
    
    # Check if successful (201 is created for review, 200 for update)
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
        echo "✅ Comment posted successfully!"
        ((SUCCESSFUL_POSTS++))
    else
        echo "❌ Failed to post comment (HTTP $HTTP_CODE)"
        ((FAILED_POSTS++))
        
        # Show error details if available
        if command -v jq &> /dev/null; then
            ERROR_MSG=$(echo "$RESPONSE_BODY" | jq -r '.message // .error // empty' 2>/dev/null)
            if [ -n "$ERROR_MSG" ]; then
                echo "   Error: $ERROR_MSG"
            fi
        fi
    fi
    
    echo ""
    
    # Add a small delay between posts to avoid rate limiting
    sleep 1
done

# Summary
echo "=================================================="
echo "📊 Posting Summary"
echo "=================================================="
echo "  - Total comments: ${#COMMENT_FILES[@]}"
echo "  - Successfully posted: $SUCCESSFUL_POSTS"
echo "  - Failed: $FAILED_POSTS"
echo ""

if [ $FAILED_POSTS -eq 0 ] && [ $SUCCESSFUL_POSTS -gt 0 ]; then
    echo "🎉 All comments posted successfully to PR #$PR_NUMBER"
    exit 0
elif [ $SUCCESSFUL_POSTS -eq 0 ] && [ $FAILED_POSTS -eq 0 ]; then
    echo "ℹ️  No comments to post"
    exit 0
else
    echo "⚠️  Some comments failed to post. Check logs above for details."
    exit 1
fi
