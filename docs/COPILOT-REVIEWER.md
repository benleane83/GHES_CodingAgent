# 🤖 Copilot PR Reviewer for GHES

> **Automated pull request review using GitHub Copilot CLI on GitHub Enterprise Server**

## 📋 Overview

This workflow automatically reviews pull requests using GitHub Copilot CLI and posts AI-generated code review comments directly to your PRs. It analyzes code changes, identifies potential issues (security, performance, quality), and provides recommendations.

### ✨ Key Features

- 🔄 **Automatic PR Review** - Triggers on PR open/sync automatically
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

The workflow is **enabled by default**. It triggers automatically on:
- Pull request opened
- Pull request synchronized (new commits)

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

When a PR is opened or updated:

1. 🔄 Workflow triggers automatically
2. 🤖 Copilot analyzes changed files
3. 💬 Review comments posted to PR
4. 📊 Summary added to workflow run

## 🏗️ Architecture

### Workflow Flow

```
Pull Request Opened/Updated
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

### Key Scripts

| Script | Purpose |
|--------|---------|
| `scripts/get-pr-diff.sh` | Fetch list of changed files from PR |
| `scripts/download-pr-files.sh` | Download file contents from both branches |
| `scripts/analyze-with-copilot.sh` | Run Copilot CLI analysis |
| `scripts/post-pr-comment.sh` | Post findings as PR review comments |

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

## 📊 Performance

### Typical Execution Time

| Phase | Duration |
|-------|----------|
| Setup & Cache | 30-60 seconds |
| Download Files | 30-90 seconds |
| Copilot Analysis | 1-3 minutes |
| Post Comments | 30-60 seconds |
| **Total** | **2-5 minutes** |

*Times depend on PR size and Copilot server load*

### Cache Performance

After first run:
- ✅ Copilot CLI cached (~100MB)
- ✅ Dependencies cached
- 📉 Subsequent runs: ~30-50% faster

## 🎯 Use Cases

### ✅ Best For

- Automated code quality checks
- Security vulnerability detection
- Performance issue identification
- Best practices enforcement
- New developer code review
- CI/CD quality gate

### ⚠️ Limitations

- Cannot review architecture decisions
- Cannot verify business logic correctness
- Limited context (doesn't see full codebase)
- Should not be the sole review method
- Requires human review for security-critical code

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

### Best Practices

1. **Always review Copilot findings** - It's a tool, not infallible
2. **Don't merge without human review** - AI complements, doesn't replace
3. **Configure appropriate model** - Balance cost vs. quality
4. **Monitor for false positives** - Report patterns to Copilot team
5. **Rotate credentials regularly** - Follow security policies

## 🐛 Troubleshooting

### Workflow Not Triggering

**Problem:** Workflow runs but doesn't analyze

**Solution:**
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

## 📈 Monitoring

### View Workflow Runs

```bash
# List recent PR reviews
gh run list --workflow=copilot-reviewer.yml --limit 20

# View specific run
gh run view <run-id>

# Check run logs
gh run view <run-id> --log
```

### Track Metrics

Monitor these KPIs:

- ⏱️ **Execution Time**: Target < 5 minutes
- ✅ **Success Rate**: Target > 95%
- 💬 **Comments/PR**: Issues found per PR
- 🔄 **Cache Hit Rate**: Should improve over time

## 🔄 Integration with Coder Workflow

This reviewer workflow integrates with the Copilot Coder workflow:

```
Issue Created
     ↓
Label: "copilot" added
     ↓
Coder Workflow: Generates code
     ↓
PR Created
     ↓
Reviewer Workflow: Reviews generated code
     ↓
Developer: Merges if approved
```

Both workflows use:
- Same GitHub Actions environment
- Same Copilot CLI installation
- Cache sharing for performance

## 📚 Advanced Usage

### Custom Analysis Prompts

To customize Copilot analysis, edit the prompt in `scripts/analyze-with-copilot.sh`:

```bash
# Find this section:
ANALYSIS_PROMPT="Analyze ALL the files..."

# Modify to add custom analysis rules:
ANALYSIS_PROMPT="Analyze ALL the files with focus on:
- Security vulnerabilities
- Performance optimizations
- TypeScript type safety
- Error handling..."
```

### Filtering by File Type

Modify `analyze-with-copilot.sh` to analyze only specific files:

```bash
# Instead of:
FILES=($(find . -type f ! -path "*/pr-comments/*" ...))

# Use:
FILES=($(find . -type f -name "*.ts" -o -name "*.tsx" ...))
```

### Integration with Branch Protection

Configure branch protection rule:

1. Go to Settings → Branches
2. Add branch protection rule for target branch
3. Require "Copilot PR Reviewer" status check
4. This makes review optional or required based on status

## 🤝 Troubleshooting & Support

### Check Logs

1. Go to Actions tab
2. Select workflow run
3. Click specific step to see logs
4. Look for error messages

### Enable Debug Logging

Add to workflow step:

```yaml
- name: Enable Debug
  run: set -x
```

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

## 📄 License

This workflow is provided as-is for use with GitHub Enterprise Server.

## 🙏 Acknowledgments

- Original ADO Reviewer Agent by [0GiS0](https://github.com/0GiS0)
- GitHub Copilot team for excellent AI capabilities
- GitHub Actions team for workflow infrastructure

---

<div align="center">

**Automated PR Reviews with GitHub Copilot on GHES**

</div>
