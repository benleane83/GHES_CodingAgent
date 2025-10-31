# ADO to GHES Reviewer Workflow: Porting Guide

> Guide to understanding how the Azure DevOps Reviewer Agent was adapted for GitHub Enterprise Server

## 📋 Overview

This guide explains the key differences between the ADO Reviewer Agent and the GHES Copilot PR Reviewer, and how concepts were adapted between platforms.

## 🔄 Platform Comparison

### Azure DevOps vs GitHub Enterprise Server

| Aspect | Azure DevOps | GitHub Enterprise Server |
|--------|--------------|-------------------------|
| **Trigger** | Azure Pipelines YAML trigger | GitHub Actions on PR event |
| **Authentication** | Personal Access Token (Basic Auth) | Token with Bearer auth |
| **API Format** | Azure DevOps REST API | GitHub REST API v3 |
| **PR Metadata** | Pull Request object model | Pull Request object model |
| **File Downloads** | Git items API | GitHub contents API |
| **Comments** | Thread-based comments | Review comments |
| **Artifacts** | Build artifacts storage | GitHub Actions artifacts |
| **Caching** | Azure Pipelines cache | GitHub Actions cache |

## 🔧 Script Adaptations

### 1. Get PR Diff Script

#### ADO Version (`get-pr-diff.sh`)
- Uses Azure DevOps REST API `/diffs/commits` endpoint
- Extracts organization, project, repository from URI parsing
- Returns diff in Azure format with `changeCounts` and `changes` array
- Uses Basic authentication with PAT

#### GHES Version (`scripts/get-pr-diff.sh`)
- Uses GitHub API `/repos/{owner}/{repo}/pulls/{number}/files`
- Simpler parameters: GHES_HOST, OWNER, REPO, PR_NUMBER
- Returns compatible JSON structure for downstream scripts
- Uses Bearer token authentication
- Handles pagination for large PRs (100+ files)

**Key Changes:**
```bash
# ADO: Parse complex URI
ORG=$(echo $URI | awk -F'/' '{print $2}')
PROJECT=$(echo $URI | awk -F'/' '{print $3}')
REPO=$(echo $URI | awk -F'/' '{print $5}')

# GHES: Simple parameters
OWNER="$2"
REPO="$3"
```

### 2. Download Files Script

#### ADO Version
- Calls Azure DevOps `/items` API with `includeContent=true`
- Downloads both source and target branch versions
- Handles base64-encoded content from API
- Creates metadata JSON with ADO-specific info

#### GHES Version
- Uses GitHub `/repos/{owner}/{repo}/contents/{path}` API
- Downloads with `Accept: application/vnd.github.v3.raw` header
- Returns raw file content (no base64 decoding needed)
- Simpler error handling

**Key Differences:**
```bash
# ADO: Base64 decoding needed
jq -r '.content' | base64 -d > "$output_file"

# GHES: Raw content API
curl -H "Accept: application/vnd.github.v3.raw" > "$output_file"
```

### 3. Analyze with Copilot

#### Both Versions
- Identical prompt and analysis logic
- Same output format (markdown files)
- Uses Copilot CLI with configurable model

**No significant changes needed** - this script is platform-agnostic.

### 4. Post Comments Script

#### ADO Version
- Posts to `/pullRequests/{id}/threads` API
- Thread-based comment structure with comment type
- Uses status codes to track threads

#### GHES Version
- Posts to `/repos/{owner}/{repo}/pulls/{number}/reviews` API
- Review-based comments (modern GitHub approach)
- Uses same Bearer token as other scripts
- HTTP 200/201 success codes

**Key Difference:**
```bash
# ADO: Threads API
API_URL="dev.azure.com/$ORG/$PROJECT/_apis/git/...pullRequests/$PR_ID/threads"
PAYLOAD='{"comments": [{"content": "...", "commentType": 1}]}'

# GHES: Reviews API
API_URL="api.github.com/repos/$OWNER/$REPO/pulls/$PR_NUMBER/reviews"
PAYLOAD='{"body": "...", "event": "COMMENT"}'
```

## 🔀 Workflow Differences

### Azure Pipelines (ADO)

```yaml
trigger: none
pr:
  branches:
    include: [main, develop]

pool:
  vmImage: ubuntu-latest

steps:
  - task: NodeTool@0
  - template: templates/run-script.yml
  - task: PublishBuildArtifacts@1
```

### GitHub Actions (GHES)

```yaml
on:
  pull_request:
    types: [opened, synchronize]
    branches: [main, develop]

permissions:
  contents: read
  pull-requests: write

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/setup-node@v4
      - run: bash scripts/...
      - uses: actions/upload-artifact@v4
```

**Advantages of GitHub Actions:**
- ✅ Simpler syntax (native YAML, no templates)
- ✅ Built-in permissions model
- ✅ Automatic environment variables (github.*)
- ✅ No need for custom templates
- ✅ Artifact management integrated

## 📋 Variable Mapping

### ADO Pipeline Variables → GitHub Actions Variables

| ADO Variable | GitHub Variable | Purpose |
|-------------|-----------------|---------|
| `$(System.PullRequest.SourceRepositoryUri)` | Parsed to components | Repository URI |
| `$(System.PullRequest.PullRequestId)` | `${{ github.event.pull_request.number }}` | PR number |
| `$(System.PullRequest.SourceBranch)` | `${{ github.event.pull_request.head.ref }}` | Source branch |
| `$(System.PullRequest.TargetBranch)` | `${{ github.event.pull_request.base.ref }}` | Target branch |
| `$(AZURE_DEVOPS_EXT_PAT)` | `${{ github.token }}` | Authentication |
| `$(Build.ArtifactStagingDirectory)` | `${{ github.workspace }}` | Working directory |
| `$(Agent.OS)` | `${{ runner.os }}` | Operating system |

### Environment Setup

| Component | ADO | GHES |
|-----------|-----|------|
| **Node.js** | `task: NodeTool@0` | `actions/setup-node@v4` |
| **Authentication** | Environment variable `AZURE_DEVOPS_EXT_PAT` | `${{ github.token }}` |
| **Caching** | `task: Cache@2` | `actions/cache@v4` |
| **Artifact Upload** | `task: PublishBuildArtifacts@1` | `actions/upload-artifact@v4` |

## 🔐 Authentication Differences

### ADO Personal Access Token (PAT)

```bash
# ADO uses Basic authentication (PAT in username field)
AUTH_HEADER=$(printf "%s:" "$PAT" | base64 -w 0)
curl -H "Authorization: Basic $AUTH_HEADER" ...
```

Requirements:
- `Code (Read & Write)` scope
- `Pull Request (Contribute)` scope
- Manual token creation in ADO settings
- Long-lived (configurable expiry)

### GHES Bearer Token

```bash
# GHES uses Bearer token
curl -H "Authorization: Bearer $TOKEN" ...
```

Advantages:
- Automatic token provisioning (`${{ github.token }}`)
- Scoped permissions (fine-grained)
- Short-lived (per workflow run)
- Automatic rotation

## 📊 API Endpoint Mapping

### Getting PR Information

```bash
# ADO
https://dev.azure.com/{org}/{project}/_apis/git/repositories/{repo}/diffs/commits
?baseVersion={target-branch}&targetVersion={source-branch}
&baseVersionType=branch&targetVersionType=branch
&api-version=7.2-preview.1

# GHES
https://{ghes-host}/api/v3/repos/{owner}/{repo}/pulls/{pr-number}/files
```

### Downloading File Content

```bash
# ADO
https://dev.azure.com/{org}/{project}/_apis/git/repositories/{repo}/items
?path={file-path}&version={branch}
&versionType=branch&includeContent=true
&api-version=7.2-preview.1

# GHES
https://{ghes-host}/api/v3/repos/{owner}/{repo}/contents/{file-path}
?ref={branch}
# With header: Accept: application/vnd.github.v3.raw
```

### Posting Comments

```bash
# ADO
https://dev.azure.com/{org}/{project}/_apis/git/repositories/{repo}/pullRequests/{pr-id}/threads
?api-version=7.1

# GHES
https://{ghes-host}/api/v3/repos/{owner}/{repo}/pulls/{pr-number}/reviews
```

## 🎯 Feature Parity

### Fully Supported

- ✅ Automatic PR analysis trigger
- ✅ Multi-file analysis
- ✅ Issue detection and comments
- ✅ Artifact storage
- ✅ Execution logging
- ✅ Model selection
- ✅ Caching/performance optimization

### Differences

| Feature | ADO | GHES | Notes |
|---------|-----|------|-------|
| **Trigger** | Manual PR or label | Automatic on PR | GHES is more automatic |
| **Comment Type** | Threads | Reviews | GHES reviews are more modern |
| **Metadata Capture** | Full project info | Owner/repo | GHES simpler |
| **Error Reporting** | Pipeline step logs | Workflow step logs | Similar but different UI |

### Not Supported in GHES Version

- ❌ Manual trigger without PR (use issues instead)
- ❌ Multiple pipelines/conditions (GitHub Actions simpler)
- ❌ Custom cache keys beyond OS/model (GitHub Actions limitations)

## 🔄 Migration Strategy

If migrating from ADO to GHES:

### Phase 1: Parallel Operation

1. Keep ADO pipeline running
2. Deploy GHES workflow alongside
3. Monitor both for 1-2 sprints
4. Compare results

### Phase 2: Validation

1. Verify GHES accuracy matches ADO
2. Check comment format is acceptable
3. Test edge cases (large PRs, binary files)
4. Gather team feedback

### Phase 3: Cutover

1. Disable ADO pipeline
2. Make GHES workflow primary
3. Update documentation
4. Archive ADO configuration

## 🆘 Troubleshooting Migration

### ADO Scripts Not Compatible

**Issue**: Copy/pasting ADO scripts fails

**Solution**: Use GHES-adapted scripts in `scripts/` directory

### API Errors

**Issue**: "Not Found" or "Unauthorized"

**Solution**: 
- Verify GitHub token permissions
- Check repository visibility
- Ensure GHES_HOST parameter is correct

### Performance Different

**Issue**: GHES runs faster/slower than ADO

**Solution**:
- GHES uses GitHub's infrastructure (usually faster)
- Cache behavior similar
- Adjust model if needed

## 📚 Related Documentation

- [Copilot Reviewer Documentation](COPILOT-REVIEWER.md)
- [GHES Setup Guide](GHES-SETUP.md)
- [Original ADO Project](https://github.com/0GiS0/ADO_ReviewerAgent)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## 🔗 Resources

- [GitHub REST API](https://docs.github.com/en/rest)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Azure DevOps REST API](https://learn.microsoft.com/en-us/rest/api/azure/devops/)
- [Copilot CLI Documentation](https://github.com/github/copilot-cli)

---

**Original ADO Implementation**: [0GiS0/ADO_ReviewerAgent](https://github.com/0GiS0/ADO_ReviewerAgent)

**GHES Adaptation**: GHES Copilot Coder Project

Last Updated: 2025
