# ============================================================================
# GitHub Copilot Workflows Deployment Script (PowerShell)
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
# Usage: .\deploy-to-repo.ps1 -GhesHost <host> -Owner <org> -Repo <repo> -GhToken <token>
#
# Example: .\deploy-to-repo.ps1 -GhesHost ghes.company.com -Owner myorg -Repo myproject -GhToken ghp_xxxxx
# ============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, HelpMessage="Your GHES hostname (e.g., ghes.company.com)")]
    [string]$GhesHost,
    
    [Parameter(Mandatory=$true, HelpMessage="Organization name (must be same org where GHES_CodingAgent is cloned)")]
    [string]$Owner,
    
    [Parameter(Mandatory=$true, HelpMessage="Target repository name")]
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
Write-ColorOutput "  GitHub Copilot Workflows Deployment (Reusable Workflow Mode)" "Cyan"
Write-ColorOutput "============================================================================" "Cyan"
Write-Host ""
Write-Host "Target Repository: " -NoNewline
Write-ColorOutput "https://$GhesHost/$Owner/$Repo" "Green"
Write-Host "Master Workflows:  " -NoNewline
Write-ColorOutput "$Owner/GHES_CodingAgent" "Green"
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
    
    # Copy caller workflow files and update the org reference
    Write-Success "Copying caller workflow files..."
    $CoderContent = Get-Content "$SourceDir/.github/workflows/copilot-coder.yml" -Raw
    $CoderContent = $CoderContent -replace "ghes-test/GHES_CodingAgent", "$Owner/GHES_CodingAgent"
    Set-Content -Path ".github/workflows/copilot-coder.yml" -Value $CoderContent
    
    $ReviewerContent = Get-Content "$SourceDir/.github/workflows/copilot-reviewer.yml" -Raw
    $ReviewerContent = $ReviewerContent -replace "ghes-test/GHES_CodingAgent", "$Owner/GHES_CodingAgent"
    Set-Content -Path ".github/workflows/copilot-reviewer.yml" -Value $ReviewerContent
    
    Write-Step "Creating labels..."
    
    Create-Label -Name "copilot" -Color "7057ff" -Description "Trigger the Copilot CLI agent" -GhesHostname $GhesHost
    Create-Label -Name "in-progress" -Color "fbca04" -Description "Copilot is working on this issue" -GhesHostname $GhesHost
    Create-Label -Name "ready-for-review" -Color "0e8a16" -Description "Ready for code review" -GhesHostname $GhesHost
    
    Write-Step "Committing changes..."
    
    git add -A
    $CommitMessage = @"
feat: Add GitHub Copilot Coder and Reviewer workflows

This commit adds caller workflows that reference the master workflows
in $Owner/GHES_CodingAgent repository.

Files added:
- .github/workflows/copilot-coder.yml (caller workflow)
- .github/workflows/copilot-reviewer.yml (caller workflow)

Benefits of reusable workflows:
- No scripts or config files needed in this repository
- Automatic updates when master workflow is improved
- Consistent behavior across all repositories

Prerequisites:
- GH_TOKEN secret (Classic PAT with repo, workflow scopes)
- COPILOT_TOKEN secret (for Copilot API access)
- CONTEXT7_API_KEY secret (optional, for documentation)
- GitHub CLI installed on self-hosted runner
- Access to $Owner/GHES_CodingAgent repository
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

| File | Description |
|------|-------------|
| ``.github/workflows/copilot-coder.yml`` | Caller workflow for code generation |
| ``.github/workflows/copilot-reviewer.yml`` | Caller workflow for PR reviews |

### ✨ Reusable Workflow Architecture

These are **lightweight caller workflows** that invoke the master workflows from:
``````
$Owner/GHES_CodingAgent
``````

### ⚠️ Required Setup (Before Merging)

#### 1. Configure Organization or Repository Secrets

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
- Add the ``copilot`` label to a PR to trigger AI review
- Posts review comments with findings
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
    Write-Host "2. Add these secrets to the organization or repository:"
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
