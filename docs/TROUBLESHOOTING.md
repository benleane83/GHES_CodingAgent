# 🔧 Troubleshooting Guide

This guide helps you diagnose and resolve common issues with the GitHub Copilot Coder workflow.

## 🚨 Common Issues

### 1. Workflow Not Triggering

**Symptom**: Adding the `copilot-generate` label doesn't trigger the workflow.

**Possible Causes & Solutions**:

- **Workflow file not in correct location**
  - ✅ Verify `.github/workflows/copilot-coder.yml` exists
  - ✅ Check file syntax with `yamllint` or GitHub Actions validator

- **Workflow disabled**
  - ✅ Go to Actions tab → Select workflow → Ensure it's enabled

- **Label name mismatch**
  - ✅ Verify label is exactly `copilot-generate` (case-sensitive)
  - ✅ Check workflow trigger configuration in YAML

- **Insufficient permissions**
  - ✅ Verify `GH_TOKEN` has required permissions
  - ✅ Check workflow permissions in YAML file

### 2. Authentication Errors

**Symptom**: Workflow fails with authentication errors.

**Error Messages**:
```
Error: Bad credentials
Error: Resource not accessible by integration
```

**Solutions**:

1. **Verify GH_TOKEN**:
   ```bash
   # Test token locally (replace YOUR_TOKEN)
   curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user
   ```

2. **Check token scopes**:
   - ✅ `repo` scope enabled
   - ✅ `copilot_requests` scope enabled
   - ✅ Token not expired

3. **Regenerate token**:
   - Go to GHES → Settings → Developer settings → Personal access tokens
   - Regenerate token with correct scopes
   - Update `GH_TOKEN` secret in repository

### 3. Copilot CLI Installation Fails

**Symptom**: Step "📦 Install Copilot CLI" fails.

**Error Messages**:
```
npm ERR! 404 Not Found - GET https://registry.npmjs.org/@github/copilot/-/copilot-X.X.X.tgz
```

**Solutions**:

1. **Verify Copilot version**:
   - Check if version exists: https://www.npmjs.com/package/@github/copilot
   - Update `COPILOT_VERSION` in workflow to latest stable version

2. **Network issues**:
   - Check if runner has internet access
   - Verify npm registry is accessible

3. **Use cache**:
   - Cache should prevent repeated downloads
   - Clear cache if corrupted: Delete and re-run workflow

### 4. MCP Server Errors

**Symptom**: Step "🧰 Check MCP Access" fails or times out.

**Error Messages**:
```
Error: Failed to connect to MCP server
Timeout waiting for MCP server response
```

**Solutions**:

1. **Check MCP configuration**:
   ```bash
   cat ~/.config/mcp-config.json
   ```
   - ✅ Verify JSON syntax is correct
   - ✅ Ensure all required MCP servers are listed

2. **Verify Context7 API key**:
   - Check if `CONTEXT7_API_KEY` secret is set
   - Test API key with Context7 service

3. **Skip MCP verification** (temporary):
   - Comment out "Check MCP Access" step in workflow
   - MCP servers will still be available to Copilot

4. **Check network connectivity**:
   - Ensure runner can access external MCP servers
   - Check firewall rules

### 5. Branch Creation Fails

**Symptom**: Step "🌿 Create Feature Branch" fails.

**Error Messages**:
```
fatal: A branch named 'copilot/123' already exists
```

**Solutions**:

1. **Branch already exists**:
   - Delete the existing branch:
     ```bash
     git branch -D copilot/123
     git push origin --delete copilot/123
     ```
   - Re-run workflow

2. **Permission issues**:
   - Verify `GH_TOKEN` has write access to repository
   - Check branch protection rules

### 6. Copilot Implementation Fails

**Symptom**: Step "🤖 Implement Changes with Copilot" fails.

**Error Messages**:
```
Error: Copilot request failed
Error: Rate limit exceeded
```

**Solutions**:

1. **Rate limiting**:
   - Wait and retry
   - Check Copilot usage limits

2. **Invalid prompt**:
   - Review issue description
   - Ensure description is clear and detailed
   - Check for special characters that might break parsing

3. **Model not available**:
   - Verify `MODEL` value in workflow
   - Try different model (e.g., change from `claude-haiku-4.5` to `gpt-4`)

4. **Timeout**:
   - Increase timeout for Copilot step (currently defaults to 6 hours)
   - Simplify issue description

### 7. Commit Fails

**Symptom**: Step "💾 Commit Changes" fails.

**Error Messages**:
```
nothing to commit, working tree clean
```

**Solutions**:

1. **No changes made**:
   - Copilot might not have generated any code
   - Review Copilot logs to see what happened
   - Check if issue description was clear enough

2. **Files not added**:
   - Verify `prepare-commit.sh` script logic
   - Check if files were excluded by `.gitignore`

3. **Git configuration**:
   - Verify git user.name and user.email are set
   - Check in workflow step "Create Feature Branch"

### 8. Push Branch Fails

**Symptom**: Step "🚀 Push Branch" fails.

**Error Messages**:
```
fatal: Authentication failed
fatal: could not read Username
```

**Solutions**:

1. **Token authentication**:
   - Verify `GH_TOKEN` is set correctly
   - Check remote URL configuration in `push-branch.sh`

2. **Protected branch**:
   - Ensure branch name doesn't match protection rules
   - Feature branches should be `copilot/*` pattern

3. **Repository permissions**:
   - Verify token has push access
   - Check repository settings

### 9. PR Creation Fails

**Symptom**: Step "📬 Create Pull Request" fails.

**Error Messages**:
```
Error: Pull request already exists
Error: Base branch does not exist
```

**Solutions**:

1. **PR already exists**:
   - Check if PR was created in previous run
   - Update existing PR instead of creating new one

2. **Base branch missing**:
   - Verify `main` branch exists
   - Change `--base` parameter to correct branch name

3. **GitHub CLI not found**:
   - Verify `gh` CLI is installed (should be pre-installed on GitHub runners)
   - Check workflow logs for CLI installation

### 10. Labels Not Updating

**Symptom**: Issue labels don't update during workflow.

**Solutions**:

1. **Permissions**:
   - Verify `issues: write` permission in workflow
   - Check `GH_TOKEN` has issue permissions

2. **Label doesn't exist**:
   - Create labels manually:
     - `copilot-generate`
     - `in-progress`
     - `completed`
     - `ready-for-review`
     - `copilot-generated`

3. **GitHub CLI issues**:
   - Test `gh` CLI authentication:
     ```bash
     gh auth status
     ```

## 🔍 Debugging Steps

### 1. Enable Debug Logging

Add debug logging to workflow:

```yaml
env:
  ACTIONS_STEP_DEBUG: true
  ACTIONS_RUNNER_DEBUG: true
```

### 2. Review Workflow Logs

1. Go to Actions tab
2. Select failed workflow run
3. Expand each step to see detailed logs
4. Look for error messages and stack traces

### 3. Download Copilot Logs

1. Go to failed workflow run
2. Scroll to Artifacts section
3. Download `copilot-logs` artifact
4. Review logs for Copilot execution details

### 4. Test Scripts Locally

Test scripts on your local machine:

```bash
# Test prepare-commit.sh
./scripts/prepare-commit.sh 123 "Test Issue" "testuser"

# Test push-branch.sh
export GH_TOKEN="your-token"
./scripts/push-branch.sh "copilot/123"

# Test update-issue-labels.sh
export GH_TOKEN="your-token"
./scripts/update-issue-labels.sh 123 "add" "in-progress"

# Test post-workflow-comment.sh
export GH_TOKEN="your-token"
./scripts/post-workflow-comment.sh 123 "https://github.com/user/repo/pull/1"
```

### 5. Verify Repository Configuration

```bash
# Check repository secrets
gh secret list

# Check workflow files
gh workflow list

# Check workflow runs
gh run list --workflow=copilot-coder.yml
```

## 📊 Performance Issues

### Slow Workflow Execution

**Symptom**: Workflow takes longer than expected (>10 minutes).

**Solutions**:

1. **Cache not working**:
   - Verify cache key in workflow
   - Check cache hit rate in logs
   - Clear cache and rebuild

2. **Network latency**:
   - Use self-hosted runners closer to your location
   - Consider mirroring npm/pip packages locally

3. **Copilot slow response**:
   - Try different model
   - Simplify issue description
   - Break large tasks into smaller issues

### High Resource Usage

**Symptom**: Workflow uses too much memory/CPU.

**Solutions**:

1. **Use self-hosted runners** with more resources
2. **Optimize MCP servers**: Remove unused servers from config
3. **Reduce logging**: Set `--log-level` to `error` instead of `all`

## 🆘 Getting Help

### Before Asking for Help

1. ✅ Check this troubleshooting guide
2. ✅ Review workflow logs
3. ✅ Download and review Copilot logs
4. ✅ Test scripts locally
5. ✅ Search existing issues

### Creating a Support Issue

Include the following information:

- **Workflow run URL**
- **Error message** (exact text)
- **Steps to reproduce**
- **Workflow logs** (relevant sections)
- **Copilot logs** (if available)
- **Environment details**:
  - GHES version
  - Runner type (hosted/self-hosted)
  - Copilot CLI version

### Useful Commands for Diagnostics

```bash
# Check GitHub CLI version
gh --version

# Check Node.js version
node --version

# Check npm version
npm --version

# Check Python version
python --version

# Check git version
git --version

# Test Copilot CLI
copilot --version

# Test GitHub API access
gh api user

# List workflow runs
gh run list --workflow=copilot-coder.yml --limit 10

# View specific workflow run
gh run view <run-id> --log

# List repository secrets (names only)
gh secret list
```

## 📚 Additional Resources

- [GitHub Actions Debugging](https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows)
- [GitHub CLI Documentation](https://cli.github.com/manual/)
- [GitHub Copilot CLI](https://github.com/github/copilot-cli)
- [GHES Documentation](https://docs.github.com/en/enterprise-server)

## 💡 Tips

- **Start simple**: Test with a simple "Hello World" issue first
- **Use caching**: Properly configured caching reduces execution time by 50%
- **Monitor logs**: Regularly review logs to catch issues early
- **Keep updated**: Update Copilot CLI version regularly
- **Document issues**: Keep track of issues and solutions for your team
