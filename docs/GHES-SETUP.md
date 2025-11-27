# 🚀 GitHub Enterprise Server (GHES) Setup Guide

This guide explains how to set up the GitHub Copilot Coder workflow on GitHub Enterprise Server.

## 📋 Prerequisites

### Required Software
- GitHub Enterprise Server (GHES) instance
- GitHub Copilot CLI access
- Node.js 22.x (installed automatically by workflow)
- Python 3.x (installed automatically by workflow)

### Required Permissions
- Repository admin access
- Ability to create GitHub Actions workflows
- Ability to configure repository secrets

## 🔐 Step 1: Configure Organization or Repository Secrets

Navigate to your repository **Settings** → **Secrets and variables** → **Actions** and add the following secrets:

### Required Secrets

1. **`GH_TOKEN`** (Required)
   - **Description**: GitHub Personal Access Token for repository operations and GitHub CLI
   - **Type**: ⚠️ **Classic PAT ONLY** - Fine-grained PATs have issues with GraphQL on GHES
   - **Required Scopes**:
     - `repo` - Full control of private repositories
     - `workflow` - Update GitHub Action workflows
   - **How to create**:
     1. Go to `https://<your-ghes-instance>/settings/tokens`
     2. Click **"Generate new token"** → **"Generate new token (classic)"**
     3. Set a descriptive name (e.g., "Copilot Workflows")
     4. Set expiration (recommend 90+ days)
     5. Select scopes: ✅ `repo`, ✅ `workflow`
     6. Click **Generate token**
     7. Copy and add as repository secret

   > ⚠️ **Important**: Do NOT use Fine-grained PATs - they fail with `Resource not accessible by personal access token` errors on GHES GraphQL operations.

2. **`COPILOT_TOKEN`** (Required)
   - **Description**: Token for GitHub Copilot API access
   - **Required for**: Running Copilot CLI commands

3. **`CONTEXT7_API_KEY`** (Optional)
   - **Description**: API key for Context7 MCP server (for documentation access)
   - **Required for**: Enhanced documentation lookup
   - **How to get**: Sign up at [Context7](https://context7.com)

## ⚙️ Step 2: Verify Workflow Configuration

The workflow file is located at `.github/workflows/copilot-coder.yml`.

### Default Configuration

```yaml
env:
  MODEL: claude-haiku-4.5          # LLM model to use
  COPILOT_VERSION: 0.0.352         # Copilot CLI version
```

### Customization Options

You can customize the workflow by editing these environment variables:

- **`MODEL`**: Change the LLM model (e.g., `claude-sonnet-4`, `gpt-4`)
- **`COPILOT_VERSION`**: Pin to a specific Copilot CLI version
- **`NPM_GLOBAL_PATH`**: Customize NPM global package path (auto-detected)

## 🎯 Step 3: Understand MCP Server Configuration

The workflow uses MCP (Model Context Protocol) servers for enhanced functionality like documentation lookup and web content retrieval.

### How MCP Configuration Works

**Important:** MCP configuration is fetched automatically at runtime from the central `GHES_CodingAgent` repository. You do not need to:
- ❌ Edit any local `mcp-config.json` file
- ❌ Deploy MCP configuration to target repositories
- ❌ Manually configure MCP servers

The master workflow automatically downloads the latest `mcp-config.json` from the central repository during execution, ensuring all repositories use consistent, up-to-date MCP settings.

### Default MCP Servers

The centrally managed configuration includes:

1. **Context7**: Documentation and code examples
2. **Fetch**: Web content retrieval
3. **Time**: Time-based operations

### Customizing MCP Servers

To modify MCP configuration for all repositories:

1. Edit `mcp-config.json` in the `GHES_CodingAgent` repository
2. Changes apply automatically to all subsequent workflow runs
```

## 📝 Step 4: Create Issues for Copilot

### Creating an Issue

1. Go to **Issues** → **New Issue**
2. Create a standard issue with your task description
3. Include clear acceptance criteria and technical details (if applicable)
4. Create the issue

### Triggering the Workflow

To trigger code generation:

1. Open the issue you want to implement
2. Add the label **`copilot`**
3. The workflow will automatically start

### Workflow States

The workflow manages issue states using labels:

- **`copilot`**: User adds to trigger workflow (automatically removed when workflow starts)
- **`in-progress`**: Workflow adds when code generation starts
- **`ready-for-review`**: Workflow adds when PR is created

## 🔍 Step 5: Monitor Workflow Execution

### Viewing Workflow Runs

1. Go to **Actions** tab in your repository
2. Select **🤖 GitHub Copilot Coder** workflow
3. Click on the latest run to see details

### Workflow Steps

The workflow executes the following steps:

1. 🚀 Start Workflow
2. 📥 Checkout Repository
3. 🏷️ Update Issue Labels - In Progress
4. 🐍 Setup Python
5. 📦 Install uv/uvx
6. ⚙️ Setup Node.js
7. 📦 Install Copilot CLI (with caching)
8. ⚙️ Configure MCP Servers (fetched from central repo)
9. 🧰 Check MCP Access
10. 🌿 Create Feature Branch
11. 🤖 Implement Changes with Copilot
12. 💾 Commit Changes
13. 🚀 Push Branch
14. 📬 Create Pull Request
15. 💬 Add Completion Comment to Issue
16. 🏷️ Update Issue Labels - Completed
17. 📦 Publish Logs

### Accessing Logs

Workflow logs are published as artifacts:

1. Go to the workflow run
2. Scroll to **Artifacts** section
3. Download **copilot-logs** artifact

## 🧪 Step 6: Test the Setup

Create a simple test issue to verify the setup:

```markdown
## 📋 Task Description
Create a simple "Hello World" Python script.

## 🎯 Acceptance Criteria
- [ ] Create hello.py file
- [ ] Script should print "Hello, World!"
- [ ] Include proper documentation

## 📚 Technical Details
### Technology Stack
- Python 3.x

### Requirements
- Simple, clean code
- Add a main function
```

1. Create this issue
2. Add the `copilot` label
3. Wait for the workflow to complete
4. Review the generated PR

## 🔒 Security Considerations

### Token Security

- **Never commit tokens** to the repository
- Use **GitHub Secrets** for all sensitive data
- Rotate tokens regularly
- Use minimum required permissions

### Workflow Permissions

The workflow requires these permissions (configured in workflow file):

```yaml
permissions:
  contents: write        # Create branches and commits
  issues: write          # Update issue labels and comments
  pull-requests: write   # Create pull requests
```

## 🌐 GHES-Specific Configuration

### Custom GHES Hostname

If your GHES instance uses a custom hostname, ensure:

1. The `GH_TOKEN` is from your GHES instance
2. Git remote URLs point to your GHES instance
3. API calls use your GHES hostname

### Self-Hosted Runners

⚠️ **CRITICAL REQUIREMENT**: If using self-hosted runners, you **MUST** manually install GitHub CLI before running any workflows.

#### Why Manual Installation is Required

Enterprise networks typically:
- Block outbound internet access during workflow execution
- Require proxy configuration for external downloads
- Have slow or restricted access to package repositories (npm, apt)

Automatic installation during workflow runs will fail or timeout in these environments.

#### Required: GitHub CLI (`gh`)

The GitHub CLI must be pre-installed on self-hosted runners. It cannot be installed during workflow execution due to network restrictions in most enterprise environments.

**Installation steps** (run on the runner VM):

```bash
# Download GitHub CLI
GH_VERSION="2.62.0"
cd /tmp
curl -L -o gh.tar.gz "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz"

# Extract and install
tar -xzf gh.tar.gz
sudo mv gh_${GH_VERSION}_linux_amd64/bin/gh /usr/local/bin/
sudo chmod +x /usr/local/bin/gh

# Cleanup
rm -rf gh.tar.gz gh_${GH_VERSION}_linux_amd64

# Verify installation
gh --version
```

**If the runner cannot reach github.com**, download the binary on another machine and transfer it:

```powershell
# On a machine with internet access (PowerShell)
curl -L -o gh.tar.gz "https://github.com/cli/cli/releases/download/v2.62.0/gh_2.62.0_linux_amd64.tar.gz"

# Transfer to runner via SCP
scp gh.tar.gz user@<runner-ip>:/tmp/
```

Then on the runner:
```bash
cd /tmp
tar -xzf gh.tar.gz
sudo mv gh_2.62.0_linux_amd64/bin/gh /usr/local/bin/
sudo chmod +x /usr/local/bin/gh
gh --version
```

#### Other Requirements

- **Node.js 22.x** - Installed automatically by workflow via `actions/setup-node`
- **Python 3.x** - Installed automatically by workflow via `actions/setup-python`

#### Runner Labels

Configure runner labels in the workflow:

```yaml
runs-on: [self-hosted, linux]
```

## 📊 Monitoring and Maintenance

### Workflow Performance

Monitor workflow execution times:

- **Average execution**: 3-5 minutes
- **Cache hit rate**: Should be >80% after first run
- **Success rate**: Should be >90%

### Regular Maintenance

1. **Update Copilot CLI**: Bump `COPILOT_VERSION` when new versions are available
2. **Review logs**: Check for MCP server issues
3. **Update dependencies**: Keep MCP servers updated
4. **Clean up branches**: Delete merged feature branches

## 🆘 Troubleshooting

### Common Issues

#### ❌ GitHub CLI Authentication Failed (HTTP 401)

**Error**: `error validating token: HTTP 401: Bad credentials`

**Cause**: The `GH_TOKEN` secret is either:
1. Created on github.com instead of your GHES instance
2. Expired or invalid
3. Missing required scopes/permissions

**Solution**:

1. **Verify token origin**: The token MUST be created on your GHES instance:
   - ✅ Correct: `https://<your-ghes-instance>/settings/tokens`
   - ❌ Wrong: `https://github.com/settings/tokens`

2. **Test the token manually** on the runner:
   ```bash
   # Replace <your-ghes-host> and <your-token>
   curl -H "Authorization: token <your-token>" \
     https://<your-ghes-host>/api/v3/user
   ```
   
   If this returns 401, the token is invalid for your GHES instance.

3. **Create a new token on GHES** with required permissions:
   - `repo` (full control)
   - `workflow` (update workflows)
   - `read:org` (if using org-level features)

4. **Update the repository secret**:
   - Go to repository Settings → Secrets and variables → Actions
   - Update `GH_TOKEN` with the new GHES token

#### ❌ GitHub CLI Not Found

**Error**: `gh: command not found`

**Solution**: GitHub CLI must be manually installed on self-hosted runners. See [Self-Hosted Runners](#self-hosted-runners) section above.

For more issues, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Copilot CLI](https://github.com/github/copilot-cli)
- [MCP Protocol](https://modelcontextprotocol.io/)
- [GHES Documentation](https://docs.github.com/en/enterprise-server)

## 🤝 Support

For issues or questions:

1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Review workflow logs
3. Create an issue in this repository
