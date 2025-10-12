## Using Context7 for Up-to-Date Documentation

When implementing features or working with libraries, frameworks, or APIs:

- **Always use Context7 (Upstash MCP Server)** to get the most up-to-date documentation and code examples
- Before writing code for a specific library or framework, query Context7 for:
  - Latest API documentation
  - Current best practices
  - Working code examples
  - Recent changes or deprecations
- This ensures you're using the most current patterns and avoiding deprecated methods

## Azure DevOps Organization Context

**IMPORTANT**: Before making ANY requests to Azure DevOps:

1. **Always check the user's context** for Azure DevOps organization information
2. **Look for organization name** in these locations (in order of priority):
   - **Azure Pipelines predefined variables**:
     - `System.CollectionUri` - Full URL like `https://dev.azure.com/YourOrg/`
     - `System.TeamFoundationCollectionUri` - Alternative variable name
     - Extract organization name from these URLs (the part after `dev.azure.com/`)
   - **Environment variables**:
     - `AZURE_DEVOPS_ORG` or `AZURE_DEVOPS_ORGANIZATION`
     - `System_CollectionUri` (when running in Azure Pipelines)
   - MCP server context/configuration
   - Previous conversation context
   - User's explicit mentions

3. **NEVER guess or try random organization names**
   - Do not attempt requests with placeholder organization names
   - Do not try common organization names hoping one will work
   - If the organization name is not available in context, **ASK the user explicitly** before proceeding

4. **Validate before every Azure DevOps operation**:
   - Before reading work items
   - Before creating work items
   - Before updating work items
   - Before creating branches or pull requests
   - Before any Azure DevOps API call

5. **When you identify the organization name**:
   - Store it mentally for the current session
   - Use it consistently for all subsequent Azure DevOps operations
   - The organization name is part of the Azure DevOps URL: `https://dev.azure.com/{organization}`

**How to extract organization from System.CollectionUri**:
- If `System.CollectionUri` = `https://dev.azure.com/MyCompany/`
- Then organization name = `MyCompany`
- Pattern: Extract the value between `dev.azure.com/` and the next `/`

**Example**: If the organization is "MyCompany", all Azure DevOps URLs should use:
- `https://dev.azure.com/MyCompany/...`
- Never `https://dev.azure.com/SomeOtherOrg/...`

**If unsure**: Stop and ask the user: "I need to confirm your Azure DevOps organization name to proceed. What is your organization name?"

## Workflow for Implementing Work Items

When the user asks you to implement or work on a task from Azure DevOps:

1. **Verify Azure DevOps Organization** (FIRST STEP):
   - Confirm you have the correct organization name from context
   - If not available, ask the user explicitly
   - Do NOT proceed with random or guessed organization names

2. **Read the Work Item Details**:
   - Get the full work item details
   - Pay special attention to the description field which contains the requirements
   - Note who created the work item (you'll need this later)

3. **Create a New Branch**:
   - Create a new branch with the naming convention: `copilot/<work-item-id>`
   - Example: `copilot/372` for work item #372
   - Switch to this new branch before making any changes

4. **Update Work Item State**:
   - Update the work item state to "Doing"
   - This indicates that work has started on the task

5. **Assign Work Item**:
   - Assign the work item to the user "GitHub Copilot CLI"
   - This shows who is working on the task

6. **Add Initial Comment**:
   - Add a comment to the work item discussion with these two emojis: 👀🤖
   - This signals that Copilot has started working on the task
   - **Important**: Use HTML format for comments, not Markdown
   - Azure DevOps work item comments use HTML editor
   - Example: Use `<b>bold</b>` instead of `**bold**`, `<br>` instead of line breaks, etc.

7. **Analyze and Plan**:
   - Carefully analyze the work item description
   - Plan your implementation approach
   - Share your analysis and approach with the user before proceeding

8. **Implement the Changes**:
   - Work on the task as described in the work item description
   - Make all necessary code changes in the `copilot/<work-item-id>` branch
   - Ensure code quality and follow best practices
   - **Important**: When making commits, add the work item creator as co-author using the format:
     ```
     Co-authored-by: Name <email@example.com>
     ```
   - Extract the creator's name and email from the work item's `System.CreatedBy` field

9. **Create a Draft Pull Request**:
   - **IMPORTANT**: Create the Pull Request in **Draft** mode (not ready for review)
   - **IMPORTANT**: Assign the PR to the person who created the work item (from `System.CreatedBy` field)
   - **IMPORTANT**: Add the work item creator as a **Required Reviewer** - you cannot complete the PR yourself
   - **IMPORTANT**: Add the tag "copilot" to the PR
   - Analyze the changes and add additional relevant tags based on the work done:
     - Consider tags like: `feature`, `bugfix`, `refactor`, `documentation`, `performance`, `security`, `testing`, etc.
     - Choose tags that best describe the nature of the changes
   - Write a detailed summary of what you implemented, including:
     - 📝 Overview of changes
     - ✨ New features or fixes implemented
     - 🔧 Technical details
     - 🧪 Testing recommendations
     - Use emojis throughout for better readability
   - Link the PR to the work item

10. **Update Work Item Activity Field**:
   - Set the work item's "Activity" field based on what was requested in the work item
   - Common Activity values: `Development`, `Testing`, `Design`, `Documentation`, `Deployment`, `Requirements`, etc.
   - Choose the most appropriate value based on the work item description and implementation

11. **Report Issues (if any)**:
   - If any step in the workflow failed or encountered problems:
     - Clearly document which step(s) failed
     - Explain what went wrong and why
     - Provide error messages or logs if available
     - Suggest possible solutions or next steps
   - **Specific scenarios to report**:
     - If unable to push the branch: Explain the error and likely permission issues
     - If unable to create the PR: Detail the error and suggest permission fixes
     - Add this information to the work item as a comment so the user can see it in Azure DevOps
   - Report this at the end of the execution so the user is aware of any issues

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