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

**CRITICAL**: This workflow MUST be followed in EXACTLY this order. Do NOT skip steps or change the sequence.

**⚠️ CRITICAL RULES - READ BEFORE STARTING:**
1. **NEVER commit directly to main/master branch** - Always create a `copilot/<work-item-id>` branch
2. **NEVER mark work item as "Done"** - Work items stay in "Doing" state until PR is reviewed and merged
3. **ALWAYS create a Pull Request** - Every implementation MUST go through a PR, even small changes
4. **ALWAYS use the provided scripts** - Do NOT use `az boards` CLI commands or manual REST API calls
5. **ALWAYS push the branch** - The PR must be created from the pushed branch in Azure DevOps
6. **IF A SCRIPT FAILS, STOP AND REPORT** - Do NOT try alternative methods like `az boards` or REST API
7. **NEVER use `az boards` commands** - Even if a script fails, report the error and stop

When the user asks you to implement or work on a task from Azure DevOops:

1. **Verify Azure DevOps Organization** (FIRST STEP):
   - Confirm you have the correct organization name from context
   - If not available, ask the user explicitly
   - Do NOT proceed with random or guessed organization names

2. **Read the Work Item Details**:
   - Get the full work item details
   - **MANDATORY**: Use the provided script to retrieve work item information
   - **Script to use**: `./scripts/get-workitem.sh`
   - **Script usage**:
     ```bash
     # Using environment variables (typical in Azure Pipelines)
     ./scripts/get-workitem.sh <work-item-id>
     
     # Or specifying project explicitly (handles spaces automatically)
     ./scripts/get-workitem.sh <work-item-id> "Project Name"
     ```
   - **Example**:
     ```bash
     ./scripts/get-workitem.sh 412
     # or
     ./scripts/get-workitem.sh 412 "GitHub Copilot CLI"
     ```
   - **What to extract from the output**:
     - Pay special attention to the **Description** field which contains the requirements
     - **MANDATORY**: Note who created the work item (**Created By Email**) - you'll need this for:
       - PR reviewer (required reviewer)
       - Co-authored-by in commits
     - **MANDATORY**: Note the project name (**Project**) - you'll need this for all scripts
     - Note the current **State** and **Activity** values
   - **DO NOT**: Try to call the Azure DevOps REST API directly
   - **DO**: Use this script which handles URL encoding of project names with spaces
   - **IF SCRIPT FAILS**: Report the error and STOP - do NOT use `az boards` as fallback

3. **Add Initial Comment - DO THIS FIRST BEFORE ANY OTHER ACTION**:
   - **CRITICAL**: This is the FIRST action before any implementation work
   - Add a comment to the work item discussion with these two emojis: 👀🤖
   - **MANDATORY**: Use the provided script to add the comment
   - **IMPORTANT - HTML Format**: When adding comments, use HTML format, NOT Markdown
     - Azure DevOps comments display better with HTML
     - Use `<b>` instead of `**` for bold
     - Use `<i>` instead of `*` for italics
     - Use `<br/>` for line breaks
     - Use `<ul><li>` for lists
     - Use `<a href="">` for links
   - **Script to use**: `./scripts/add-comment-to-workitem.sh`
   - **Script usage**:
     ```bash
     ./scripts/add-comment-to-workitem.sh <organization> <project> <work-item-id> "👀🤖 Started working on this task"
     ```
   - **Parameters to extract**:
     - `organization`: From `System.CollectionUri` environment variable
     - `project`: From the work item's `System.TeamProject` field
     - `work-item-id`: The Work Item ID number
   - **Example**:
     ```bash
     ./scripts/add-comment-to-workitem.sh returngisorg "My Project" 372 "👀🤖 Started working on this task"
     ```
   - **DO NOT**: Try to call the Azure DevOps REST API directly for adding comments
   - **DO**: Use this script which handles all the complexity
   - **IF SCRIPT FAILS**: Report the error to the user and STOP - do NOT use `az boards` as fallback

4. **Create a New Branch - MANDATORY BEFORE ANY CODE CHANGES**:
   - **CRITICAL**: You MUST create a new branch BEFORE making ANY code changes
   - **Branch naming convention**: `copilot/<work-item-id>`
   - Example: `copilot/372` for work item 372
   - **MANDATORY**: Switch to this new branch before making any changes
   - **DO NOT**: Make commits directly to the main/master branch
   - Use: `git checkout -b copilot/<work-item-id>`
   - Verify: `git branch --show-current` to confirm you're on the new branch

5. **Update Work Item State**:
   - Update the work item state to "Doing"
   - **MANDATORY**: Use the provided script to update the state
   - **Script to use**: `./scripts/update-workitem-state.sh`
   - **Script usage**:
     ```bash
     ./scripts/update-workitem-state.sh <organization> <project> <work-item-id> "Doing"
     ```
   - **Parameters to extract**:
     - `organization`: From `System.CollectionUri` environment variable
     - `project`: From the work item's `System.TeamProject` field
     - `work-item-id`: The Work Item ID number
   - **Example**:
     ```bash
     ./scripts/update-workitem-state.sh returngisorg "My Project" 372 "Doing"
     ```
   - **DO NOT**: Try to call the Azure DevOps REST API directly
   - **DO**: Use this script which handles the PATCH request properly
   - **IF SCRIPT FAILS**: Report the error to the work item and STOP - do NOT use `az boards` as fallback

6. **Assign Work Item - MANDATORY DO NOT SKIP**:
   - **CRITICAL**: You MUST assign the work item, this step is NOT optional
   - Assign the work item to the user "GitHub Copilot CLI"
   - **MANDATORY**: Use the provided script to assign the work item
   - **Script to use**: `./scripts/assign-workitem.sh`
   - **Script usage**:
     ```bash
     ./scripts/assign-workitem.sh <organization> <project> <work-item-id> "GitHub Copilot CLI"
     ```
   - **Parameters to extract**:
     - `organization`: From `System.CollectionUri` environment variable
     - `project`: From the work item's `System.TeamProject` field
     - `work-item-id`: The Work Item ID number
   - **Example**:
     ```bash
     ./scripts/assign-workitem.sh returngisorg "My Project" 372 "GitHub Copilot CLI"
     ```
   - **DO NOT**: Try to call the Azure DevOps REST API directly
   - **DO**: Use this script which handles the assignment properly
   - **IF SCRIPT FAILS**: Report the error to the work item and STOP - do NOT use `az boards` as fallback

7. **Analyze and Plan**:
   - Carefully analyze the work item description
   - Plan your implementation approach
   - Share your analysis and approach with the user before proceeding

8. **Implement the Changes**:
   - **VERIFY**: Confirm you are on the `copilot/<work-item-id>` branch
   - Run: `git branch --show-current` to verify
   - Work on the task as described in the work item description
   - Make all necessary code changes in the `copilot/<work-item-id>` branch
   - Ensure code quality and follow best practices
   - **CRITICAL - Add Co-Author to Commits**:
     - When making commits, you MUST add the work item creator as co-author
     - Extract the creator's name and email from the work item's `System.CreatedBy` field
     - The `System.CreatedBy` field contains: `{"displayName": "Name", "uniqueName": "email@example.com"}`
     - Add co-author at the END of the commit message with TWO blank lines before it
     - **Format**:
       ```
       Commit title
       
       Commit description line 1
       Commit description line 2
       
       
       Co-authored-by: Display Name <email@example.com>
       ```
     - **Example**:
       ```bash
       git commit -m "feat: Add feature XYZ
       
       - Added feature A
       - Fixed bug B
       - Updated docs
       
       
       Co-authored-by: Daenerys Targaryen <daenerys@thegameofthrones.onmicrosoft.com>"
       ```
   - **DO NOT**: Complete the work item or mark it as "Done" - it stays in "Doing" until PR is merged

9. **Push the Branch to Azure DevOps - MANDATORY**:
   - **CRITICAL**: You MUST push the branch before creating the PR
   - **Method 1 - Using AZURE_DEVOPS_PAT (PREFERRED)**:
     - Check if `AZURE_DEVOPS_PAT` environment variable is available
     - If available, configure git remote with PAT:
       ```bash
       git remote set-url origin "https://build:${AZURE_DEVOPS_PAT}@dev.azure.com/<org>/<project>/_git/<repo>"
       git push -u origin copilot/<work-item-id>
       ```
     - **Example**:
       ```bash
       git remote set-url origin "https://build:${AZURE_DEVOPS_PAT}@dev.azure.com/returngisorg/GitHub%20Copilot%20CLI/_git/GitHub%20Copilot%20CLI"
       git push -u origin copilot/411
       ```
   - **Method 2 - Using SYSTEM_ACCESSTOKEN (if PAT not available)**:
     - Try using the System.AccessToken:
       ```bash
       git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push -u origin copilot/<work-item-id>
       ```
   - **Verify the push**:
     - After pushing, verify the branch exists in Azure DevOps
     - Check: `az repos ref list --org https://dev.azure.com/<org> --project "<project>" --repository "<repo>" --filter heads | grep copilot/<work-item-id>`
   - **If push fails**:
     - Report the error to the work item using `./scripts/add-comment-to-workitem.sh`
     - Include the full error message in the comment
     - **DO NOT** mark work item as "Done"
     - **DO NOT** try to create the PR if push failed
     - STOP execution and report the issue

10. **Create a Draft Pull Request with Required Reviewer - MANDATORY**:
   - **CRITICAL**: Use the provided script to create the PR with required reviewer in one step
   - **DO NOT** use `az repos pr create` - it cannot add required reviewers properly
   - **DO NOT** use `az repos pr create --reviewers` - this only adds optional reviewers, NOT required
   - **MANDATORY**: Use the provided script that creates PR in Draft mode with required reviewer
   - **Script to use**: `./scripts/create-pr-with-required-reviewer.sh`
   - **Script usage**:
     ```bash
     ./scripts/create-pr-with-required-reviewer.sh <organization> <project> <repository-id> <source-branch> <target-branch> <title> <description> <reviewer-email>
     ```
   - **Script usage**:
     ```bash
     ./scripts/create-pr-with-required-reviewer.sh <organization> <project> <repository-id> <source-branch> <target-branch> <title> <description> <reviewer-email>
     ```
   - **Parameters to extract**:
     - `organization`: From `System.CollectionUri` environment variable
     - `project`: From the work item's `System.TeamProject` field
     - `repository-id`: Get using `az repos show` command
     - `source-branch`: The branch name you created (e.g., `copilot/411`)
     - `target-branch`: Usually `main` or `master`
     - `title`: Include work item reference like `AB#411: Task description`
     - `description`: Detailed summary with emojis, features implemented, acceptance criteria met
     - `reviewer-email`: From the work item's `System.CreatedBy` field (extract uniqueName or email)
   - **Example**:
     ```bash
     REPO_ID=$(az repos show --org https://dev.azure.com/returngisorg --project "GitHub Copilot CLI" --repository "GitHub Copilot CLI" --query id -o tsv)
     ./scripts/create-pr-with-required-reviewer.sh returngisorg "GitHub Copilot CLI" "$REPO_ID" "copilot/411" "main" "AB#411: Add devcontainer configuration" "Detailed description here" "user@example.com"
     ```
   - **What the script does**:
     - Creates PR in **Draft** mode automatically
     - Adds the tag "copilot" automatically
     - Sets the reviewer as **Required** (NOT optional)
     - Verifies the reviewer was added correctly
     - Links PR to work item via AB# in title
     - Returns the PR ID and URL
   - **DO NOT**: Try to call the Azure DevOps REST API directly
   - **DO NOT**: Use `az repos pr create` with or without `--reviewers`
   - **DO**: Use this script which handles everything correctly in one atomic operation
   - **CRITICAL - Verify PR Creation and Required Reviewer**:
     - After the script completes, **VERIFY** the PR was created successfully
     - The script already does verification, but you should confirm from its output:
       - ✅ PR ID was returned
       - ✅ PR URL is accessible
       - ✅ Script confirmed "isRequired: true"
       - ✅ Script showed "SUCCESS: Reviewer is REQUIRED"
     - **If verification in script output shows any issues**:
       - Report the problem immediately
       - Do NOT proceed to next steps
       - Add comment to work item with the issue details
     - **Additional verification (optional but recommended)**:
       - Query the PR reviewers to double-check:
         ```bash
         az repos pr reviewer list --id <pr-id> --org https://dev.azure.com/<org> --detect true --output json | jq '.[] | select(.displayName == "<reviewer-name>") | {displayName, isRequired}'
         ```
       - Confirm output shows `"isRequired": true`
     - **If reviewer is NOT required after all checks**:
       - This is a CRITICAL ERROR
       - Report to work item immediately
       - Do NOT mark as complete

11. **Update Work Item Activity Field**:
   - Set the work item's "Activity" field based on what was requested in the work item
   - **MANDATORY**: Use the provided script to update the Activity field
   - **Script to use**: `./scripts/update-workitem-activity.sh`
   - **Script usage**:
     ```bash
     ./scripts/update-workitem-activity.sh <organization> <project> <work-item-id> <activity>
     ```
   - **Parameters to extract**:
     - `organization`: From `System.CollectionUri` environment variable
     - `project`: From the work item's `System.TeamProject` field
     - `work-item-id`: The Work Item ID number
     - `activity`: One of the valid activity values (see options below)
   - **Activity field options**:
     - `Deployment` - For deployment-related tasks, CI/CD, infrastructure
     - `Design` - For architectural design, UI/UX design work
     - `Development` - For coding, implementation, feature development (most common)
     - `Documentation` - For writing docs, README updates, code comments
     - `Requirements` - For gathering or defining requirements
     - `Testing` - For writing tests, QA work, test automation
   - **Example**:
     ```bash
     ./scripts/update-workitem-activity.sh returngisorg "My Project" 372 "Development"
     ```
   - **DO NOT**: Try to call the Azure DevOps REST API directly
   - **DO**: Use this script which handles the PATCH request and validates activity values
   - **IF SCRIPT FAILS**: Report the error to the work item and STOP - do NOT use `az boards` as fallback

12. **Report Issues (if any)**:
   - If any step in the workflow failed or encountered problems:
     - Clearly document which step(s) failed
     - Explain what went wrong and why
     - Provide error messages or logs if available
     - Suggest possible solutions or next steps
   - **Specific scenarios to report**:
     - If unable to push the branch: Explain the error and likely permission issues
     - If unable to create the PR: Detail the error and suggest permission fixes
     - **MANDATORY**: Add error information to the work item as a comment
     - **IMPORTANT - Use HTML Format**: Format error comments in HTML for better display
       - Example HTML error comment:
         ```html
         ❌ <b>Error:</b> Failed to push branch<br/><br/>
         <b>Details:</b> Permission denied<br/>
         <b>Error message:</b><br/>
         <pre>fatal: unable to access 'https://dev.azure.com/...': The requested URL returned error: 403</pre><br/>
         <b>Possible solution:</b> Please check repository access permissions for the build service account.
         ```
     - **Script to use**: `./scripts/add-comment-to-workitem.sh`
     - **Script usage**:
       ```bash
       ./scripts/add-comment-to-workitem.sh <organization> <project> <work-item-id> "❌ <b>Error:</b> <detailed error message in HTML>"
       ```
     - **Example**:
       ```bash
       ./scripts/add-comment-to-workitem.sh returngisorg "My Project" 372 "❌ <b>Error:</b> Failed to push branch. Permission denied.<br/><br/>Please check repository access permissions."
       ```
   - **DO NOT**: Try to call the Azure DevOps REST API directly for error reporting
   - **DO**: Use this script to add error comments so the user sees them in Azure DevOps
   - **IF SCRIPT FAILS**: Report the issue but continue with other cleanup tasks
   - Report this at the end of the execution so the user is aware of any issues

**⚠️ FINAL REMINDER:**
- **NEVER mark the work item as "Done"** - This is done automatically when the PR is merged
- The work item should remain in "Doing" state with a PR in Draft mode awaiting review
- The workflow is: To Do → Doing (with PR) → Done (after PR merge by reviewer)
- **DO NOT**: Use `az boards` CLI commands - ALWAYS use the provided scripts
- **DO NOT**: Make direct commits to main/master branch - ALWAYS create a branch and PR

**Example PR Description Format:**
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