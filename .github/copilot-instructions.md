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

**CRITICAL - READ THIS FIRST**: The Azure DevOps organization name is ALWAYS available in the environment variable `System_CollectionUri` when running in Azure Pipelines.

**IMPORTANT**: Before making ANY requests to Azure DevOps:

1. **FIRST STEP - Get organization name from System.CollectionUri**:
   - **PRIMARY SOURCE**: Check the environment variable `System_CollectionUri` or `System.CollectionUri`
   - This variable contains the full URL: `https://dev.azure.com/YourOrgName/`
   - **Extract the organization name**: It's the part between `dev.azure.com/` and the next `/`
   - **Example**: If `System_CollectionUri=https://dev.azure.com/MyCompany/` then organization = `MyCompany`
   - **IMPORTANT**: You can access this via the shell environment variable `System_CollectionUri`

2. **Alternative sources** (only if System_CollectionUri is not available):
   - Environment variable: `AZURE_DEVOPS_ORG` or `AZURE_DEVOPS_ORGANIZATION`
   - User's explicit mention in the conversation
   - Previous conversation context

3. **NEVER, EVER do this**:
   - ❌ Do NOT guess organization names
   - ❌ Do NOT try random organization names
   - ❌ Do NOT use placeholder names like "fabrikam", "contoso", etc.
   - ❌ Do NOT assume any organization name without verifying

4. **If you cannot find the organization name**:
   - First, try: `echo $System_CollectionUri` in the terminal
   - If still not found, STOP and ask: "I need to confirm your Azure DevOps organization name. What is it?"
   - Do NOT proceed with API calls until you have the correct organization name

5. **Validate before every Azure DevOps operation**:
   - Before reading work items
   - Before creating work items
   - Before updating work items
   - Before creating branches or pull requests
   - Before any Azure DevOps API call
   - **ALWAYS verify**: Do I have the correct organization name from `System_CollectionUri`?

6. **When you identify the organization name**:
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

3. **Add Initial Comment - DO THIS FIRST**:
   - **CRITICAL**: This is the FIRST action before any implementation work
   - Add a comment to the work item discussion with these two emojis: 👀🤖
   - This signals that Copilot has started working on the task
   - **Important**: Use HTML format for comments, not Markdown
   - Azure DevOps work item comments use HTML editor
   - Example: Use `<b>bold</b>` instead of `**bold**`, `<br>` instead of line breaks, etc.
   - **MANDATORY**: Use the Azure DevOps REST API to add comments
   - **REST API Details**:
     - Endpoint: `POST https://dev.azure.com/{organization}/{project}/_apis/wit/workItems/{workItemId}/comments?api-version=7.0-preview.3`
     - Headers: 
       - `Content-Type: application/json`
       - `Authorization: Bearer {PAT}` (use the `AZURE_DEVOPS_PAT` environment variable)
     - Request Body: `{ "text": "your comment text in HTML format" }`
     - Example request:
       ```bash
       curl -X POST \
         "https://dev.azure.com/{organization}/{project}/_apis/wit/workItems/{workItemId}/comments?api-version=7.0-preview.3" \
         -H "Content-Type: application/json" \
         -H "Authorization: Basic {Base64EncodedPAT}" \
         -d '{"text": "👀🤖 Started working on this task"}'
       ```

4. **Create a New Branch**:
   - Create a new branch with the naming convention: `copilot/<work-item-id>`
   - Example: `copilot/372` for work item #372
   - Switch to this new branch before making any changes

5. **Update Work Item State**:
   - Update the work item state to "Doing"
   - This indicates that work has started on the task

6. **Assign Work Item**:
   - Assign the work item to the user "GitHub Copilot CLI"
   - This shows who is working on the task

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
   - **MANDATORY**: Use the provided script to add the required reviewer
   - **Script to use**: `./scripts/add-required-reviewer.sh`
   - **Script usage**:
     ```bash
     ./scripts/add-required-reviewer.sh <organization> <project> <repository-id> <pr-id> <reviewer-email>
     ```
   - **Parameters to extract**:
     - `organization`: From `System.CollectionUri` environment variable
     - `project`: From the work item's `System.TeamProject` field
     - `repository-id`: From the repository information
     - `pr-id`: The Pull Request ID number you just created
     - `reviewer-email`: From the work item's `System.CreatedBy` field (extract the email/uniqueName)
   - **Example**:
     ```bash
     ./scripts/add-required-reviewer.sh returngisorg "My Project" abc-123-def 42 user@example.com
     ```
   - **DO NOT**: Try to call the Azure DevOps REST API directly for adding reviewers
   - **DO**: Use this script which handles all the complexity including:
     - Finding the correct Identity ID from the email
     - URL-encoding the project name
     - Making the PUT request with correct format
     - Verifying the reviewer was added as required
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
   - **CRITICAL - Verify PR Creation**:
     - After creating the PR, **VERIFY** that it was created successfully
     - Check that the PR exists in Azure DevOps
     - Confirm the following requirements were met:
       - ✅ PR is in **Draft** mode
       - ✅ PR is assigned to the work item creator
       - ✅ Work item creator is added as a **Required Reviewer** (NOT just a reviewer, must be REQUIRED)
       - ✅ Tag "copilot" is present
       - ✅ PR is linked to the work item
     - **MANDATORY verification of Required Reviewer**:
       - Query the PR to get the list of reviewers
       - Verify that the work item creator appears in the reviewers list
       - Verify that the `isRequired` property is set to `true` for that reviewer
       - If the reviewer is not required, use the REST API to update it immediately
     - If ANY of these requirements are not met, fix them immediately
     - Report the PR URL and status to the user

10. **Update Work Item Activity Field**:
   - Set the work item's "Activity" field based on what was requested in the work item
   - Common Activity values: `Development`, `Testing`, `Design`, `Documentation`, `Deployment`, `Requirements`, etc.
   - Choose the most appropriate value based on the work item description and implementation
   - **Activity field options**:
     - `Deployment` - For deployment-related tasks, CI/CD, infrastructure
     - `Design` - For architectural design, UI/UX design work
     - `Development` - For coding, implementation, feature development (most common)
     - `Documentation` - For writing docs, README updates, code comments
     - `Requirements` - For gathering or defining requirements
     - `Testing` - For writing tests, QA work, test automation

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
     - **Use the same REST API method** described in step 6 to add comments
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