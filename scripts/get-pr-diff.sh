#!/bin/bash

# Get PR differences using GitHub API (GHES-compatible)
# Usage: ./get-pr-diff.sh <GHES_HOST> <OWNER> <REPO> <PR_NUMBER> <TOKEN> <OUTPUT_FILE>

set -e

echo "🌐 Get PR Differences using GitHub API"
echo "======================================="

# Verify parameters
if [ $# -ne 6 ]; then
    echo "❌ ERROR: Incorrect number of parameters"
    echo "Usage: $0 <GHES_HOST> <OWNER> <REPO> <PR_NUMBER> <TOKEN> <OUTPUT_FILE>"
    echo ""
    echo "Example:"
    echo "$0 'github.company.com' 'myorg' 'myrepo' '42' 'ghp_xxxx' '/path/to/output.json'"
    exit 1
fi

# Assign parameters
GHES_HOST="$1"
OWNER="$2"
REPO="$3"
PR_NUMBER="$4"
TOKEN="$5"
OUTPUT_FILE="$6"

echo "📋 PR Information:"
echo "  - GHES Host: $GHES_HOST"
echo "  - Owner: $OWNER"
echo "  - Repository: $REPO"
echo "  - PR Number: $PR_NUMBER"
echo "  - Output File: $OUTPUT_FILE"
echo ""

# Determine if using GHES or GitHub.com
if [[ "$GHES_HOST" == "github.com" ]]; then
    API_BASE="https://api.github.com"
else
    API_BASE="https://$GHES_HOST/api/v3"
fi

echo "🔗 API Base URL: $API_BASE"
echo ""

# Get PR details first
echo "🔍 Fetching PR details..."
PR_URL="$API_BASE/repos/$OWNER/$REPO/pulls/$PR_NUMBER"

PR_RESPONSE=$(curl -s \
    -H "Authorization: Bearer $TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "$PR_URL" 2>/dev/null)

# Check if API call was successful
if echo "$PR_RESPONSE" | grep -q "\"message\": \"Not Found\""; then
    echo "❌ ERROR: PR not found or unauthorized"
    echo "   URL: $PR_URL"
    exit 1
fi

# Extract branch information
BASE_REF=$(echo "$PR_RESPONSE" | grep -o '"base":{"label":"[^"]*"' | cut -d'"' -f8 | cut -d: -f2-)
HEAD_REF=$(echo "$PR_RESPONSE" | grep -o '"head":{"label":"[^"]*"' | cut -d'"' -f8 | cut -d: -f2-)

echo "  - Base Branch: $BASE_REF"
echo "  - Head Branch: $HEAD_REF"
echo ""

# Get the files changed in the PR
echo "📄 Fetching changed files..."
FILES_URL="$API_BASE/repos/$OWNER/$REPO/pulls/$PR_NUMBER/files"

# GitHub API paginated endpoint, we'll get up to 300 files (3 pages)
# Initialize the array to hold all files
CHANGES=()
PAGE=1
TOTAL=0

while [ $PAGE -le 3 ]; do
    FILES_RESPONSE=$(curl -s \
        -H "Authorization: Bearer $TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "$FILES_URL?page=$PAGE&per_page=100" 2>/dev/null)
    
    # Check if we got any files
    if echo "$FILES_RESPONSE" | grep -q "^\\[\\]"; then
        break
    fi
    
    # Extract file information and build diff structure
    # For each file, create a change entry
    FILE_COUNT=$(echo "$FILES_RESPONSE" | grep -o '"filename":' | wc -l)
    
    if [ $FILE_COUNT -eq 0 ]; then
        break
    fi
    
    TOTAL=$((TOTAL + FILE_COUNT))
    PAGE=$((PAGE + 1))
done

echo "✅ Found $TOTAL changed files"
echo ""

# Create the output JSON structure that matches the analysis scripts' expectations
echo "📝 Creating diff output in GitHub format..."

cat > "$OUTPUT_FILE" << 'EOJSON'
{
  "pr_number": __PR_NUMBER__,
  "base_ref": "__BASE_REF__",
  "head_ref": "__HEAD_REF__",
  "changes": [
    __FILES__
  ],
  "statistics": {
    "total_changes": __TOTAL_CHANGES__,
    "additions": 0,
    "deletions": 0
  }
}
EOJSON

# Now let's actually build the changes array
echo "🔄 Processing files..."

CHANGES_ARRAY=""
FIRST=true
FILE_COUNT=0

for PAGE in 1 2 3; do
    FILES_RESPONSE=$(curl -s \
        -H "Authorization: Bearer $TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "$FILES_URL?page=$PAGE&per_page=100" 2>/dev/null)
    
    if echo "$FILES_RESPONSE" | grep -q "^\\[\\]"; then
        break
    fi
    
    # Parse each file from the response
    FILENAMES=$(echo "$FILES_RESPONSE" | grep -o '"filename":"[^"]*"' | cut -d'"' -f4)
    
    while IFS= read -r filename; do
        if [ -n "$filename" ]; then
            if [ "$FIRST" = false ]; then
                CHANGES_ARRAY="$CHANGES_ARRAY,"
            fi
            
            CHANGES_ARRAY="$CHANGES_ARRAY
    {
      \"path\": \"$filename\",
      \"type\": \"modify\"
    }"
            
            FIRST=false
            FILE_COUNT=$((FILE_COUNT + 1))
            echo "   - $filename"
        fi
    done <<< "$FILENAMES"
done

echo ""
echo "✅ Total files: $FILE_COUNT"
echo ""

# Build final JSON output
cat > "$OUTPUT_FILE" << EOF
{
  "pr_number": $PR_NUMBER,
  "base_ref": "$BASE_REF",
  "head_ref": "$HEAD_REF",
  "changes": [$CHANGES_ARRAY
  ],
  "statistics": {
    "total_changes": $FILE_COUNT
  }
}
EOF

# Verify the JSON is valid
if command -v jq &> /dev/null; then
    if jq empty "$OUTPUT_FILE" 2>/dev/null; then
        echo "✅ Valid JSON created: $OUTPUT_FILE"
        echo "   Size: $(du -h "$OUTPUT_FILE" | cut -f1)"
        exit 0
    else
        echo "❌ Invalid JSON generated"
        exit 1
    fi
else
    echo "✅ Diff file created (jq not available for validation)"
    echo "   Size: $(du -h "$OUTPUT_FILE" | cut -f1)"
    exit 0
fi
