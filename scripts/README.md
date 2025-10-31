# GitHub Copilot Coder - Scripts

This directory contains helper scripts used by the GitHub Copilot Coder workflow to manage commit and branch operations for GHES (GitHub Enterprise Server).

## 📋 Scripts Overview

### Core Scripts
- `prepare-commit.sh` - Prepares and commits changes with co-author attribution
- `push-branch.sh` - Pushes feature branch to remote repository
- `post-workflow-comment.sh` - Posts completion comment to GitHub issue

## � Script Descriptions

### `prepare-commit.sh`

Prepares and commits staged changes with proper co-author attribution.

**Usage:**
```bash
./scripts/prepare-commit.sh <issue_number> <issue_title> <creator_username>
```

**Parameters:**
- `issue_number` - GitHub issue number
- `issue_title` - GitHub issue title
- `creator_username` - GitHub username of issue creator

**Example:**
```bash
./scripts/prepare-commit.sh 42 "Add new feature" "octocat"
```

**What it does:**
- Validates that required parameters are provided
- Checks git configuration is set up
- Stages all changes (excluding metadata files)
- Creates a commit with co-author attribution
- Generates commit message from `commit-message.md` if available

**Environment variables:**
- Requires `GIT_AUTHOR_NAME` and `GIT_AUTHOR_EMAIL` set by workflow

### `push-branch.sh`

Pushes the feature branch to the remote repository.

**Usage:**
```bash
./scripts/push-branch.sh <branch_name>
```

**Parameters:**
- `branch_name` - Name of branch to push (typically `copilot/<issue-number>`)

**Example:**
```bash
./scripts/push-branch.sh copilot/42
```

**What it does:**
- Validates branch name is provided
- Pushes branch to origin
- Sets upstream tracking

**Environment variables:**
- Requires `GH_TOKEN` for authentication

### `post-workflow-comment.sh`

Posts a completion comment to the GitHub issue linking to the created pull request.

**Usage:**
```bash
./scripts/post-workflow-comment.sh <issue_number> <pr_url>
```

**Parameters:**
- `issue_number` - GitHub issue number
- `pr_url` - URL of the created pull request

**Example:**
```bash
./scripts/post-workflow-comment.sh 42 "https://github.com/owner/repo/pull/99"
```

**What it does:**
- Validates parameters are provided
- Posts a comment on the GitHub issue
- Links to the generated pull request
- Notifies issue creator of completion

**Environment variables:**
- Requires `GH_TOKEN` for authentication
