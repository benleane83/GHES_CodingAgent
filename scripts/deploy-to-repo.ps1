# ============================================================================
# GitHub Copilot Workflows Deployment Script (PowerShell)
# ============================================================================
# This script deploys the Copilot Coder and Copilot Reviewer workflows
# to a target repository on GitHub Enterprise Server.
#
# Usage: .\deploy-to-repo.ps1 -GhesHost <host> -Owner <owner> -Repo <repo> -GhToken <token>
#
# Example: .\deploy-to-repo.ps1 -GhesHost vm-ghes.company.com -Owner myorg -Repo myrepo -GhToken ghp_xxxxx
# ============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, HelpMessage="Your GHES hostname (e.g., vm-ghes.company.com)")]
    [string]$GhesHost,
    
    [Parameter(Mandatory=$true, HelpMessage="Repository owner (org or user)")]
    [string]$Owner,
    
    [Parameter(Mandatory=$true, HelpMessage="Repository name")]
    [string]$Repo,
    
    [Parameter(Mandatory=$true, HelpMessage="Classic PAT with repo and workflow scopes")]
    [string]$GhToken
)

$ErrorActionPreference = "Stop"

# Get the script directory and source directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SourceDir = Split-Path -Parent $ScriptDir

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-ColorOutput "🔹 $Message" "Yellow"
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "  ✓ $Message" "Green"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "  ⚠ $Message" "Yellow"
}

function Create-Label {
    param(
        [string]$Name,
        [string]$Color,
        [string]$Description,
        [string]$GhesHostname
    )
    
    # Use gh api with explicit hostname for GHES compatibility
    $LabelPayload = @{
        name = $Name
        color = $Color
        description = $Description
    } | ConvertTo-Json
    
    $result = $LabelPayload | gh api --hostname $GhesHostname -X POST "repos/$Owner/$Repo/labels" --input - 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Created label: $Name"
    }
    else {
        Write-Warning "Label exists or error: $Name"
    }
}

# ============================================================================
# Main Script
# ============================================================================

Write-Host ""
Write-ColorOutput "============================================================================" "Cyan"
Write-ColorOutput "  GitHub Copilot Workflows Deployment" "Cyan"
Write-ColorOutput "============================================================================" "Cyan"
Write-Host ""
Write-Host "Target: " -NoNewline
Write-ColorOutput "https://$GhesHost/$Owner/$Repo" "Green"
Write-Host ""

# Authenticate gh CLI with GHES
Write-Step "Authenticating with GHES..."
$GhToken | gh auth login --hostname $GhesHost --with-token
if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "Failed to authenticate with GHES" "Red"
    exit 1
}
gh auth status --hostname $GhesHost

# Create temporary directory for cloning
$TempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

try {
    Write-Step "Cloning target repository..."
    Push-Location $TempDir
    
    git clone "https://x-access-token:$GhToken@$GhesHost/$Owner/$Repo.git" target-repo
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to clone repository"
    }
    
    Set-Location target-repo
    
    # Configure git
    git config user.name "GitHub Copilot Setup"
    git config user.email "copilot-setup@$GhesHost"
    
    # Create branch for deployment
    $BranchName = "setup/copilot-workflows"
    git checkout -b $BranchName 2>$null
    if ($LASTEXITCODE -ne 0) {
        git checkout $BranchName
    }
    
    Write-Step "Creating directory structure..."
    
    # Create directories
    New-Item -ItemType Directory -Path ".github/workflows" -Force | Out-Null
    New-Item -ItemType Directory -Path "scripts" -Force | Out-Null
    
    # Copy workflow files
    Write-Success "Copying workflow files..."
    Copy-Item "$SourceDir/.github/workflows/copilot-coder.yml" ".github/workflows/"
    Copy-Item "$SourceDir/.github/workflows/copilot-reviewer.yml" ".github/workflows/"
    
    # Copy scripts
    Write-Success "Copying scripts..."
    Copy-Item "$SourceDir/scripts/prepare-commit.sh" "scripts/"
    Copy-Item "$SourceDir/scripts/push-branch.sh" "scripts/"
    Copy-Item "$SourceDir/scripts/post-workflow-comment.sh" "scripts/"
    Copy-Item "$SourceDir/scripts/get-pr-diff.sh" "scripts/"
    Copy-Item "$SourceDir/scripts/download-pr-files.sh" "scripts/"
    Copy-Item "$SourceDir/scripts/analyze-with-copilot.sh" "scripts/"
    Copy-Item "$SourceDir/scripts/post-pr-comment.sh" "scripts/"
    
    # Copy MCP config
    Write-Success "Copying MCP configuration..."
    Copy-Item "$SourceDir/mcp-config.json" "."
    
    # Note: Workflow files now use dynamic GHES hostname detection via github.server_url
    # No hostname replacement needed!
    
    Write-Step "Creating labels..."
    
    Create-Label -Name "copilot" -Color "7057ff" -Description "Trigger the Copilot CLI agent" -GhesHostname $GhesHost
    Create-Label -Name "in-progress" -Color "fbca04" -Description "Copilot is working on this issue" -GhesHostname $GhesHost
    Create-Label -Name "ready-for-review" -Color "0e8a16" -Description "Ready for code review" -GhesHostname $GhesHost
    
    Write-Step "Committing changes..."
    
    git add -A
    $CommitMessage = @"
feat: Add GitHub Copilot Coder and Reviewer workflows

This commit adds:
- copilot-coder.yml: Generates code from GitHub issues
- copilot-reviewer.yml: Automatically reviews PRs
- Required scripts for workflow execution
- MCP server configuration

Prerequisites:
- GH_TOKEN secret (Classic PAT with repo, workflow scopes)
- COPILOT_TOKEN secret (for Copilot API access)
- CONTEXT7_API_KEY secret (optional, for documentation)
- GitHub CLI installed on self-hosted runner
"@
    git commit -m $CommitMessage
    
    Write-Step "Pushing branch..."
    git push -u origin $BranchName
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to push branch"
    }
    
    Write-Step "Creating Pull Request..."
    
    $PrBody = @"
## 🤖 GitHub Copilot Workflows Setup

This PR adds the GitHub Copilot Coder and Reviewer workflows to this repository.

### 📦 What's Included

- ``.github/workflows/copilot-coder.yml`` - Generates code from GitHub issues
- ``.github/workflows/copilot-reviewer.yml`` - Automatically reviews PRs
- ``.github/copilot-instructions.md`` - Instructions for Copilot CLI
- ``scripts/`` - Required automation scripts
- ``mcp-config.json`` - MCP server configuration

### ⚠️ Required Setup (Before Merging)

#### 1. Configure Repository Secrets

Go to **Settings → Secrets and variables → Actions** and add:

| Secret | Required | Description |
|--------|----------|-------------|
| ``GH_TOKEN`` | ✅ Yes | Classic PAT from GHES with ``repo`` and ``workflow`` scopes |
| ``COPILOT_TOKEN`` | ✅ Yes | Token for GitHub Copilot API access |
| ``CONTEXT7_API_KEY`` | ❌ Optional | API key for Context7 documentation service |

#### 2. Self-Hosted Runner Prerequisites

Your runner must have these tools pre-installed:
- **GitHub CLI (``gh``)** - [Installation instructions](https://cli.github.com/)

### 🚀 How to Use

#### Copilot Coder
1. Create an issue with a clear description
2. Add the ``copilot`` label
3. Wait for Copilot to generate code and create a PR

#### Copilot Reviewer
- Automatically runs on every PR
- Posts review comments with findings

### 📚 Documentation

See the [GHES Setup Guide](docs/GHES-SETUP.md) for detailed instructions.
"@

    # Save PR body to temp file to handle special characters
    $PrBodyFile = Join-Path $TempDir "pr_body.md"
    $PrBody | Out-File -FilePath $PrBodyFile -Encoding utf8
    
    # Use gh api to create PR on GHES (gh pr create doesn't work well with GHES)
    $PrPayload = @{
        title = "🤖 Add GitHub Copilot Coder and Reviewer Workflows"
        body = $PrBody
        head = $BranchName
        base = "main"
    } | ConvertTo-Json
    
    $PrResponse = $PrPayload | gh api --hostname $GhesHost -X POST "repos/$Owner/$Repo/pulls" --input -
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create PR"
    }
    
    $PrUrl = ($PrResponse | ConvertFrom-Json).html_url
    
    Write-Host ""
    Write-ColorOutput "============================================================================" "Green"
    Write-ColorOutput "  ✅ Deployment Complete!" "Green"
    Write-ColorOutput "============================================================================" "Green"
    Write-Host ""
    Write-Host "Pull Request created: " -NoNewline
    Write-ColorOutput $PrUrl "Cyan"
    Write-Host ""
    Write-ColorOutput "⚠️  Next Steps:" "Yellow"
    Write-Host ""
    Write-Host "1. Review and merge the PR"
    Write-Host ""
    Write-Host "2. Add these secrets to the repository:"
    Write-Host "   - GH_TOKEN: Classic PAT with repo, workflow scopes (from GHES)"
    Write-Host "   - COPILOT_TOKEN: Token for Copilot API"
    Write-Host "   - CONTEXT7_API_KEY: (Optional) Context7 API key"
    Write-Host ""
    Write-Host "3. Ensure your self-hosted runner has GitHub CLI installed:"
    Write-Host "   See: https://cli.github.com/manual/installation"
    Write-Host ""
    Write-ColorOutput "Done!" "Green"
}
finally {
    # Cleanup
    Pop-Location
    if (Test-Path $TempDir) {
        Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue
    }
}
