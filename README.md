# 🤖 GitHub Copilot Coder for GHES

> **Automated code generation powered by GitHub Copilot CLI on GitHub Enterprise Server**

[![GitHub Actions](https://img.shields.io/badge/GitHub-Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)](https://github.com/features/actions)
[![GitHub Copilot](https://img.shields.io/badge/GitHub-Copilot-000000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/features/copilot)
[![GHES](https://img.shields.io/badge/GHES-Compatible-success?style=for-the-badge&logo=github&logoColor=white)](https://docs.github.com/en/enterprise-server)

---

## 📋 Overview

This repository implements an automated coding workflow using **GitHub Copilot CLI** integrated with **GitHub Enterprise Server (GHES)**. Simply create an issue, add a label, and watch as Copilot generates the code, creates a PR, and links everything together automatically.

### ✨ Key Features

#### 🤖 Copilot Coder
- 🏷️ **Label-driven workflow** - Trigger code generation by adding the `copilot` label
- 🤖 **AI-powered coding** - GitHub Copilot CLI generates code based on issue descriptions
- 🌿 **Automatic branching** - Creates feature branches (`copilot/{issue-number}`)
- 📬 **Auto PR creation** - Opens pull requests with generated code
- 🔗 **Native linking** - Automatically links PRs to issues
- 📊 **Progress tracking** - Updates issue labels to track workflow state
- 📦 **Artifact logging** - Captures and stores execution logs
- 🔄 **MCP integration** - Uses Context7 for documentation and best practices

#### 🔍 Copilot PR Reviewer
- 💬 **Automatic PR reviews** - Reviews code on every PR open/update
- 🔒 **Security analysis** - Detects security vulnerabilities
- ⚡ **Performance checks** - Identifies performance issues
- 🧹 **Code quality** - Flags code quality concerns
- 📝 **Detailed feedback** - Posts actionable comments with examples
- 📊 **Artifact logs** - Complete analysis available for reference

## 🚀 Quick Start

### 1️⃣ Setup (One Time)

1. **Configure Repository Secrets**
   
   Go to **Settings** → **Secrets and variables** → **Actions**:
   
   - `GH_TOKEN` - Fine-grained GitHub PAT with the permissions listed below
   - `CONTEXT7_API_KEY` - (Optional) Context7 API key for documentation

   **Required GH_TOKEN Permissions (Fine-Grained PAT):**
   - **Repository Permissions:**
     - `contents: read & write` - For pushing code to branches
     - `issues: read & write` - For editing issue labels and adding comments
     - `pull_requests: read & write` - For creating pull requests and managing PRs
   
   Note: If using a classic PAT instead, ensure it has `repo` scope with full access.

2. **Create Required Labels**
   
   The workflow uses these labels (create them if they don't exist):
   - `copilot` - Triggers the workflow
   - `in-progress` - Workflow is running
   - `completed` - Workflow completed successfully
   - `ready-for-review` - PR is ready for review
   - `copilot-generated` - Applied to generated PRs

### 2️⃣ Create an Issue

Create a standard issue with:

```markdown
## 📋 Task Description
Create a Python FastAPI application with a simple health check endpoint.

## 🎯 Acceptance Criteria
- [ ] FastAPI app with /health endpoint
- [ ] Returns JSON with status and timestamp
- [ ] Includes proper documentation
- [ ] Add requirements.txt

## 📚 Technical Details
- Use FastAPI latest version
- Python 3.11+
- Follow REST API best practices
```

### 3️⃣ Trigger the Workflow

Add the **`copilot`** label to the issue.

### 4️⃣ Watch the Magic ✨

The workflow will automatically:

1. 🏷️ Update issue labels → `in-progress`
2. 🌿 Create branch → `copilot/{issue-number}`
3. 🤖 Generate code using Copilot CLI
4. 💾 Commit changes with co-author attribution
5. 🚀 Push branch to repository
6. 📬 Create Pull Request
7. 💬 Comment on issue with PR link
8. 🏷️ Update labels → `completed`, `ready-for-review`

### 5️⃣ Review and Merge

1. Review the Pull Request
2. **Copilot Reviewer automatically analyzes the code** ✨
3. Test the implementation
4. Approve and merge when ready

## 🤖 Copilot PR Reviewer (Automatic)

The **Copilot PR Reviewer** automatically analyzes every pull request:

- 🔄 **Triggers on every PR** - Open or update
- 🔍 **Analyzes all changed files** - Security, performance, code quality
- 💬 **Posts review comments** - With actionable recommendations
- 📊 **Generates analysis report** - Available as artifact

### Review Process

```
PR Opened/Updated
         ↓
Reviewer Workflow Triggers (Automatic)
         ↓
1️⃣ Download Changed Files
2️⃣ Run Copilot Analysis
3️⃣ Post Review Comments
         ↓
� Feedback Ready for Developer
```

### Example Review Output

Copilot identifies and comments on issues like:

- 🔒 **Security**: SQL injection, exposed secrets, unsafe deserialization
- ⚡ **Performance**: Inefficient loops, unnecessary allocations, N+1 queries
- 🧹 **Code Quality**: Naming, documentation, complexity, error handling
- 📝 **Best Practices**: Type safety, error handling, edge cases

**No action required!** The reviewer workflow runs automatically on every PR. Just merge your code after addressing the findings.

For detailed information, see [Copilot PR Reviewer Documentation](docs/COPILOT-REVIEWER.md).

## �🎯 How It Works

### Coder Workflow Trigger

```yaml
on:
  issues:
    types: [opened, labeled]
```

The coder workflow triggers when:
- An issue is opened with the `copilot` label
- The `copilot` label is added to an existing issue

### Reviewer Workflow Trigger

```yaml
on:
  pull_request:
    types: [opened, synchronize]
```

The reviewer workflow triggers when:
- A pull request is opened
- A pull request is updated (new commits)

### Architecture

```
GitHub Issue Created
       ↓
Add 'copilot' Label
       ↓
Workflow Triggers
       ↓
Update Labels (in-progress)
       ↓
Setup Environment
(Python, Node.js, Copilot CLI)
       ↓
Configure MCP Servers
       ↓
Create Feature Branch
       ↓
Run Copilot CLI
(Generate Code)
       ↓
Commit Changes
       ↓
Push Branch
       ↓
Create Pull Request
       ↓
Comment on Issue
       ↓
Update Labels (completed, ready-for-review)
       ↓
✅ Done!
```

## 📦 Repository Structure

```
.github/
├── workflows/
│   ├── copilot-coder.yml         # Code generation workflow
│   └── copilot-reviewer.yml      # PR review workflow (NEW!)
└── copilot-instructions.md       # Instructions for Copilot CLI

scripts/
├── prepare-commit.sh             # Prepare commit with co-author
├── push-branch.sh                # Push branch to remote
├── post-workflow-comment.sh      # Post completion comment
├── get-pr-diff.sh                # Get PR file changes (reviewer)
├── download-pr-files.sh          # Download changed files (reviewer)
├── analyze-with-copilot.sh       # Run AI analysis (reviewer)
└── post-pr-comment.sh            # Post review comments (reviewer)

docs/
├── GHES-SETUP.md                # Detailed setup guide
├── GHES-COMPATIBILITY.md        # GHES compatibility info
├── COPILOT-REVIEWER.md          # PR Reviewer documentation (NEW!)
├── REVIEWER-MIGRATION.md        # ADO to GHES adaptation guide (NEW!)
├── MIGRATION-GUIDE.md           # Migration from ADO guide
└── TROUBLESHOOTING.md           # Common issues and solutions

mcp-config.json                  # MCP servers configuration
```

## 🛠️ Technologies Used

- **GitHub Actions** - Workflow orchestration
- **GitHub Copilot CLI** - AI-powered code generation
- **GitHub Issues** - Task management
- **Bash Scripts** - Automation
- **Node.js 22.x** - Runtime for Copilot CLI
- **Python 3.x** - Tooling and MCP server runtime
- **uv** - Python package manager for installing MCP servers
- **MCP Servers** - Context providers:
  - **Context7** (npx) - Documentation and examples
  - **Fetch** (uvx) - Web content retrieval
  - **Time** (uvx) - Time-based operations

## ⚙️ Configuration

### Workflow Variables

Edit `.github/workflows/copilot-coder.yml` to customize:

```yaml
env:
  MODEL: claude-haiku-4.5          # LLM model to use
  COPILOT_VERSION: 0.0.352         # Copilot CLI version
```

## 🌐 Network Requirements

For the workflow to run successfully, GHES runners must have outbound internet access to:

| Service | Host | Port | Protocol | Purpose |
|---------|------|------|----------|---------|
| **GHES API** | `<your-ghes-host>` | 443 | HTTPS | GitHub CLI and API calls |
| **Copilot CLI** | `registry.npmjs.org` | 443 | HTTPS | Download @github/copilot package |
| **MCP Servers** | `pypi.org` | 443 | HTTPS | Install MCP servers via uv |
| **Documentation** | `api.context7.com` | 443 | HTTPS | Context7 MCP service |

### Firewall Configuration

If your GHES runners are behind a firewall, ensure these outbound rules are configured:

```bash
# Allow outbound HTTPS to required services
Allow: registry.npmjs.org:443
Allow: pypi.org:443  
Allow: api.context7.com:443
Allow: <your-ghes-host>:443
```

### Behind Corporate Proxy

If GHES runners access the internet through a corporate proxy, configure:

```yaml
# In workflow or runner configuration
HTTP_PROXY: http://proxy.company.com:8080
HTTPS_PROXY: http://proxy.company.com:8080
NO_PROXY: <your-ghes-host>
```

For detailed network configuration and troubleshooting, see **[GHES Compatibility Guide](docs/GHES-COMPATIBILITY.md#-required-networkfirewall-paths)**.

---

### MCP Servers

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
    },
    "time": {
      "type": "local",
      "command": "uvx",
      "tools": ["*"],
      "args": ["mcp-server-time"]
    }
  }
}
```

**Note**: MCP servers using `uvx` are installed on-demand via the `uv` Python package manager from PyPI.

### Copilot Instructions

Edit `.github/copilot-instructions.md` to customize Copilot's behavior:

- Add project-specific guidelines
- Define code style preferences
- Specify frameworks or libraries to use
- Add security or compliance requirements

## 📊 Workflow Execution

### Typical Execution Time

- ⏱️ **Setup** (1-2 minutes): Install dependencies (cached after first run)
- 🤖 **Code Generation** (2-5 minutes): Copilot generates code
- 📬 **PR Creation** (<1 minute): Create and link PR

**Total**: ~3-8 minutes depending on task complexity

### Logs and Artifacts

Each workflow run publishes:

- 📝 **Workflow logs** - Available in Actions tab
- 📦 **Copilot logs** - Downloaded as artifacts (retention: 30 days)

Access artifacts:
1. Go to Actions tab
2. Select workflow run
3. Scroll to Artifacts section
4. Download `copilot-logs`

## 🎯 Use Cases

### ✅ Perfect For

- Creating new features from scratch
- Implementing API endpoints
- Writing utility functions
- Setting up new projects
- Creating boilerplate code
- Implementing well-defined algorithms
- Converting specifications to code

### ⚠️ Consider Manual Review For

- Complex architectural changes
- Security-critical code
- Performance-sensitive code
- Legacy code refactoring
- Cross-cutting concerns

## 🔒 Security

### Token Security

- ✅ **Never commit tokens** to repository
- ✅ Use **GitHub Secrets** for all sensitive data
- ✅ Rotate tokens regularly
- ✅ Use minimum required permissions

### Workflow Permissions

```yaml
permissions:
  contents: write        # Create branches and commits
  issues: write          # Update issue labels and comments
  pull-requests: write   # Create pull requests
```

### Code Review

- 🔍 **Always review** generated code before merging
- 🧪 **Test thoroughly** in development environment
- 🛡️ **Run security scans** on generated code
- 📖 **Verify documentation** is accurate

## 📚 Documentation

Detailed guides are available in the `docs/` directory:

Detailed guides are available in the `docs/` directory:

- **[GHES Setup Guide](docs/GHES-SETUP.md)** - Complete setup instructions
- **[Copilot PR Reviewer Guide](docs/COPILOT-REVIEWER.md)** - Automated PR review
- **[Migration Guide](docs/MIGRATION-GUIDE.md)** - Migrate from Azure DevOps
- **[Reviewer Migration Guide](docs/REVIEWER-MIGRATION.md)** - ADO Reviewer adaptation details
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions

## 🆘 Troubleshooting

### Workflow Not Triggering

- ✅ Verify label is exactly `copilot` (case-sensitive)
- ✅ Check workflow file syntax
- ✅ Ensure workflow is enabled in Actions tab

### Authentication Errors

- ✅ Verify `GH_TOKEN` is set in repository secrets
- ✅ Check token scopes (`repo`, `copilot_requests`)
- ✅ Ensure token is from GHES, not GitHub.com

### Copilot Errors

- ✅ Check issue description is clear and detailed
- ✅ Verify `MODEL` setting in workflow
- ✅ Review Copilot logs in artifacts

For more troubleshooting help, see **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)**.

## 📈 Monitoring

### Workflow Success Rate

Monitor workflow runs in the Actions tab:

```bash
# List recent workflow runs
gh run list --workflow=copilot-coder.yml --limit 10

# View specific run
gh run view <run-id> --log
```

### Performance Metrics

Track these metrics for your workflow:

- ⏱️ Average execution time
- ✅ Success rate
- 📊 Cache hit rate
- 🔄 Retry rate

## 🤝 Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is provided as-is for educational and reference purposes.

## 🙏 Acknowledgments

- **GitHub Copilot team** - For the amazing Copilot CLI
- **MCP community** - For the Model Context Protocol
- **Context7** - For documentation services
- **Original ADO implementation** - By [0GiS0](https://github.com/0GiS0)

## 📞 Support

- 📖 **Documentation**: Check `docs/` directory
- 🐛 **Issues**: Create an issue in this repository
- 💬 **Discussions**: Use GitHub Discussions
- 📧 **Contact**: See repository maintainers

---

<div align="center">

**Made with ❤️ and 🤖 by GitHub Copilot**

</div>
