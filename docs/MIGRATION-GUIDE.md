# 🔄 Migration Guide: Azure DevOps to GHES

This guide walks you through migrating from the Azure DevOps Coding Agent to the GitHub Enterprise Server (GHES) implementation.

## 📋 Overview

### What's Changing

| Aspect | Azure DevOps | GitHub Enterprise Server |
|--------|--------------|--------------------------|
| **Trigger** | Webhook | GitHub Actions (issue labeled) |
| **Work Items** | ADO Work Items | GitHub Issues |
| **Pipeline** | azure-pipelines.yml | .github/workflows/copilot-coder.yml |
| **Authentication** | AZURE_DEVOPS_PAT | GH_TOKEN |
| **Repository** | Multi-repo (orchestration + target) | Single repository |
| **State Management** | Work item states | Issue labels |
| **Linking** | API calls to link branches/PRs | Native GitHub linking |
| **Scripts** | 15+ scripts | 4 scripts (simplified) |

### What's Staying the Same

- ✅ GitHub Copilot CLI for code generation
- ✅ MCP servers for context (Context7, Fetch, Time)
- ✅ Node.js 22.x and Python 3.x runtime
- ✅ Copilot instructions file
- ✅ Commit message and PR description generation
- ✅ Co-author attribution

## 🗺️ Migration Steps

### Phase 1: Preparation (Before Migration)

#### 1.1 Backup Current Setup

```bash
# Clone your ADO repository
git clone https://dev.azure.com/your-org/your-project/_git/your-repo
cd your-repo

# Create backup branch
git checkout -b backup-ado-setup
git push origin backup-ado-setup
```

#### 1.2 Document Current Configuration

Document your current setup:

- Variable group values
- Service connections
- Webhook configuration
- Repository URLs
- Team members with access

#### 1.3 Export Work Items (Optional)

If you want to migrate existing work items to GitHub issues:

1. Export work items from ADO:
   - Use Azure DevOps REST API or CLI
   - Export to CSV or JSON

2. Prepare for import to GitHub:
   - Convert to GitHub issue format
   - Map ADO fields to GitHub issue fields

### Phase 2: GHES Repository Setup

#### 2.1 Create or Migrate Repository

**Option A: New Repository**
```bash
# Create new repository on GHES
gh repo create your-repo --private

# Clone and push
git clone https://github.com/your-org/your-repo
cd your-repo
```

**Option B: Migrate Existing Repository**
```bash
# Add GHES remote
git remote add ghes https://github.com/your-org/your-repo

# Push all branches
git push ghes --all

# Push all tags
git push ghes --tags
```

#### 2.2 Port Configuration Files

1. **Copy files from ADO repo to GHES repo**:

```bash
# In your ADO repo
cd /path/to/ado-repo

# Copy essential files
cp mcp-config.json /path/to/ghes-repo/
cp .github/copilot-instructions.md /path/to/ghes-repo/.github/
cp -r scripts/prepare-commit.sh /path/to/ghes-repo/scripts/
cp -r scripts/push-branch.sh /path/to/ghes-repo/scripts/
```

2. **Copy new GHES files**:

The new implementation adds these files:
- `.github/workflows/copilot-coder.yml`
- `.github/ISSUE_TEMPLATE/copilot-task.md`
- `scripts/update-issue-labels.sh`
- `scripts/post-workflow-comment.sh`
- `docs/GHES-SETUP.md`
- `docs/MIGRATION-GUIDE.md`
- `docs/TROUBLESHOOTING.md`

#### 2.3 Configure Secrets

Map your ADO variables to GitHub secrets:

| ADO Variable | GitHub Secret | Notes |
|--------------|---------------|-------|
| `GH_TOKEN` | `GH_TOKEN` | Use GHES token, not GitHub.com |
| `AZURE_DEVOPS_PAT` | N/A | Not needed in GHES |
| `CONTEXT7_API_KEY` | `CONTEXT7_API_KEY` | Same value |
| `COPILOT_VERSION` | N/A | Now in workflow env vars |
| `MODEL` | N/A | Now in workflow env vars |

**Configure secrets**:
```bash
# Using GitHub CLI
gh secret set GH_TOKEN
gh secret set CONTEXT7_API_KEY
```

Or via web UI:
1. Go to repository Settings
2. Secrets and variables → Actions
3. New repository secret

### Phase 3: Script Migration

#### 3.1 Scripts No Longer Needed

These ADO-specific scripts are not needed in GHES:

- ❌ `parse-webhook-data.sh` - No webhooks
- ❌ `get-workitem.sh` - GitHub Issues via API
- ❌ `clone-target-repo.sh` - Single repo
- ❌ `orchestrate-workitem.sh` - Native GitHub Actions
- ❌ `link-branch-to-workitem.sh` - Native linking
- ❌ `update-workitem-activity.sh` - Use labels
- ❌ `add-completion-comment.sh` - New script
- ❌ `create-pr-and-link.sh` - GitHub CLI
- ❌ `link-pr-to-workitem.sh` - Native linking
- ❌ `add-comment-to-workitem.sh` - New script
- ❌ `assign-workitem.sh` - GitHub issue assignment
- ❌ `update-workitem-state.sh` - Use labels
- ❌ `create-pr-with-required-reviewer.sh` - GitHub CLI

#### 3.2 Scripts Updated for GHES

These scripts have been updated to support both ADO and GHES:

**`prepare-commit.sh`**
- Now accepts GitHub username instead of project name
- Constructs email from GitHub username
- Falls back to ADO mode if `get-workitem.sh` exists

**`push-branch.sh`**
- Now supports single parameter (branch name) for GHES
- Uses `GH_TOKEN` instead of `AZURE_DEVOPS_PAT`
- Maintains backwards compatibility with ADO (4 parameters)

#### 3.3 New Scripts for GHES

**`update-issue-labels.sh`**
- Adds or removes labels from GitHub issues
- Usage: `./scripts/update-issue-labels.sh <issue_number> <add|remove> <labels>`

**`post-workflow-comment.sh`**
- Posts completion comment to GitHub issue
- Usage: `./scripts/post-workflow-comment.sh <issue_number> <pr_url>`

### Phase 4: Update Copilot Instructions

Update `.github/copilot-instructions.md` if needed:

**Changes to consider**:
- Remove references to Azure DevOps
- Update examples to use GitHub terminology
- Update file paths if different
- Keep the core instructions the same

### Phase 5: Testing

#### 5.1 Test Workflow Trigger

1. Create a test issue:
```markdown
## 📋 Task Description
Create a simple Python script that prints "Hello, GHES!".

## 🎯 Acceptance Criteria
- [ ] Create hello.py
- [ ] Script prints "Hello, GHES!"
```

2. Add the `copilot` label

3. Monitor the workflow:
```bash
gh run watch
```

#### 5.2 Verify Each Step

Check that each workflow step completes successfully:

- ✅ Workflow triggers on label
- ✅ Python and Node.js installed
- ✅ Copilot CLI installed
- ✅ MCP servers configured
- ✅ Feature branch created
- ✅ Copilot generates code
- ✅ Changes committed
- ✅ Branch pushed
- ✅ PR created
- ✅ Issue commented
- ✅ Labels updated

#### 5.3 Test Edge Cases

Test various scenarios:

1. **Empty description**: Issue with minimal description
2. **Complex task**: Multi-file implementation
3. **With references**: Issue with URLs to documentation
4. **With specific versions**: Request specific library versions
5. **Error handling**: Test failure scenarios

### Phase 6: Parallel Operation (Optional)

Run both ADO and GHES systems in parallel:

#### 6.1 Test Period

1. Keep ADO pipeline running
2. Test GHES workflow with non-critical issues
3. Compare results between both systems
4. Gather feedback from team

#### 6.2 Gradual Migration

Gradually shift work items to GHES:

**Week 1-2**: 
- Test issues only
- Critical work stays in ADO

**Week 3-4**: 
- Non-critical features in GHES
- Monitor for issues

**Week 5+**: 
- All new work in GHES
- Complete migration

### Phase 7: Documentation and Training

#### 7.1 Update Documentation

Update your team documentation:

- How to create Copilot tasks
- How to trigger workflows
- How to review generated PRs
- Troubleshooting guide

#### 7.2 Team Training

Train your team on:

- Creating GitHub issues vs ADO work items
- Using labels to trigger workflows
- Reviewing Copilot-generated PRs
- Monitoring workflow runs
- Accessing logs and artifacts

### Phase 8: Cleanup

#### 8.1 Archive ADO Pipeline

Once fully migrated:

1. Disable ADO webhook
2. Archive ADO pipeline
3. Keep repository for reference
4. Document the cutover date

#### 8.2 Remove Unused Files

Remove ADO-specific files from GHES repo:

```bash
# Optional: Remove ADO files
git rm azure-pipelines.yml
git rm work-item-updated-pipeline.yml
git rm templates/run-script.yml
git rm scripts/parse-webhook-data.sh
git rm scripts/get-workitem.sh
# ... (other ADO scripts)

git commit -m "chore: Remove ADO-specific files after migration"
git push
```

Or keep them with a deprecation notice:

```bash
# Add deprecation notice
echo "# DEPRECATED: This file is from the ADO implementation and is no longer used." > azure-pipelines.yml.deprecated
git add azure-pipelines.yml.deprecated
git commit -m "docs: Mark ADO files as deprecated"
git push
```

## 🔄 Mapping Guide

### Work Item → Issue Mapping

| ADO Work Item Field | GitHub Issue Equivalent |
|---------------------|-------------------------|
| Work Item ID | Issue Number (#123) |
| Title | Issue Title |
| Description | Issue Body |
| State | Labels (in-progress, completed, etc.) |
| Assigned To | Assignee |
| Tags | Labels |
| Comments | Comments |
| Attachments | Uploaded files in comments |
| Related Work Items | Linked issues (#123, #456) |
| Iteration | Milestone |
| Area Path | Project board columns |

### Pipeline → Workflow Mapping

| ADO Pipeline Concept | GitHub Actions Equivalent |
|----------------------|---------------------------|
| Pipeline | Workflow |
| Stage | Job |
| Job | Job |
| Task | Step |
| Variable Group | Repository Secrets |
| Service Connection | Secrets |
| Artifact | Artifact |
| Pipeline Run | Workflow Run |

### API → API Mapping

| ADO API | GitHub API | Example |
|---------|------------|---------|
| `GET workitems/{id}` | `GET /repos/{owner}/{repo}/issues/{number}` | Get issue details |
| `PATCH workitems/{id}` | `PATCH /repos/{owner}/{repo}/issues/{number}` | Update issue |
| `POST pullrequests` | `POST /repos/{owner}/{repo}/pulls` | Create PR |
| `POST comments` | `POST /repos/{owner}/{repo}/issues/{number}/comments` | Add comment |

## 📊 Comparison

### Advantages of GHES Implementation

1. **Simpler architecture**: Single repository, no webhooks
2. **Native integration**: Built-in GitHub Actions, no external services
3. **Better visibility**: All activity in one place
4. **Easier debugging**: Centralized logs and artifacts
5. **Lower maintenance**: Fewer moving parts
6. **Better security**: Fewer tokens and connections to manage
7. **Cost effective**: No ADO licensing needed

### Considerations

1. **Label-based states**: Less rich than ADO work item states
2. **No custom fields**: GitHub issues have fixed schema
3. **Different UI**: Team needs to learn GitHub interface
4. **Migration effort**: One-time effort to move existing work

## 🆘 Troubleshooting Migration Issues

### Issue: Workflow doesn't trigger

**Solution**: 
- Verify label is exactly `copilot`
- Check workflow file syntax
- Ensure workflow is enabled

### Issue: Authentication fails

**Solution**:
- Verify `GH_TOKEN` is from GHES, not GitHub.com
- Check token scopes include `repo` and `copilot_requests`
- Regenerate token if expired

### Issue: Scripts fail

**Solution**:
- Make scripts executable: `chmod +x scripts/*.sh`
- Test scripts locally first
- Check bash version compatibility

### Issue: MCP servers not working

**Solution**:
- Verify `CONTEXT7_API_KEY` is set
- Test MCP config locally
- Check network connectivity

## 📚 Additional Resources

- [GHES Setup Guide](GHES-SETUP.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Issues Documentation](https://docs.github.com/en/issues)
- [GitHub CLI Documentation](https://cli.github.com/manual/)

## ✅ Migration Checklist

### Pre-Migration
- [ ] Backup ADO repository
- [ ] Document current configuration
- [ ] Export work items (if needed)
- [ ] Create or migrate GHES repository

### Setup
- [ ] Copy configuration files
- [ ] Create workflow file
- [ ] Configure repository secrets
- [ ] Update scripts
- [ ] Create issue templates
- [ ] Add documentation

### Testing
- [ ] Test workflow trigger
- [ ] Test Copilot execution
- [ ] Test PR creation
- [ ] Test label updates
- [ ] Test edge cases

### Deployment
- [ ] Train team
- [ ] Update documentation
- [ ] Run parallel (optional)
- [ ] Monitor and adjust
- [ ] Complete migration

### Cleanup
- [ ] Disable ADO webhook
- [ ] Archive ADO pipeline
- [ ] Remove/mark ADO files as deprecated
- [ ] Update team documentation

## 🎉 Congratulations!

You've successfully migrated from Azure DevOps to GitHub Enterprise Server! Your team can now enjoy a simpler, more integrated development workflow.
