# 🤖 Azure DevOps Coding Agent powered by GitHub Copilot CLI

<div align="center">

[![YouTube Channel Subscribers](https://img.shields.io/youtube/channel/subscribers/UC140iBrEZbOtvxWsJ-Tb0lQ?style=for-the-badge&logo=youtube&logoColor=white&color=red)](https://www.youtube.com/c/GiselaTorres?sub_confirmation=1)
[![GitHub followers](https://img.shields.io/github/followers/0GiS0?style=for-the-badge&logo=github&logoColor=white)](https://github.com/0GiS0)
[![LinkedIn Follow](https://img.shields.io/badge/LinkedIn-Follow-blue?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/giselatorresbuitrago/)
[![X Follow](https://img.shields.io/badge/X-Follow-black?style=for-the-badge&logo=x&logoColor=white)](https://twitter.com/0GiS0)

**📖 Languages:** [🇪🇸 Español](README.md) | 🇬🇧 **English**

</div>

Hi developer 👋🏻! This repository implements a workflow in Azure Pipelines 🚀 that integrates **GitHub Copilot CLI** 🤖 to automatically generate code from Work Items 📋. The code in this repository was used for my video: 🚀 Take Azure DevOps to the next level with GitHub Copilot CLI 🤖


<a href="https://youtu.be/ZS0LQA2_zZQ">
 <img src="https://img.youtube.com/vi/ZS0LQA2_zZQ/maxresdefault.jpg" alt="🚀 Take Azure DevOps to the next level with GitHub Copilot CLI 🤖" width="100%" />
</a>

### 🎯 Objectives

- ✅ Automate code creation using AI (GitHub Copilot)
- ✅ Integrate GitHub Copilot CLI with Azure DevOps
- ✅ Manage automatic workflows from WebHooks
- ✅ Create feature branches, commits and Pull Requests automatically
- ✅ Link changes with Azure DevOps work items

## 🚀 What does it do?

The pipeline is triggered by a **WebHook from Azure DevOps** and performs the following workflow:

1. 📖 **Reads the work item** - Gets the description and requirements
2. 🌿 **Creates a feature branch** - `copilot/<work-item-id>`
3. 🤖 **Runs GitHub Copilot CLI** - Generates code automatically
4. 💾 **Makes a commit** - Saves changes with descriptive messages
5. 🚀 **Pushes the branch** - Uploads changes to the repository
6. 📬 **Creates a Pull Request** - Opens the PR automatically
7. 🔗 **Links everything in Azure DevOps** - Connects the branch, commit and PR with the work item

## 🛠️ Technologies Used

- **Azure DevOps** - Work items and pipelines management
- **GitHub Copilot CLI** - Automatic code generation with AI
- **Bash Scripts** - Automation and orchestration
- **Node.js 22.x** - Runtime for Copilot CLI
- **Python 3.x** - Auxiliary tools
- **MCP Servers** - Context7 for updated documentation

## 📦 Project Structure

```
├── azure-pipelines.yml          # Pipeline definition
├── mcp-config.json              # MCP Servers configuration
├── .github/
│   └── copilot-instructions.md  # Instructions for Copilot
└── scripts/                     # Automation scripts
    ├── clone-target-repo.sh
    ├── create-pr-and-link.sh
    ├── push-branch.sh
    └── ...
```

## ⚙️ Required Configuration

### Environment Variables

- `GH_TOKEN` - GitHub token with Copilot Requests permission
- `AZURE_DEVOPS_PAT` - Azure DevOps Personal Access Token for the user simulating GitHub Copilot CLI
- `CONTEXT7_API_KEY` - API key for Context7 (documentation)
- `COPILOT_VERSION` - Copilot CLI version to install, to prevent the workflow from breaking if something important changes
- `MODEL` - Language model to use (e.g., claude-sonnet-4)

### Azure DevOps WebHook

The pipeline is triggered by a WebHook configured in Azure DevOps that fires when work items are created or updated.

If you want to see how to configure it, you can check my article (in Spanish): [How to run an Azure Pipelines workflow 🚀 when a work item is created](https://www.returngis.net/2025/10/como-ejecutar-un-flujo-de-azure-pipelines-%f0%9f%9a%80-cuando-se-crea-un-work-item/)

## 📝 How the Pipeline Works - Step by Step

The pipeline executes the following steps automatically:

### 🔧 Environment Preparation
1. **🚀 Start Pipeline** - Initiates the workflow
2. **🐍 Setup Python** - Installs Python 3.x
3. **📦 Install uv/uvx** - Fast package manager
4. **⚙️ Setup Node.js 22.x** - Installs Node.js for Copilot CLI
5. **🔍 Detect NPM Path** - Locates the global NPM path
6. **📦 Cache NPM Packages** - Caches global packages to speed up future runs
7. **📦 Install Copilot CLI** - Installs @github/copilot in the specified version

### 📋 Work Item Processing
8. **📋 Parse Webhook Data** - Extracts event information (ID, title, description, etc.)
9. **🛎️ Clone Target Repository** - Clones the target repository where code will be generated
10. **📖 Read Work Item Details** - Gets all work item information from Azure DevOps
11. **🚀 Initialize Work Item** - Changes state to "Development" and prepares the work item

### 🔐 Security and Tools Configuration
12. **⚙️ Configure MCP Servers** - Copies MCP configuration (Context7, etc.) to ~/.config/
13. **🧰 Check MCP Access** - Verifies that all MCP servers are available

### 💻 Code Generation
14. **🌿 Create Feature Branch** - Creates `copilot/<work-item-id>`
15. **🤖 Run GitHub Copilot CLI** - Generates code based on the work item description
    - Copies Copilot instructions to the repository
    - Runs Copilot with the specified model (e.g., claude-sonnet-4)
    - Records all detailed logs

### 📤 Commit and Publishing
16. **💾 Prepare and Commit** - Creates a commit with the generated code
    - Generates `copilot-summary.md` (change description)
    - Generates `commit-message.md` (commit message)
17. **� Push Branch** - Uploads the branch to the remote repository

### 🔗 Integration and Linking
18. **🔗 Link Branch to Work Item** - Links the feature branch with the work item
19. **� Update Work Item Activity** - Marks the activity as "Development"
20. **📬 Create PR and Link** - Creates a Pull Request and links it to the work item

### 🎉 Completion
21. **💬 Add Completion Comment** - Comments on the work item with the PR link
22. **📦 Publish Logs** - Saves all pipeline logs as artifacts

## 🔄 Complete Workflow Diagram

```
Work Item Created/Updated
         ↓
  Setup Environment
  (Python, Node.js, NPM)
         ↓
 Cache NPM Packages
         ↓
Install Copilot CLI
         ↓
 Parse Webhook Data
         ↓
Clone Repository
         ↓
Read Work Item Details
         ↓
Initialize Work Item
         ↓
Configure MCP Servers
         ↓
Check MCP Access
         ↓
Create Branch (copilot/xxx)
         ↓
  Run GitHub Copilot
   (AI Code Generation)
         ↓
  Commit Changes
         ↓
  Push to Remote
         ↓
Link Branch to WI
         ↓
Update Activity (Development)
         ↓
 Create Pull Request
         ↓
Link PR to Work Item
         ↓
Add Completion Comment
         ↓
  Publish Logs
         ↓
✅ Workflow Complete
```

## 🔐 Security Considerations

- **Secrets Management**: Ensure all tokens and sensitive data are stored in Azure DevOps secret variables
- **Access Control**: Limit access to the pipeline to authorized users
- **Code Review**: All generated code should be reviewed before merging
- **Audit Trail**: Monitor all changes and access logs

## 📚 Scripts Overview

### Key Scripts

- **`orchestrate-workitem.sh`** - Manages work item state and workflow
- **`clone-target-repo.sh`** - Clones the repository where code will be generated
- **`create-pr-and-link.sh`** - Creates Pull Request and links it to the work item
- **`prepare-commit.sh`** - Prepares commit with summary and message
- **`push-branch.sh`** - Pushes changes to the remote repository

For more details, check the [scripts README](scripts/README.md)

## 🤝 Contributing

Want to improve this project? You can:
- Report bugs or suggest features 🐛
- Improve automation scripts 📜
- Optimize Copilot configuration 🚀
- Add new features ✨

## 📄 License

This project is provided as-is for educational and automation purposes.

## 🎬 Related Content

- 📺 [YouTube Channel](https://www.youtube.com/c/GiselaTorres)
- 📝 [Blog](https://www.returngis.net)
- 🐦 [Twitter/X](https://twitter.com/0GiS0)
- 💼 [LinkedIn](https://www.linkedin.com/in/giselatorresbuitrago/)

---

**Made with ❤️ by [Gisela Torres](https://github.com/0GiS0)**
