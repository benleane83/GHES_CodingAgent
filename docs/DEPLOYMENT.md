# 🚀 Deploying Copilot Workflows to New Repositories

This guide explains how to deploy the GitHub Copilot Coder and Reviewer workflows to any repository on your GitHub Enterprise Server.

## 📋 Prerequisites Summary

Before deploying, ensure these prerequisites are met:

### Self-Hosted Runner Requirements

| Component | Required | Installation |
|-----------|----------|--------------|
| **GitHub CLI (`gh`)** | ✅ Yes | Must be pre-installed manually |
| **Node.js 22.x** | ✅ Yes | Installed automatically by workflow |
| **Python 3.x** | ✅ Yes | Installed automatically by workflow |
| **uv/uvx** | ✅ Yes | Installed automatically by workflow |

### Organization or Repository Secrets

| Secret | Required | Description |
|--------|----------|-------------|
| `GH_TOKEN` | ✅ Yes | **Classic PAT** from GHES with `repo` and `workflow` scopes |
| `COPILOT_TOKEN` | ✅ Yes | Token for GitHub Copilot API access |
| `CONTEXT7_API_KEY` | ❌ Optional | API key for Context7 documentation service |

### Required Labels

These labels are created automatically by the deployment script:

| Label | Color | Purpose |
|-------|-------|---------|
| `copilot` | `#7057ff` | Triggers code generation and PR review workflows |
| `in-progress` | `#fbca04` | Applied while workflow is running |
| `ready-for-review` | `#0e8a16` | Applied when PR is ready |

---

## 🔧 Automated Deployment (Recommended)

Use the deployment script to automatically set up everything:

### PowerShell (Windows)

```powershell
# From the GHES_CodingAgent repository
.\scripts\deploy-to-repo.ps1 `
    -GhesHost "ghes.company.com" `
    -Owner "myorg" `
    -Repo "my-new-repo" `
    -GhToken "ghp_xxxxxxxxxxxx"
```

### Bash (Linux/Mac/Git Bash)

```bash
./scripts/deploy-to-repo.sh ghes.company.com myorg my-new-repo ghp_xxxxxxxxxxxx
```

### What the Script Does

1. ✅ Clones the target repository
2. ✅ Copies lightweight caller workflow files (2 files only)
3. ✅ Updates organization reference in workflows
4. ✅ Creates required labels
5. ✅ Creates a Pull Request with setup instructions

### What Gets Deployed

Only **2 small files** are deployed to target repositories:

| File | Size | Description |
|------|------|-------------|
| `.github/workflows/copilot-coder.yml` | ~30 lines | Calls master coder workflow |
| `.github/workflows/copilot-reviewer.yml` | ~35 lines | Calls master reviewer workflow |

### After Running the Script

1. **Review and merge** the created PR
2. **Add repository secrets** (see below)
3. **Verify runner setup** (GitHub CLI installed)

---

## 🔐 Creating the GH_TOKEN

The `GH_TOKEN` **must be a Classic PAT** created on your GHES instance (not github.com).

### Steps

1. Go to `https://<your-ghes-host>/settings/tokens`
2. Click **"Generate new token"** → **"Generate new token (classic)"**
3. Set expiration (recommend 90 days or longer)
4. Select scopes:
   - ✅ `repo` (Full control of private repositories)
   - ✅ `workflow` (Update GitHub Action workflows)
5. Click **Generate token**
6. Copy and save the token securely

### ⚠️ Important Notes

- **Do NOT use Fine-grained PATs** - They have issues with GraphQL operations on GHES
- **Create on GHES, not github.com** - The token must be from your GHES instance
- **Rotate regularly** - Set calendar reminders for token expiration

---

## 🖥️ Self-Hosted Runner Setup

### Install GitHub CLI (Required)

SSH into your runner VM and run:

```bash
# Download GitHub CLI
GH_VERSION="2.62.0"
cd /tmp
curl -L -o gh.tar.gz "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz"

# Extract and install
tar -xzf gh.tar.gz
sudo mv gh_${GH_VERSION}_linux_amd64/bin/gh /usr/local/bin/
sudo chmod +x /usr/local/bin/gh

# Verify
gh --version
```

### If Runner Cannot Reach github.com

Download the binary on another machine and transfer:

```powershell
# On a machine with internet access
curl -L -o gh.tar.gz "https://github.com/cli/cli/releases/download/v2.62.0/gh_2.62.0_linux_amd64.tar.gz"

# Transfer to runner
scp gh.tar.gz user@<runner-ip>:/tmp/
```

Then install on the runner as shown above.

---

## ✅ Verification Checklist

After deployment, verify everything is set up correctly:

- [ ] Workflows visible in **Actions** tab
- [ ] All 3 labels created (`copilot`, `in-progress`, `ready-for-review`)
- [ ] `GH_TOKEN` secret configured
- [ ] `COPILOT_TOKEN` secret configured
- [ ] GitHub CLI installed on runner (`gh --version`)
- [ ] Runner is online and idle

### Test the Setup

1. Create a test issue with a simple task description
2. Add the `copilot` label
3. Watch the workflow run in the Actions tab
4. Verify PR is created successfully

---

## 🔄 Updating Deployed Workflows

Since target repositories use **caller workflows** that reference the master workflows in `GHES_CodingAgent`:

- **No action needed!** Updates to master workflows automatically apply to all repositories
- Only re-deploy if the caller workflow file structure changes

---

## 🆘 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| `gh: command not found` | Install GitHub CLI on runner |
| `HTTP 401: Bad credentials` | Token is invalid or from wrong server |
| `Resource not accessible by personal access token` | Use Classic PAT instead of Fine-grained |

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for more solutions.
