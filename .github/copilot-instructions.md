## Using MCP Server for Azure DevOps

If the user has configured MCP Server for Azure DevOps in their `~/.config/mcp-config.json` file, use that server to get work items instead of GitHub issues.

Always assume the MCP Server for Azure DevOps is named `azure-devops` in the configuration file. If the user asks something related to Azure DevOps work items, always try to use the MCP Server for Azure DevOps.

**IMPORTANT: Azure DevOps MCP Server is MANDATORY**
- When the user requests ANYTHING related to Azure DevOps (work items, queries, updates, comments, etc.), you MUST use the MCP Server for Azure DevOps.
- DO NOT attempt to use Azure DevOps REST API directly as an alternative.
- If the MCP Server connection fails or returns an error:
  1. Report the error clearly to the user
  2. Explain what went wrong
  3. DO NOT try to solve the problem using REST API calls
  4. Ask the user to verify their MCP Server configuration

## Workflow for Implementing Work Items

When the user asks you to implement or work on a task from Azure DevOps:

1. **Read the Work Item Details**:
   - Use the MCP Server to get the full work item details
   - Pay special attention to the description field which contains the requirements
   - Note who created the work item (you'll need this later)

2. **Create a New Branch**:
   - Create a new branch with the naming convention: `copilot/<work-item-id>`
   - Example: `copilot/372` for work item #372
   - Switch to this new branch before making any changes

3. **Update Work Item State**:
   - Use the MCP Server to update the work item state to "Doing"
   - This indicates that work has started on the task

4. **Add Initial Comment**:
   - Add a comment to the work item discussion with these two emojis: 👀🤖
   - This signals that Copilot has started working on the task

5. **Analyze and Plan**:
   - Carefully analyze the work item description
   - Plan your implementation approach
   - Share your analysis and approach with the user before proceeding

6. **Implement the Changes**:
   - Work on the task as described in the work item description
   - Make all necessary code changes in the `copilot/<work-item-id>` branch
   - Ensure code quality and follow best practices
   - **Important**: When making commits, add the work item creator as co-author using the format:
     ```
     Co-authored-by: Name <email@example.com>
     ```
   - Extract the creator's name and email from the work item's `System.CreatedBy` field

7. **Create a Draft Pull Request**:
   - Once implementation is complete, create a Pull Request in **Draft** mode
   - Write a detailed summary of what you implemented, including:
     - 📝 Overview of changes
     - ✨ New features or fixes implemented
     - 🔧 Technical details
     - 🧪 Testing recommendations
     - Use emojis throughout for better readability
   - Assign the PR to the person who created the work item
   - Link the PR to the work item

**Example PR Description Format**:
```
## 🎯 Summary
Brief overview of what was implemented

## ✨ Changes Made
- 🔧 Feature 1: Description
- 🐛 Bug fix: Description
- 📝 Documentation updates

## 🧪 Testing
How to test the changes

## 📋 Work Item
Closes #<work-item-id>
```


