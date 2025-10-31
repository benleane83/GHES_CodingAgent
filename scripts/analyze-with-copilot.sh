#!/bin/bash

# Analyze PR files with GitHub Copilot CLI
# This script reuses the original implementation with minor adjustments

echo "🤖 PR Analysis with GitHub Copilot CLI"
echo "======================================="

# Ensure GH_TOKEN is exported for Copilot CLI
if [ -z "$GH_TOKEN" ]; then
    echo "⚠️  Warning: GH_TOKEN environment variable not set"
    if [ -z "$GITHUB_TOKEN" ]; then
        echo "❌ ERROR: No authentication token found (GH_TOKEN or GITHUB_TOKEN)"
        exit 1
    else
        export GH_TOKEN="$GITHUB_TOKEN"
    fi
else
    export GH_TOKEN
fi

# Parameters
PR_DIRECTORY="$1"
OUTPUT_COMMENTS_DIR="${2:-$PR_DIRECTORY/pr-comments}"

echo "📋 Analysis configuration:"
echo "  - PR Directory: $PR_DIRECTORY"
echo "  - Output Comments Directory: $OUTPUT_COMMENTS_DIR"
echo ""

# Check if directory exists
if [ ! -d "$PR_DIRECTORY" ]; then
    echo "❌ ERROR: Directory $PR_DIRECTORY does not exist"
    exit 1
fi

# Create output directory for comments
mkdir -p "$OUTPUT_COMMENTS_DIR"

# Get list of files to analyze (get relative paths)
echo "🔍 Scanning files in directory..."
cd "$PR_DIRECTORY"
FILES=($(find . -type f ! -path "*/pr-comments/*" ! -name "pr-comment*.md" ! -name ".*" | sed 's|^\./||'))

if [ ${#FILES[@]} -eq 0 ]; then
    echo "❌ ERROR: No files found to analyze in $PR_DIRECTORY"
    exit 1
fi

echo "✅ Found ${#FILES[@]} files to analyze:"
for file in "${FILES[@]}"; do
    echo "   - $file"
done
echo ""

# Get model from environment or use default
MODEL="${MODEL:-claude-haiku-4.5}"
echo "🤖 Using model: $MODEL"
echo ""

# Build the list of files for the prompt
FILES_LIST=""
for file in "${FILES[@]}"; do
    FILES_LIST="${FILES_LIST}- \`$file\`"$'\n'
done

# Create the comprehensive prompt for Copilot
ANALYSIS_PROMPT="Analyze ALL the files in this Pull Request directory and generate a SEPARATE markdown file for EACH file analyzed.

📁 **Files to analyze:**
$FILES_LIST

🎯 **IMPORTANT INSTRUCTIONS:**

For EACH file listed above, you must:
1. Analyze the file thoroughly
2. Create a separate markdown file with the analysis if there is anything noteworthy (issues, recommendations)
3. Name each file following this pattern: replace \`/\` with \`_\` in the original path and add \`_analysis.md\` suffix
4. Save each file in the directory: \`$OUTPUT_COMMENTS_DIR/\`

📝 **Format for EACH analysis file:**

# 🔬 \$relative_path analysis

Provide a comprehensive review of this file including:

## 📊 Overview
Brief description of what this file does and its purpose in the codebase.

## ⚠️ Issues and Recommendations
If there are issues, list them with:
- **Issue type** (e.g., Security, Performance, Code Quality, Best Practices)
- **Description** of the problem
- **Code snippet** showing the problematic code
- **Recommendation** on how to fix it

Example format for issues:

### 🔴 [Issue Type]: Brief description

\`\`\`language
// Problematic code here
\`\`\`

**Problem:** Detailed explanation of the issue.

**Recommendation:** How to fix it.

\`\`\`language
// Suggested fix here
\`\`\`

## ✅ Summary
- **Overall Status:** ⚠️ Needs Attention / 🔴 Critical Issues / ✅ Good
- **Priority:** High/Medium/Low
- **Action Required:** Yes/No

IMPORTANT: Save the analysis in a file named with the pattern described above.
Focus only on this single file. Be thorough but concise."

# Execute copilot for analysis
cd "$PR_DIRECTORY"

echo "🤖 Generating analysis with Copilot..."
echo "🔐 Token status: GH_TOKEN is $([ -n "$GH_TOKEN" ] && echo "set" || echo "NOT set")"

# Try using gh CLI to login first to ensure proper authentication
if command -v gh &> /dev/null; then
    echo "🔑 Authenticating with GitHub CLI..."
    echo "$GH_TOKEN" | gh auth login --with-token 2>/dev/null || true
fi

# Execute copilot with explicit token in environment
GH_TOKEN="$GH_TOKEN" copilot -p "$ANALYSIS_PROMPT" --allow-all-tools --model "$MODEL" 2>&1

COPILOT_EXIT=$?

if [ $COPILOT_EXIT -ne 0 ]; then
    echo "⚠️  Copilot analysis completed with exit code: $COPILOT_EXIT"
else
    echo "✅ Copilot analysis completed successfully"
fi

# Summary
echo "=================================================="
echo "📊 Analysis Summary"
echo "=================================================="
echo "  - Total files analyzed: ${#FILES[@]}"
echo "  - Output directory: $OUTPUT_COMMENTS_DIR"

# Count generated analysis files
ANALYSIS_COUNT=$(ls -1 "$OUTPUT_COMMENTS_DIR"/*_analysis.md 2>/dev/null | wc -l)
echo "  - Analysis files generated: $ANALYSIS_COUNT"
echo ""

# List generated files if any
if [ $ANALYSIS_COUNT -gt 0 ]; then
    echo "📋 Generated analysis files:"
    ls -1 "$OUTPUT_COMMENTS_DIR"/*_analysis.md 2>/dev/null | while read -r file; do
        echo "   - $(basename "$file")"
    done
fi

exit 0
