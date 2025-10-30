# GitHub Copilot Instructions for GitHub Actions Workflow

## 🎯 Your Role

You are being called from a GitHub Actions workflow that handles the automation for you.

**What the Workflow Does FOR YOU**:
- ✅ Creates the feature branch (`copilot/<issue-number>`)
- ✅ Commits your changes with co-author attribution
- ✅ Pushes the branch to GitHub
- ✅ Creates the Pull Request and links it to the issue

## ✅ YOUR MANDATORY CHECKLIST

You will receive a GitHub issue description in your prompt. You MUST complete ALL of these steps:


1. **[ ] Read and understand** the issue description
2. **[ ] Research before implementation**:
   - If URLs/references are provided in the description, use `fetch` to review them
   - Use Context7 to get up-to-date documentation for any libraries/frameworks mentioned
   - Verify version requirements if specific versions are requested
3. **[ ] Implement the code changes** according to the requirements
4. **[ ] Create `copilot-summary.md`** - Pull Request description file (MANDATORY)
5. **[ ] Create `commit-message.md`** - Commit message file (MANDATORY)


---

## 🚨 CRITICAL: Version Compliance & Reference Links

### Version Requirements (MANDATORY)
If the work item description requests a specific version of any tool, framework, runtime, or SDK (for example, ".NET 9", "Node.js 20", "Python 3.12", "React 18", etc.):

- ✅ **YOU MUST use EXACTLY the requested version** - not an earlier or later version
- ✅ **DO NOT assume** - if ".NET 9" is requested, DO NOT use .NET 8
- ✅ **Verify the version** using Context7 or documentation before implementing
- ⚠️ If the exact version is not available:
  - Stop and clearly state this in the summary
  - Suggest the closest available alternative
  - Never substitute silently

### Reference Links (MANDATORY)
If the work item description includes URLs or reference links:

- ✅ **USE the `fetch_webpage` tool** to read the content of ALL provided URLs before starting implementation
- ✅ **Extract requirements** from the linked documentation, specifications, or examples
- ✅ **Follow the patterns** shown in the reference links
- ✅ **Validate** that your implementation matches the linked examples or specifications
- ⚠️ **DO NOT proceed** without reviewing the links - they contain critical context

## 🌐 Language of Output

The implementation summary (`copilot-summary.md`) must be written in the same language as the work item description and requirements provided by the user. The commit message (`commit-message.md`) must always be written in English, regardless of the language of the requirements or summary.

---

## 📋 Detailed Instructions

You will receive the work item description in your prompt. Your responsibilities are:

### 1. Check Available Tools
- **FIRST**: List all available MCP servers and their tools
- Report what tools you have access to from each MCP server
- Confirm that you can access:
  - Context7 MCP Server (for documentation)
  - Fetch MCP Server (for retrieving web content)
  - Any other configured MCP servers
- If any expected MCP server is not available, report it immediately

### 2. Implement the Requirements
- **FIRST**: Read and understand the description provided in the prompt
- **IF URLs are provided**: Use `fetch_webpage` tool to review ALL reference links before coding
- **IF specific versions mentioned**: Verify version availability using Context7 or documentation
- **USE Context7 MCP Server** to fetch up-to-date documentation, code examples, and best practices for any libraries, frameworks, or technologies mentioned in the issue
  - Context7 provides the latest official documentation and real-world examples
  - Query Context7 before implementing to ensure you're using current APIs and patterns
  - Example: If implementing React components, query Context7 for React documentation first
- **IF creating a new project**: Create an appropriate `.gitignore` file for the programming language or framework
  - Include common patterns to exclude compiled files, dependencies, build outputs, IDE files, etc.
  - Examples: `node_modules/`, `*.pyc`, `bin/`, `obj/`, `.env`, `.DS_Store`, etc.
  - Use standard gitignore templates for the chosen technology stack
- Implement the requested changes following **best practices**
- Write clean, maintainable, and well-documented code
- Be **concise** and focused on the requirements
- **IMPORTANT**: You are already on the `copilot/<issue-number>` branch - just write the code
- **DO NOT commit** - the workflow will do it for you
- **DO NOT push** - the workflow will do it for you

### 3. Generate Implementation Summary

**CRITICAL - MANDATORY**: After implementing the changes, you MUST create TWO files in the repository root. The workflow will fail if these files are missing.

#### A) `copilot-summary.md` - Pull Request Description

**YOU MUST CREATE THIS FILE**. This file will be used as the Pull Request description.

**Required format**:

```markdown
## ✨ Implemented Changes

### 📝 Summary
[Brief description of what was implemented - 2-3 sentences]

### 📁 Modified Files
- `path/to/file1.ext` - [What changed in this file]
- `path/to/file2.ext` - [What changed in this file]

### 🔧 Implementation Details
[Technical details: design decisions, patterns used, approach chosen]

### 🧪 How to Test
1. [Step to test the implementation]
2. [Step to verify functionality]

### ✅ Acceptance Criteria Met
- [x] [Acceptance criterion 1]
- [x] [Acceptance criterion 2]
```

**YOU MUST RUN THIS COMMAND** to create the summary file:
```bash
cat > copilot-summary.md << 'EOF'
## ✨ Implemented Changes

### 📝 Summary
[Your summary here...]

### 📁 Modified Files
- `file1.ext` - Description

### 🔧 Implementation Details
[Your details here...]

### 🧪 How to Test
1. Step 1
2. Step 2

### ✅ Acceptance Criteria Met
- [x] Criterion 1
EOF
```

#### B) `commit-message.md` - Commit Message

**YOU MUST CREATE THIS FILE**. This file will be used as the git commit message.

**Required format** (follow Conventional Commits):

```
<type>: <short description>

<detailed description of changes>

- Changed file1.ext: specific change
- Changed file2.ext: specific change
```

**Types to use**:
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code refactoring
- `docs`: Documentation changes
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**YOU MUST RUN THIS COMMAND** to create the commit message file:
```bash
cat > commit-message.md << 'EOF'
feat: Add new feature

Implemented the requested functionality following best practices.

- Modified file1.ext: added new function
- Updated file2.ext: refactored logic
EOF
```

## ⚠️ FINAL REMINDER

Before you finish, verify that you have created:
1. ✅ `copilot-summary.md` - in the repository root
2. ✅ `commit-message.md` - in the repository root

**The workflow will fail without these files!**
