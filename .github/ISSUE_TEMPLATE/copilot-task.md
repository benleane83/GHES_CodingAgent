---
name: 🤖 Copilot Task
about: Create a task for GitHub Copilot CLI to implement
title: '[COPILOT] '
labels: 'copilot-task'
assignees: ''
---

## 📋 Task Description

<!-- Provide a clear and concise description of what needs to be implemented -->

## 🎯 Acceptance Criteria

<!-- List the acceptance criteria for this task -->

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## 📚 Technical Details

<!-- Provide technical details, requirements, or constraints -->

### Technology Stack
<!-- List the technologies, frameworks, or libraries to use -->

### Requirements
<!-- List specific requirements or constraints -->

## 🔗 References

<!-- Add any relevant links, documentation, or examples -->

- [Documentation](https://example.com)
- [Example](https://example.com)

## 📝 Additional Context

<!-- Add any other context, screenshots, or information about the task -->

---

## 🚀 How to Trigger Implementation

Once this issue is ready for implementation:

1. Review the description and ensure all details are clear
2. Add the `copilot-generate` label to this issue
3. The GitHub Copilot Coder workflow will automatically:
   - Create a feature branch `copilot/{issue-number}`
   - Implement the changes using GitHub Copilot CLI
   - Create a Pull Request with the implementation
   - Link the PR back to this issue

## 📦 What to Expect

The workflow will:
- ✅ Update issue labels to track progress (`in-progress`, `completed`, `ready-for-review`)
- ✅ Create a feature branch
- ✅ Generate code based on the description
- ✅ Commit changes with proper attribution
- ✅ Create a Pull Request
- ✅ Post a completion comment with PR link
- ✅ Publish execution logs as artifacts
