#!/bin/bash
# ============================================================================
# GitHub Copilot Workflows Deployment Script
# ============================================================================
# This script deploys the Copilot Coder and Copilot Reviewer caller workflows
# to a target repository on GitHub Enterprise Server.
#
# PREREQUISITE: You must first clone this repository (GHES_CodingAgent) into
# your GHES organization. Then run this script FROM that cloned repo to deploy
# to other repositories in the SAME organization.
#
# The caller workflows reference the master workflows in GHES_CodingAgent,
# so NO scripts folder is needed in the target repository!
#
# Usage: ./deploy-to-repo.sh <ghes-host> <org> <repo> <gh-token>
#
# Example: ./deploy-to-repo.sh ghes.company.com myorg myproject ghp_xxxxx
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check arguments
if [ "$#" -lt 4 ]; then
    echo -e "${RED}Usage: $0 <ghes-host> <org> <repo> <gh-token>${NC}"
    echo ""
    echo "Arguments:"
    echo "  ghes-host  - Your GHES hostname (e.g., ghes.company.com)"
    echo "  org        - Organization name (must be same org where GHES_CodingAgent is cloned)"
    echo "  repo       - Target repository name"
    echo "  gh-token   - Classic PAT with repo and workflow scopes"
    echo ""
    echo "Example:"
    echo "  $0 ghes.company.com myorg myproject ghp_xxxxx"
    exit 1
fi

GHES_HOST="$1"
OWNER="$2"
REPO="$3"
GH_TOKEN="$4"

# Source directory (where this script lives)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}  GitHub Copilot Workflows Deployment (Reusable Workflow Mode)${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""
echo -e "Target Repository: ${GREEN}https://${GHES_HOST}/${OWNER}/${REPO}${NC}"
echo -e "Master Workflows:  ${GREEN}${OWNER}/GHES_CodingAgent${NC}"
echo ""

# Authenticate gh CLI with GHES
echo -e "${YELLOW}🔐 Authenticating with GHES...${NC}"
echo "$GH_TOKEN" | gh auth login --hostname "$GHES_HOST" --with-token
gh auth status --hostname "$GHES_HOST"
echo ""

# Create temporary directory for cloning
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo -e "${YELLOW}📥 Cloning target repository...${NC}"
cd "$TEMP_DIR"
git clone "https://x-access-token:${GH_TOKEN}@${GHES_HOST}/${OWNER}/${REPO}.git" target-repo
cd target-repo

# Configure git
git config user.name "GitHub Copilot Setup"
git config user.email "copilot-setup@${GHES_HOST}"

# Create branch for deployment
BRANCH_NAME="setup/copilot-workflows"
git checkout -b "$BRANCH_NAME" 2>/dev/null || git checkout "$BRANCH_NAME"

echo ""
echo -e "${YELLOW}📁 Creating directory structure...${NC}"

# Create directories
mkdir -p .github/workflows

# Copy caller workflow files and update the org reference
echo -e "${GREEN}  ✓ Copying caller workflow files...${NC}"
sed "s|ghes-test/GHES_CodingAgent|${OWNER}/GHES_CodingAgent|g" \
    "$SOURCE_DIR/.github/workflows/copilot-coder.yml" > .github/workflows/copilot-coder.yml
sed "s|ghes-test/GHES_CodingAgent|${OWNER}/GHES_CodingAgent|g" \
    "$SOURCE_DIR/.github/workflows/copilot-reviewer.yml" > .github/workflows/copilot-reviewer.yml

# Copy MCP config (needed for Copilot CLI to find MCP servers)
echo -e "${GREEN}  ✓ Copying MCP configuration...${NC}"
cp "$SOURCE_DIR/mcp-config.json" .

echo ""
echo -e "${YELLOW}📝 Creating labels...${NC}"

# Create labels using gh api with explicit hostname (ignore errors if they already exist)
create_label() {
    local name="$1"
    local color="$2"
    local description="$3"
    
    # Use gh api with explicit hostname for GHES compatibility
    if gh api --hostname "$GHES_HOST" -X POST "repos/${OWNER}/${REPO}/labels" \
        -f name="$name" -f color="$color" -f description="$description" >/dev/null 2>&1; then
        echo -e "${GREEN}  ✓ Created label: $name${NC}"
    else
        echo -e "${YELLOW}  ⚠ Label exists or error: $name${NC}"
    fi
}

create_label "copilot" "7057ff" "Trigger the Copilot CLI agent"
create_label "in-progress" "fbca04" "Copilot is working on this issue"
create_label "ready-for-review" "0e8a16" "Ready for code review"

echo ""
echo -e "${YELLOW}💾 Committing changes...${NC}"

# Add and commit
git add -A
git commit -m "feat: Add GitHub Copilot Coder and Reviewer workflows

This commit adds caller workflows that reference the master workflows
in ${OWNER}/GHES_CodingAgent repository.

Files added:
- .github/workflows/copilot-coder.yml (caller workflow)
- .github/workflows/copilot-reviewer.yml (caller workflow)
- .github/copilot-instructions.md (Copilot CLI instructions)
- mcp-config.json (MCP server configuration)

Benefits of reusable workflows:
- No scripts folder needed in this repository
- Automatic updates when master workflow is improved
- Consistent behavior across all repositories

Prerequisites:
- GH_TOKEN secret (Classic PAT with repo, workflow scopes)
- COPILOT_TOKEN secret (for Copilot API access)
- CONTEXT7_API_KEY secret (optional, for documentation)
- GitHub CLI installed on self-hosted runner
- Access to ${OWNER}/GHES_CodingAgent repository"

echo ""
echo -e "${YELLOW}🚀 Pushing branch...${NC}"
git push -u origin "$BRANCH_NAME"

echo ""
echo -e "${YELLOW}📬 Creating Pull Request...${NC}"

PR_BODY="## 🤖 GitHub Copilot Workflows Setup

This PR adds the GitHub Copilot Coder and Reviewer workflows to this repository.

### 📦 What's Included

| File | Description |
|------|-------------|
| \`.github/workflows/copilot-coder.yml\` | Caller workflow for code generation |
| \`.github/workflows/copilot-reviewer.yml\` | Caller workflow for PR reviews |
| \`.github/copilot-instructions.md\` | Instructions for Copilot CLI |
| \`mcp-config.json\` | MCP server configuration |

### ✨ Reusable Workflow Architecture

These are **lightweight caller workflows** that invoke the master workflows from:
\`\`\`
${OWNER}/GHES_CodingAgent
\`\`\`

### ⚠️ Required Setup (Before Merging)

#### 1. Configure Repository Secrets

Go to **Settings → Secrets and variables → Actions** and add:

| Secret | Required | Description |
|--------|----------|-------------|
| \`GH_TOKEN\` | ✅ Yes | Classic PAT from GHES with \`repo\` and \`workflow\` scopes |
| \`COPILOT_TOKEN\` | ✅ Yes | Token for GitHub Copilot API access |
| \`CONTEXT7_API_KEY\` | ❌ Optional | API key for Context7 documentation service |

#### 2. Repository Access

Ensure this repository can access workflows from \`${OWNER}/GHES_CodingAgent\`.

#### 3. Self-Hosted Runner Prerequisites

Your runner must have these tools pre-installed:
- **GitHub CLI (\`gh\`)** - [Installation instructions](https://cli.github.com/)

### 🚀 How to Use

#### Copilot Coder
1. Create an issue with a clear description
2. Add the \`copilot\` label
3. Wait for Copilot to generate code and create a PR

#### Copilot Reviewer
- Automatically runs on every PR
- Posts review comments with findings
"

# Use gh api with explicit hostname for GHES compatibility
PR_RESPONSE=$(gh api --hostname "$GHES_HOST" -X POST "repos/${OWNER}/${REPO}/pulls" \
    -f title="🤖 Add GitHub Copilot Coder and Reviewer Workflows" \
    -f body="$PR_BODY" \
    -f head="$BRANCH_NAME" \
    -f base="main")

PR_URL=$(echo "$PR_RESPONSE" | grep -o '"html_url": *"[^"]*"' | head -1 | cut -d'"' -f4)

echo ""
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}  ✅ Deployment Complete!${NC}"
echo -e "${GREEN}============================================================================${NC}"
echo ""
echo -e "Pull Request created: ${BLUE}${PR_URL}${NC}"
echo ""
echo -e "${YELLOW}⚠️  Next Steps:${NC}"
echo ""
echo "1. Review and merge the PR"
echo ""
echo "2. Add these secrets to the repository:"
echo "   - GH_TOKEN: Classic PAT with repo, workflow scopes (from GHES)"
echo "   - COPILOT_TOKEN: Token for Copilot API"
echo "   - CONTEXT7_API_KEY: (Optional) Context7 API key"
echo ""
echo "3. Ensure your self-hosted runner has GitHub CLI installed:"
echo "   curl -L https://github.com/cli/cli/releases/download/v2.62.0/gh_2.62.0_linux_amd64.tar.gz -o /tmp/gh.tar.gz"
echo "   tar -xzf /tmp/gh.tar.gz -C /tmp"
echo "   sudo mv /tmp/gh_2.62.0_linux_amd64/bin/gh /usr/local/bin/"
echo ""
echo -e "${GREEN}Done!${NC}"
