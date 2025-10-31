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

## 🔐 Step 1: Configure Repository Secrets

Navigate to your repository **Settings** → **Secrets and variables** → **Actions** and add the following secrets:

### Required Secrets

1. **`GH_TOKEN`** (Required)
   - **Description**: GitHub Personal Access Token with repository and Copilot access
   - **Type**: Fine-grained Personal Access Token (recommended) or Classic PAT
   - **Fine-Grained PAT Permissions Required**:
     - **Repository Permissions**:
       - `contents: read & write` - For creating and pushing branches with code changes
       - `issues: read & write` - For updating issue labels and adding completion comments
       - `pull_requests: read & write` - For creating pull requests and managing them
     - **Account Permissions**:
       - None specifically required
   - **Classic PAT Alternative**: Use `repo` scope for full repository access
   - **How to create**:
     1. Go to your GHES instance → Settings → Developer settings → Personal access tokens
     2. Select "Fine-grained tokens" (recommended) or "Tokens (classic)"
     3. Configure permissions as listed above
     4. Copy the token and add it as a repository secret

2. **`CONTEXT7_API_KEY`** (Optional)
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

## 🎯 Step 3: Configure MCP Servers (Optional)

The workflow uses MCP (Model Context Protocol) servers for enhanced functionality.

### Default MCP Configuration

The file `mcp-config.json` in the repository root configures:

1. **Context7**: Documentation and code examples
2. **Fetch**: Web content retrieval
3. **Time**: Time-based operations

### Customizing MCP Servers

Edit `mcp-config.json` to add or remove MCP servers:

```json
{
  "mcpServers": {
    "context7": {
      "type": "local",
      "command": "npx",
      "tools": ["*"],
      "args": ["-y", "@upstash/context7-mcp"]
    },
    "fetch": {
      "type": "local",
      "command": "uvx",
      "tools": ["*"],
      "args": ["mcp-server-fetch"]
    }
  }
}
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
- **`completed`**: Workflow adds when code generation finishes
- **`ready-for-review`**: Workflow adds when PR is created
- **`copilot-generated`**: Applied to PRs created by the workflow

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
8. ⚙️ Configure MCP Servers
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

If using self-hosted runners:

1. Ensure Node.js 22.x is available
2. Ensure Python 3.x is available
3. Configure runner labels in workflow:

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

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.

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
