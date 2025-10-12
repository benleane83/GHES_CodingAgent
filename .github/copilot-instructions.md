# GitHub Copilot Instructions for Azure Pipeline

## 🎯 Your Role

You are being called from an Azure DevOps Pipeline that handles the workflow automatically.

**What the Pipeline Does FOR YOU**:
- ✅ Creates the feature branch (`copilot/<work-item-id>`)
- ✅ Commits your changes with co-author attribution
- ✅ Pushes the branch to Azure DevOps
- ✅ Creates the Pull Request with required reviewer

## 📋 Your Task

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

**CRITICAL**: You MUST create a summary file at `copilot-summary.md`

This file will be used as the Pull Request description.

**Required format**:

```markdown
## ✨ Cambios Implementados

### 📝 Resumen
[Brief description of what was implemented - 2-3 sentences]

### 📁 Archivos Modificados
- `path/to/file1.ext` - [What changed in this file]
- `path/to/file2.ext` - [What changed in this file]

### 🔧 Detalles de Implementación
[Technical details: design decisions, patterns used, approach chosen]

### 🧪 Cómo Probar
1. [Step to test the implementation]
2. [Step to verify functionality]

### ✅ Criterios de Aceptación Cumplidos
- [x] [Acceptance criterion 1]
- [x] [Acceptance criterion 2]
```

**Command to create the summary file**:
```bash
cat > /tmp/copilot-summary.md << 'EOF'
## ✨ Cambios Implementados

### 📝 Resumen
[Your summary here...]

### 📁 Archivos Modificados
- `file1.ext` - Description

### 🔧 Detalles de Implementación
[Your details here...]

### 🧪 Cómo Probar
1. Step 1
2. Step 2

### ✅ Criterios de Aceptación Cumplidos
- [x] Criterion 1
EOF
```
