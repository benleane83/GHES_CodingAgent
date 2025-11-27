# 🤖 Copilot PR Reviewer for GHES

> **Automated pull request review using GitHub Copilot CLI on GitHub Enterprise Server**

## 📋 Overview

This workflow automatically reviews pull requests using GitHub Copilot CLI and posts AI-generated code review comments directly to your PRs. It analyzes code changes, identifies potential issues (security, performance, quality), and provides recommendations.

### ✨ Key Features

- 🏷️ **Label-Triggered Review** - Manually trigger by adding the `copilot` label
- 🤖 **AI-powered Analysis** - GitHub Copilot CLI analyzes all changed files
- 🐛 **Issue Detection** - Identifies security, performance, and code quality issues
- 💬 **Auto Comments** - Posts review findings as PR comments
- 📦 **Artifact Logging** - Captures complete analysis for reference
- ⚡ **Caching** - Caches Copilot CLI for faster runs
- 🎯 **Customizable Model** - Configure AI model (claude-haiku-4.5, gpt-4o, etc.)

## 🚀 Quick Start

### 1️⃣ Prerequisites

Ensure your GHES instance supports:
- GitHub Actions enabled
- Runners with internet access to npm registry and GitHub Copilot API
- Node.js 20+ available (GitHub Actions default)

### 2️⃣ Enable the Workflow

The workflow triggers when you **add the `copilot` label** to a pull request:
- Review is **on-demand** - it only runs when you explicitly request it
- Add the `copilot` label to trigger an AI review
- Remove and re-add the label to re-run the review after updates

### 3️⃣ Optional Configuration

Edit `.github/workflows/copilot-reviewer.yml` to customize:

```yaml
env:
  MODEL: claude-haiku-4.5          # Change AI model
  COPILOT_VERSION: latest          # Pin specific Copilot CLI version
```

Supported models:
- `claude-haiku-4.5` (default - fast, low cost)
- `claude-sonnet-4` (balanced)
- `gpt-4o` (GPT-4 equivalent)
- `o1-preview` (reasoning)
- `o1-mini` (light reasoning)

### 4️⃣ Watch Reviews Appear

When the `copilot` label is added to a PR:

1. 🏷️ You add the `copilot` label to the PR
2. 🔄 Workflow triggers
3. 🤖 Copilot analyzes changed files
4. 💬 Review comments posted to PR
5. 📊 Summary added to workflow run

## 🏗️ Architecture

### Workflow Flow

```
Add 'copilot' label to PR
         ↓
    Setup Environment
  (Node.js, Copilot CLI)
         ↓
  Get PR Differences
    (GitHub API)
         ↓
 Download Modified Files
  (from source & target branches)
         ↓
Analyze with Copilot CLI
  (Identifies issues)
         ↓
Post Review Comments
  (to PR using GitHub API)
         ↓
Upload Artifacts
  (Analysis for reference)
         ↓
  ✅ Review Complete
```

## 📁 Analysis Output

### Comment Format

Copilot generates markdown comments for each file with issues:

```markdown
# 🔬 path/to/file.js analysis

## 📊 Overview
Brief description of what this file does.

## ⚠️ Issues and Recommendations

### 🔴 [Security]: SQL Injection vulnerability

\`\`\`javascript
// Problematic code
const query = "SELECT * FROM users WHERE id = " + userId;
\`\`\`

**Problem:** String concatenation allows SQL injection attacks.

**Recommendation:** Use parameterized queries.

\`\`\`javascript
// Fixed code
const query = "SELECT * FROM users WHERE id = ?";
db.execute(query, [userId]);
\`\`\`

## ✅ Summary
- **Overall Status:** ⚠️ Needs Attention
- **Priority:** High
- **Action Required:** Yes
```

### Artifacts

Each workflow run uploads analysis artifacts containing:

```
pr-analysis/
├── source/                    # Changed files from PR
│   ├── file1.js
│   ├── file2.py
│   └── pr-comments/           # Generated analyses
│       ├── file1_js_analysis.md
│       └── file2_py_analysis.md
├── target/                    # Files from target branch
│   ├── file1.js
│   └── file2.py
└── metadata/                  # Analysis metadata
    └── pr-info.json
```

Download artifacts from Actions tab to review full analysis offline.

## ⚙️ Configuration

### Environment Variables

Edit `.github/workflows/copilot-reviewer.yml`:

```yaml
env:
  MODEL: claude-haiku-4.5              # AI model to use
  COPILOT_VERSION: latest              # Copilot CLI version
  ANALYSIS_DIR: ${{ github.workspace }}/pr-analysis
  DIFF_FILE: ${{ github.workspace }}/pr-diff.json
```

### Network Requirements

Workflow needs outbound HTTPS access to:

| Service | Host | Port | Purpose |
|---------|------|------|---------|
| **npm Registry** | `registry.npmjs.org` | 443 | Download @github/copilot |
| **GitHub API** | `<your-ghes-host>` | 443 | PR data and posting comments |
| **Copilot API** | `copilot-api.github.com` | 443 | AI analysis |

### Firewall Configuration

If runners are behind a firewall:

```bash
# Allow outbound HTTPS
Allow: registry.npmjs.org:443
Allow: copilot-api.github.com:443
Allow: <your-ghes-host>:443
```

## 🔒 Security Considerations

### Token Management

- ✅ Uses `github.token` (automatic, scoped)
- ✅ Token has limited permissions (PR-scoped)
- ✅ Rotates with each workflow run
- ❌ Never commit secrets to repo

### Code Analysis

- 🔍 Copilot analysis runs on GHES infrastructure
- 🔍 File content sent to Copilot API for analysis
- 🔍 Comments stored in GitHub PR
- 🔒 Ensure Copilot API access is authorized

## 🐛 Troubleshooting

### Workflow Not Triggering

**Problem:** Workflow doesn't run when expected

**Solution:**
- ✅ Ensure you added the `copilot` label (workflow only triggers on label, not on PR open/sync)
- Check `.github/workflows/copilot-reviewer.yml` is present
- Verify workflow is enabled in Actions tab
- Check branch is in `on.pull_request.branches`

### No Comments Posted

**Problem:** Workflow runs but no review comments appear

**Causes & Solutions:**
- ✅ No issues found → Normal, check artifacts for details
- ✅ Files too large → Copilot may skip binary/large files
- ❌ API error → Check workflow logs for error details
- ❌ Token permissions → Ensure token has `pull-requests: write`

### Copilot Analysis Fails

**Problem:** Error in "Analyze with Copilot CLI" step

**Solutions:**
1. Check Copilot CLI version compatibility
2. Verify internet access to copilot-api.github.com
3. Review step logs for specific error
4. Try updating `COPILOT_VERSION` in workflow

### Files Not Downloaded

**Problem:** "Download Modified Files" step fails

**Solutions:**
1. Verify GitHub token has `contents: read` permission
2. Check network access to GitHub API
3. Verify PR branch still exists
4. Check repository size (large repos may timeout)

### Rate Limiting

**Problem:** Too many workflow runs causing rate limits

**Solution:**
- Limit PR trigger conditions
- Adjust per `COPILOT_VERSION` if needed
- Contact GitHub support for rate limit increase

### Performance Issues

**Problem:** Workflow taking too long

**Optimization:**
1. Reduce PR size (smaller PRs = faster analysis)
2. Switch to faster model (`claude-haiku-4.5`)
3. Check runner load/resources
4. Verify network connectivity

## 🤝 Troubleshooting & Support

### Check Logs

1. Go to Actions tab
2. Select workflow run
3. Click specific step to see logs
4. Look for error messages

### Common Issues

See [main TROUBLESHOOTING.md](TROUBLESHOOTING.md) for:
- GitHub API errors
- Copilot CLI issues
- Network problems
- Authentication failures

## 🔗 Related Documentation

- [Main README](../README.md) - Overview
- [GHES Setup Guide](GHES-SETUP.md) - Installation
- [Copilot Coder Workflow](../README.md#-github-copilot-coder) - Code generation
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub API Reference](https://docs.github.com/en/rest)

---

<div align="center">

**Automated PR Reviews with GitHub Copilot on GHES**

</div>
