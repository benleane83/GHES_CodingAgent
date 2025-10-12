# GitHub Copilot Instructions for Azure Pipeline

## 🎯 Your Role

You are being called from an Azure DevOps Pipeline that handles the workflow automatically.

**What the Pipeline Does FOR YOU**:
- ✅ Creates the feature branch (`copilot/<work-item-id>`)
- ✅ Commits your changes with co-author attribution
- ✅ Pushes the branch to Azure DevOps
- ✅ Creates the Pull Request with required reviewer

## ✅ YOUR MANDATORY CHECKLIST

You will receive a work item description in your prompt. You MUST complete ALL of these steps:

1. **[ ] Read and understand** the work item description
2. **[ ] Implement the code changes** according to the requirements
3. **[ ] Create `copilot-summary.md`** - Pull Request description file (MANDATORY)
4. **[ ] Create `commit-message.md`** - Commit message file (MANDATORY)

**⚠️ THE PIPELINE WILL FAIL IF FILES 3 AND 4 ARE NOT CREATED!**

---

## 🚨 Important: Requested Version Compliance

If the work item description requests a specific version of any tool, framework, runtime, or SDK (for example, ".NET 9", "Node.js 20", "Python 3.12", etc.), **you must ensure that the implementation uses exactly the requested version**. Do not use an earlier or later version (e.g., do not use .NET 8 if .NET 9 is requested). If the exact version is not available, you must clearly state this in the summary and suggest the closest available alternative, but never assume or substitute a different version without explicit mention.

## 🌐 Language of Output

The implementation summary (`copilot-summary.md`) must be written in the same language as the work item description and requirements provided by the user. The commit message (`commit-message.md`) must always be written in English, regardless of the language of the requirements or summary.

---

## 📋 Detailed Instructions

You will receive the work item description in your prompt. Your responsibilities are:

### 1. Implement the Requirements
- Read and understand the description provided in the prompt
- Implement the requested changes following **best practices**
- Write clean, maintainable, and well-documented code
- Be **concise** and focused on the requirements
- **IMPORTANT**: You are already on the `copilot/<work-item-id>` branch - just write the code
- **DO NOT commit** - the pipeline will do it for you
- **DO NOT push** - the pipeline will do it for you

### 2. Generate Implementation Summary

**CRITICAL - MANDATORY**: After implementing the changes, you MUST create TWO files in the repository root. The pipeline will fail if these files are missing.

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

**The pipeline will fail without these files!**
