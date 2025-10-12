# Azure DevOps Automation Scripts

This directory contains automation scripts for Azure DevOps operations used by the GitHub Copilot CLI agent.

## Prerequisites

All scripts require:
- **AZURE_DEVOPS_PAT** environment variable with a valid Personal Access Token
- The PAT must have permissions for:
  - Work item tracking (read/write)
  - Code (read/write for PR operations)
  - Identity (read for user lookups)

## Scripts

### 0. get-workitem.sh

Retrieves and displays information about an Azure DevOps work item.

**Usage:**
```bash
./scripts/get-workitem.sh <work-item-id> [project]
```

**Parameters:**
- `work-item-id`: Work Item ID number (required)
- `project`: Project name (optional, uses System_TeamProject if not provided)

**Environment Variables:**
- `AZURE_DEVOPS_PAT`: Personal Access Token (required)
- `System_CollectionUri`: Azure DevOps organization URL (required) - e.g., `https://dev.azure.com/myorg/`
- `System_TeamProject`: Project name (used if project argument not provided)

**Examples:**
```bash
# Using environment variables (typical in Azure Pipelines)
./scripts/get-workitem.sh 412

# Specifying project explicitly (handles spaces automatically)
./scripts/get-workitem.sh 412 "GitHub Copilot CLI"

# With project name containing spaces
./scripts/get-workitem.sh 372 "My Project Name"
```

**What it displays:**
- Work Item ID, Type, Title, State
- Activity field value
- Assigned To, Created By (with email)
- Created Date
- Description (first 20 lines)
- Extracted information useful for other scripts (creator email, project name, etc.)

**Output:**
```
🔍 Retrieving Work Item from Azure DevOps
==========================================
Organization: returngisorg
Project: GitHub Copilot CLI
Work Item ID: 412

✅ Work item retrieved successfully!

================================================
📋 Work Item Details
================================================
ID:              412
Type:            Task
Title:           Add devcontainer configuration
State:           To Do
Activity:        Development
Assigned To:     Unassigned
Created By:      John Doe (john.doe@example.com)
Created Date:    2025-10-12T10:30:00Z

Description:
---
Add devcontainer configuration for the project...

================================================

📝 Extracted Information for Scripts:
---
Project:              GitHub Copilot CLI
Created By Name:      John Doe
Created By Email:     john.doe@example.com
Work Item Type:       Task
Current State:        To Do
Current Activity:     Development
```

**Use Cases:**
- Quickly view work item details before implementing
- Extract creator email for Co-authored-by commits
- Verify work item state and activity
- Get project name for other script operations

**Note:** This script automatically handles project names with spaces by URL-encoding them for the API call.

---

### 1. add-comment-to-workitem.sh

Adds a comment to an Azure DevOps work item.

**Usage:**
```bash
./scripts/add-comment-to-workitem.sh <organization> <project> <work-item-id> <comment-text>
```

**Parameters:**
- `organization`: Azure DevOps organization name (from System_CollectionUri)
- `project`: Project name (from System.TeamProject field)
- `work-item-id`: Work Item ID number
- `comment-text`: The comment text to add (supports HTML formatting)

**IMPORTANT - HTML Formatting:**
- Azure DevOps comments display better with HTML format, NOT Markdown
- Use `<b>` instead of `**` for bold
- Use `<i>` instead of `*` for italics
- Use `<br/>` for line breaks
- Use `<ul><li>` for lists
- Use `<a href="">` for links
- Use `<pre>` for code blocks

**Example:**
```bash
./scripts/add-comment-to-workitem.sh returngisorg "My Project" 372 "👀🤖 Started working on this task"

# HTML formatted example:
./scripts/add-comment-to-workitem.sh returngisorg "My Project" 372 "✅ <b>Implementation completed</b><br/><br/><b>Changes made:</b><ul><li>Feature A</li><li>Feature B</li></ul>"

# Error reporting example:
./scripts/add-comment-to-workitem.sh returngisorg "My Project" 372 "❌ <b>Error:</b> Failed to push branch<br/><br/><b>Details:</b> Permission denied"
```

**Output:**
- Success: "Comment added successfully. Comment ID: 12345"
- Error: Error message with HTTP status

---

### 2. update-workitem-state.sh

Updates the State field of an Azure DevOps work item.

**Usage:**
```bash
./scripts/update-workitem-state.sh <organization> <project> <work-item-id> <state>
```

**Parameters:**
- `organization`: Azure DevOps organization name (from System_CollectionUri)
- `project`: Project name (from System.TeamProject field)
- `work-item-id`: Work Item ID number
- `state`: New state value (e.g., "To Do", "Doing", "Done")

**Example:**
```bash
./scripts/update-workitem-state.sh returngisorg "My Project" 372 "Doing"
```

**Output:**
- Success: "Work item state updated successfully. Current state: Doing"
- Error: Error message with HTTP status

**Notes:**
- Valid state values depend on your work item type and process template
- Common states: "To Do", "Doing", "Done" (Agile), "New", "Active", "Closed" (Scrum)

---

### 3. assign-workitem.sh

Assigns an Azure DevOps work item to a user.

**Usage:**
```bash
./scripts/assign-workitem.sh <organization> <project> <work-item-id> <assignee>
```

**Parameters:**
- `organization`: Azure DevOps organization name (from System_CollectionUri)
- `project`: Project name (from System.TeamProject field)
- `work-item-id`: Work Item ID number
- `assignee`: User email or display name (e.g., "GitHub Copilot CLI")

**Example:**
```bash
./scripts/assign-workitem.sh returngisorg "My Project" 372 "GitHub Copilot CLI"
```

**Output:**
- Success: "Work item assigned successfully to: GitHub Copilot CLI"
- Error: Error message with HTTP status

**Notes:**
- To assign to the bot, use: "GitHub Copilot CLI"
- To unassign, pass empty string: ""

---

### 4. update-workitem-activity.sh

Updates the Activity field (Microsoft.VSTS.Common.Activity) of an Azure DevOps work item.

**Usage:**
```bash
./scripts/update-workitem-activity.sh <organization> <project> <work-item-id> <activity>
```

**Parameters:**
- `organization`: Azure DevOps organization name (from System_CollectionUri)
- `project`: Project name (from System.TeamProject field)
- `work-item-id`: Work Item ID number
- `activity`: Activity type (see valid values below)

**Valid Activity Values:**
- `Deployment` - For deployment-related tasks, CI/CD, infrastructure
- `Design` - For architectural design, UI/UX design work
- `Development` - For coding, implementation, feature development (most common)
- `Documentation` - For writing docs, README updates, code comments
- `Requirements` - For gathering or defining requirements
- `Testing` - For writing tests, QA work, test automation

**Example:**
```bash
./scripts/update-workitem-activity.sh returngisorg "My Project" 372 "Development"
```

**Output:**
- Success: "Work item Activity field updated successfully. Activity: Development"
- Error: Error message with HTTP status or invalid activity value

**Notes:**
- Activity field is case-sensitive
- Script validates against the list of valid values before making API call

---

### 5. create-pr-with-required-reviewer.sh

Creates an Azure DevOps Pull Request in Draft mode with a Required Reviewer in a single atomic operation.

**Usage:**
```bash
./scripts/create-pr-with-required-reviewer.sh <organization> <project> <repository-id> <source-branch> <target-branch> <title> <description> <reviewer-email>
```

**Parameters:**
- `organization`: Azure DevOps organization name
- `project`: Project name (will be URL-encoded by script)
- `repository-id`: Repository ID (GUID format)
- `source-branch`: Source branch name (e.g., "copilot/411")
- `target-branch`: Target branch name (e.g., "main")
- `title`: PR title (include work item reference like "AB#411: Description")
- `description`: PR description with details of changes
- `reviewer-email`: Email address of the required reviewer

**Example:**
```bash
# First get the repository ID
REPO_ID=$(az repos show --org https://dev.azure.com/returngisorg --project "My Project" --repository "My Repo" --query id -o tsv)

# Create PR with required reviewer
./scripts/create-pr-with-required-reviewer.sh returngisorg "My Project" "$REPO_ID" "copilot/411" "main" "AB#411: Add feature" "Description with details" user@example.com
```

**Output:**
- Success: "PR created successfully with Required Reviewer! PR ID: 77"
- Error: Error message with details

**What it does:**
1. Finds the reviewer's Identity ID from their email
2. Creates a Pull Request in **Draft** mode
3. Adds the reviewer as **Required** (NOT optional)
4. Automatically adds the "copilot" label to the PR
5. Verifies the reviewer was added with `isRequired: true`
6. Returns the PR ID and URL

**Notes:**
- PR is created in **Draft** mode by default
- Reviewer is set as **Required** which prevents PR completion without their approval
- The "copilot" label is automatically added
- This is an atomic operation - PR and required reviewer are added together
- Much more reliable than using `az repos pr create --reviewers` which only adds optional reviewers

---

### 6. add-required-reviewer.sh

Adds a required reviewer to an existing Azure DevOps Pull Request.

**Usage:**
```bash
./scripts/add-required-reviewer.sh <organization> <project> <repository-id> <pr-id> <reviewer-email>
```

**Parameters:**
- `organization`: Azure DevOps organization name
- `project`: Project name (will be URL-encoded by script)
- `repository-id`: Repository ID (GUID format)
- `pr-id`: Pull Request ID number
- `reviewer-email`: Email address of the reviewer

**Example:**
```bash
./scripts/add-required-reviewer.sh returngisorg "My Project" abc-123-def 42 user@example.com
```

**Output:**
- Success: "Required reviewer added successfully. Identity ID: <id>"
- Error: Error message with details

**How it works:**
1. Retrieves team members to find the reviewer's Identity ID from email
2. URL-encodes the project name for API compatibility
3. Makes PUT request to add reviewer as required
4. Verifies the reviewer was added with `isRequired: true`

**Notes:**
- Requires the reviewer to be a member of the project
- Sets `isRequired: true` which prevents PR completion without approval
- Uses PUT method (not PATCH) as per Azure DevOps API requirements

---

## Environment Variables

### AZURE_DEVOPS_PAT
Personal Access Token for authentication with Azure DevOps.

**Setting up:**
```bash
export AZURE_DEVOPS_PAT="your-pat-token-here"
```

**Required Scopes:**
- Work Item Tracking: Read & write
- Code: Read & write
- Identity: Read
- Project and Team: Read

---

## Error Handling

All scripts include error handling for:
- Missing or invalid parameters
- Missing AZURE_DEVOPS_PAT environment variable
- HTTP errors from Azure DevOps API
- Invalid data formats

Error messages are returned to stderr with appropriate exit codes.

---

## Testing

Test scripts with real Azure DevOps data before use in production:

```bash
# Test adding comment
./scripts/add-comment-to-workitem.sh returngisorg "Test Project" 123 "Test comment"

# Test updating state
./scripts/update-workitem-state.sh returngisorg "Test Project" 123 "Doing"

# Test assigning work item
./scripts/assign-workitem.sh returngisorg "Test Project" 123 "user@example.com"

# Test updating activity
./scripts/update-workitem-activity.sh returngisorg "Test Project" 123 "Development"

# Test adding reviewer
./scripts/add-required-reviewer.sh returngisorg "Test Project" repo-id 1 "user@example.com"
```

---

## API References

- [Work Items - Add Comment](https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/comments/add?view=azure-devops-rest-7.0)
- [Work Items - Update](https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/work-items/update?view=azure-devops-rest-7.0)
- [Pull Request Reviewers - Create](https://learn.microsoft.com/en-us/rest/api/azure/devops/git/pull-request-reviewers/create-pull-request-reviewer?view=azure-devops-rest-7.0)
- [Identities - Read Team Members](https://learn.microsoft.com/en-us/rest/api/azure/devops/core/teams/get-team-members-with-extended-properties?view=azure-devops-rest-7.0)

