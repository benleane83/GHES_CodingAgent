#!/bin/bash

# Download PR files from GHES using GitHub API
# Usage: ./download-pr-files.sh <GHES_HOST> <OWNER> <REPO> <PR_NUMBER> <TOKEN> <OUTPUT_DIR>

set -e

echo "📁 Downloading Modified PR Files from GHES"
echo "=========================================="

# Verify parameters
if [ $# -ne 6 ]; then
    echo "❌ ERROR: Incorrect number of parameters"
    echo "Usage: $0 <GHES_HOST> <OWNER> <REPO> <PR_NUMBER> <TOKEN> <OUTPUT_DIR>"
    echo ""
    echo "Example:"
    echo "$0 'github.company.com' 'myorg' 'myrepo' '42' 'ghp_xxxx' '/path/to/output'"
    exit 1
fi

# Assign parameters
GHES_HOST="$1"
OWNER="$2"
REPO="$3"
PR_NUMBER="$4"
TOKEN="$5"
OUTPUT_DIR="${6:-./pr-files-$(date +%Y%m%d_%H%M%S)}"

echo "📋 Configuration:"
echo "  - GHES Host: $GHES_HOST"
echo "  - Owner: $OWNER"
echo "  - Repository: $REPO"
echo "  - PR Number: $PR_NUMBER"
echo "  - Output Directory: $OUTPUT_DIR"
echo ""

# Determine API base URL
if [[ "$GHES_HOST" == "github.com" ]]; then
    API_BASE="https://api.github.com"
else
    API_BASE="https://$GHES_HOST/api/v3"
fi

# Verify jq is available
if ! command -v jq &> /dev/null; then
    echo "❌ ERROR: jq is required to process JSON"
    echo "Install with: brew install jq (macOS) or apt-get install jq (Ubuntu)"
    exit 1
fi

# Create output directories
echo "📁 Creating directory structure..."
mkdir -p "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/source"
mkdir -p "$OUTPUT_DIR/target" 
mkdir -p "$OUTPUT_DIR/metadata"

# Get files from the PR
echo "📄 Fetching changed files from PR..."
FILES_URL="$API_BASE/repos/$OWNER/$REPO/pulls/$PR_NUMBER/files"

CHANGES=()
PAGE=1
FILE_COUNT=0

# Collect all files from all pages
while [ $PAGE -le 10 ]; do
    RESPONSE=$(curl -s \
        -H "Authorization: Bearer $TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "$FILES_URL?page=$PAGE&per_page=100" 2>/dev/null)
    
    # Check if empty response
    if echo "$RESPONSE" | grep -q "^\\[\\]"; then
        break
    fi
    
    # Count files on this page
    PAGE_COUNT=$(echo "$RESPONSE" | grep -o '"filename":' | wc -l)
    
    if [ $PAGE_COUNT -eq 0 ]; then
        break
    fi
    
    FILE_COUNT=$((FILE_COUNT + PAGE_COUNT))
    
    # Extract filenames
    echo "$RESPONSE" | jq -r '.[] | .filename' >> "/tmp/pr_files_$$.txt" 2>/dev/null || true
    
    PAGE=$((PAGE + 1))
done

if [ ! -f "/tmp/pr_files_$$.txt" ]; then
    echo "⚠️  No modified files found in PR"
    exit 0
fi

TOTAL_FILES=$(wc -l < "/tmp/pr_files_$$.txt" | tr -d ' ')
echo "✅ Found $TOTAL_FILES files to download"
echo ""

# Function to download a file from GitHub
download_file() {
    local filepath="$1"
    local ref="$2"
    local output_subdir="$3"
    local display_name="$4"
    
    echo "📥 Downloading: $filepath ($display_name)"
    
    # Create directory structure
    local file_dir="$OUTPUT_DIR/$output_subdir/$(dirname "$filepath")"
    mkdir -p "$file_dir"
    
    # GitHub API content endpoint
    local content_url="$API_BASE/repos/$OWNER/$REPO/contents/$filepath?ref=$ref"
    
    # Download file
    RESPONSE=$(curl -s \
        -H "Authorization: Bearer $TOKEN" \
        -H "Accept: application/vnd.github.v3.raw" \
        "$content_url" 2>/dev/null)
    
    # Check for errors
    if echo "$RESPONSE" | grep -q "\"message\""; then
        local error_msg=$(echo "$RESPONSE" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)
        echo "  ❌ Error: $error_msg"
        return 1
    fi
    
    # Save file
    local output_file="$OUTPUT_DIR/$output_subdir/$filepath"
    echo "$RESPONSE" > "$output_file"
    
    if [ -s "$output_file" ]; then
        local file_size=$(du -h "$output_file" | cut -f1)
        echo "  ✅ Downloaded ($file_size)"
        return 0
    else
        echo "  ⚠️  Empty file downloaded"
        return 1
    fi
}

# Counters
SUCCESSFUL_DOWNLOADS=0
FAILED_DOWNLOADS=0

# Process each file
echo "🔄 Downloading files..."
while IFS= read -r filepath; do
    if [ -n "$filepath" ]; then
        echo ""
        echo "📄 Processing: $filepath"
        
        # Get PR details to find the head branch
        PR_URL="$API_BASE/repos/$OWNER/$REPO/pulls/$PR_NUMBER"
        PR_DATA=$(curl -s \
            -H "Authorization: Bearer $TOKEN" \
            -H "Accept: application/vnd.github.v3+json" \
            "$PR_URL" 2>/dev/null)
        
        HEAD_SHA=$(echo "$PR_DATA" | grep -o '"sha":"[^"]*"' | head -1 | cut -d'"' -f4)
        BASE_SHA=$(echo "$PR_DATA" | grep -o '"base":{[^}]*"sha":"[^"]*"' | grep -o '"sha":"[^"]*"' | cut -d'"' -f4)
        
        # Download from source (head) branch
        if download_file "$filepath" "$HEAD_SHA" "source" "source branch"; then
            ((SUCCESSFUL_DOWNLOADS++))
        else
            ((FAILED_DOWNLOADS++))
        fi
        
        # Download from target (base) branch if it exists
        if download_file "$filepath" "$BASE_SHA" "target" "target branch"; then
            ((SUCCESSFUL_DOWNLOADS++))
        else
            echo "  ⚠️  Could not download from target branch (possibly new file)"
        fi
    fi
done < "/tmp/pr_files_$$.txt"

# Cleanup temp file
rm -f "/tmp/pr_files_$$.txt"

# Create metadata
echo ""
echo "📝 Generating metadata..."
METADATA_FILE="$OUTPUT_DIR/metadata/pr-info.json"

PR_URL="$API_BASE/repos/$OWNER/$REPO/pulls/$PR_NUMBER"
PR_DATA=$(curl -s \
    -H "Authorization: Bearer $TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "$PR_URL" 2>/dev/null)

BASE_REF=$(echo "$PR_DATA" | grep -o '"base":{"label":"[^"]*"' | cut -d'"' -f8 | cut -d: -f2-)
HEAD_REF=$(echo "$PR_DATA" | grep -o '"head":{"label":"[^"]*"' | cut -d'"' -f8 | cut -d: -f2-)

cat > "$METADATA_FILE" << EOF
{
  "download_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "repository": {
    "ghes_host": "$GHES_HOST",
    "owner": "$OWNER",
    "repository": "$REPO"
  },
  "pr": {
    "number": $PR_NUMBER,
    "base_ref": "$BASE_REF",
    "head_ref": "$HEAD_REF"
  },
  "statistics": {
    "total_files": $TOTAL_FILES,
    "successful_downloads": $SUCCESSFUL_DOWNLOADS,
    "failed_downloads": $FAILED_DOWNLOADS
  }
}
EOF

echo ""
echo "📊 Download Summary:"
echo "  - Total files: $TOTAL_FILES"
echo "  - Successful downloads: $SUCCESSFUL_DOWNLOADS"
echo "  - Failed downloads: $FAILED_DOWNLOADS"
echo "  - Output directory: $OUTPUT_DIR"
echo ""
echo "📁 Directory structure created:"
echo "  $OUTPUT_DIR/"
echo "  ├── source/         # Files from source branch"
echo "  ├── target/         # Files from target branch"  
echo "  └── metadata/       # PR info and metadata"
echo "      └── pr-info.json"
echo ""

if [ $FAILED_DOWNLOADS -gt 0 ]; then
    echo "⚠️  Some downloads had issues. Check logs above for details."
fi

exit 0
