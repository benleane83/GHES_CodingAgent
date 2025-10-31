# 🚀 Reviewer Integration Guide

> Quick start guide for integrating the Copilot PR Reviewer into your GHES workflow

## What Was Added

### New Files

```
.github/workflows/copilot-reviewer.yml          # Automatic PR review workflow
scripts/
  ├── get-pr-diff.sh                           # Get changed files from PR
  ├── download-pr-files.sh                     # Download changed files
  ├── analyze-with-copilot.sh                  # Run Copilot analysis
  └── post-pr-comment.sh                       # Post review comments

docs/
  ├── COPILOT-REVIEWER.md                      # Complete reviewer guide
  └── REVIEWER-MIGRATION.md                    # ADO-to-GHES adaptation guide
```

### Modified Files

```
README.md                                       # Added reviewer features
```

## ✨ What's New

The **Copilot PR Reviewer** automatically:

1. ✅ Triggers on every pull request (open/update)
2. ✅ Downloads changed files from PR
3. ✅ Analyzes code with Copilot CLI
4. ✅ Posts review comments with findings
5. ✅ Saves complete analysis as artifacts

## 🎯 Quick Integration Steps

### Step 1: No Configuration Needed! ✨

The reviewer workflow is **enabled by default**:
- ✅ Workflow file in place: `.github/workflows/copilot-reviewer.yml`
- ✅ Scripts ready: `scripts/get-pr-diff.sh`, etc.
- ✅ Uses existing GitHub token
- ✅ No secrets needed (uses `${{ github.token }}`)

### Step 2: Create a Pull Request

Open any pull request in your repository:

```bash
git checkout -b feature/test
echo "# Test" > test.md
git add test.md
git commit -m "Add test file"
git push origin feature/test
```

Then create a PR on GitHub.

### Step 3: Watch the Reviewer Work

1. Go to Actions tab
2. Find "🤖 Copilot PR Reviewer" workflow
3. Watch it analyze the PR
4. See comments appear on the PR
5. Download analysis artifacts

## 📊 Example Workflow Run

### Workflow Execution

```
Pull Request opened/updated
         ↓
"🤖 Copilot PR Reviewer" workflow triggered
         ↓
✅ Setup Node.js 22.x
✅ Install Copilot CLI (from cache)
✅ Get PR Differences
✅ Download Modified Files
✅ Analyze with GitHub Copilot CLI
✅ Publish Comment on PR (if issues found)
✅ Upload Analysis Artifacts
         ↓
Workflow Complete!
```

### Expected Output

**On PR:** Review comments appear directly on changed lines

```markdown
# 🔬 src/api.js analysis

## ⚠️ Issues and Recommendations

### 🔴 [Security]: SQL Injection vulnerability

**Problem:** User input directly concatenated into SQL query...
**Recommendation:** Use parameterized queries...
```

**In Actions:** Artifacts contain full analysis

```
pr-analysis/
├── source/           # Changed files from your PR
├── target/           # Files from base branch
└── metadata/         # Analysis metadata
```

## 🔧 Configuration Options

### Default Settings (No Action Needed)

```yaml
# .github/workflows/copilot-reviewer.yml
env:
  MODEL: claude-haiku-4.5     # Fast, cost-effective model
  COPILOT_VERSION: latest     # Latest Copilot CLI
```

### Customize (Optional)

Edit `.github/workflows/copilot-reviewer.yml`:

```yaml
env:
  MODEL: claude-sonnet-4      # More powerful analysis
  COPILOT_VERSION: 0.0.352    # Pin specific version
```

Available models:
- `claude-haiku-4.5` (default - fast)
- `claude-sonnet-4` (balanced)
- `gpt-4o` (GPT-4)
- `o1-preview` (reasoning)
- `o1-mini` (light reasoning)

## 🎯 Triggered Automatically

The reviewer triggers **automatically** on:

- ✅ Pull request opened
- ✅ Pull request updated (new commits)
- ✅ All branches (configurable in workflow file)

**No labels or manual triggers needed!**

## 📊 Results & Artifacts

### Review Comments

Comments posted directly to PR:
- 🔒 Security issues
- ⚡ Performance concerns
- 🧹 Code quality suggestions
- 📝 Best practices

### Artifacts

Download from Actions tab for offline review:
- Complete file analysis
- Source/target branch versions
- Metadata and statistics

**Retention:** 30 days (adjustable in workflow)

## 🆘 Troubleshooting

### Workflow Not Running

**Check:**
1. Go to Actions tab
2. Verify workflow is enabled
3. Check repository has workflows enabled
4. Look for error messages

### No Comments Posted

**Possible Reasons:**
- ✅ No issues found (good!)
- ❌ API error → Check logs
- ❌ Permission issue → Check token scopes
- ❌ Files too large → Check file sizes

### Performance Issues

**Optimize:**
- Use `claude-haiku-4.5` (faster)
- Reduce PR size (smaller PRs = faster analysis)
- Check runner resources
- Verify network connectivity

## 📚 Documentation

For detailed information, see:

| Document | Purpose |
|----------|---------|
| [COPILOT-REVIEWER.md](../docs/COPILOT-REVIEWER.md) | Complete reviewer guide |
| [REVIEWER-MIGRATION.md](../docs/REVIEWER-MIGRATION.md) | How ADO was adapted to GHES |
| [README.md](../README.md) | Main project documentation |
| [GHES-SETUP.md](../docs/GHES-SETUP.md) | Setup instructions |

## 🔄 Integration with Coder Workflow

Both workflows work together:

```
Issue with "copilot" label
         ↓
Coder generates code
         ↓
PR created automatically
         ↓
Reviewer analyzes code
         ↓
Developer reviews both feedback sources
         ↓
Merge when ready
```

## ✅ Verification Checklist

Confirm everything is working:

- [ ] Workflow file exists: `.github/workflows/copilot-reviewer.yml`
- [ ] Scripts present in `scripts/` directory
- [ ] Workflow runs on PR create/update
- [ ] Comments appear on PRs
- [ ] Artifacts download successfully

## 🚀 Next Steps

1. **Create a test PR** to see reviewer in action
2. **Review the comments** and analysis quality
3. **Adjust model** if needed (see Configuration)
4. **Monitor runs** in Actions tab
5. **Read documentation** for advanced usage

## 💡 Tips & Best Practices

- ✅ Always review AI findings (it's a tool, not infallible)
- ✅ Use comments to improve code quality
- ✅ Don't rely solely on AI review (have humans review too)
- ✅ Monitor costs if using expensive models
- ✅ Check artifacts for detailed analysis

## 🐛 Report Issues

If you encounter issues:

1. Check [TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md)
2. Review workflow logs in Actions tab
3. Download artifacts for error details
4. Check GHES system logs if available

## 📞 Support

- 📖 Full documentation: [docs/COPILOT-REVIEWER.md](../docs/COPILOT-REVIEWER.md)
- 🔗 Original project: [0GiS0/ADO_ReviewerAgent](https://github.com/0GiS0/ADO_ReviewerAgent)
- 📚 GitHub Actions: [github.com/features/actions](https://github.com/features/actions)

---

**Happy reviewing! 🚀**

The Copilot PR Reviewer is now active and will automatically analyze every pull request!
