# GitHub Enterprise Server (GHES) Compatibility Analysis

This document details the compatibility of the GitHub Copilot Coder application with GitHub Enterprise Server environments, based on testing performed on GitHub Enterprise Cloud.

**Deployment Assumption**: GHES environments have internet connectivity and firewall access to required external services.

---

## ✅ Compatible Components

### GitHub Actions Core Features
- ✅ **Workflow triggers** - `issues.opened` and `issues.labeled` events work identically
- ✅ **Native permissions block** - `contents: write`, `issues: write`, `pull-requests: write` supported
- ✅ **GITHUB_TOKEN** - Auto-generated token works the same way
- ✅ **GitHub CLI** - Full feature parity across `gh` commands used (issue edit, pr create)
- ✅ **Standard actions** - `actions/checkout@v4`, `actions/setup-python@v5`, `actions/setup-node@v4`, `actions/cache@v4`, `actions/upload-artifact@v4` all supported

### Shell Scripts
- ✅ **prepare-commit.sh** - No GHES-specific dependencies; uses standard git commands
- ✅ **push-branch.sh** - Extracts hostname dynamically from remote URL, supports any hostname
- ✅ **post-workflow-comment.sh** - Uses `gh` CLI which works across GHES and GitHub.com

---

## ⚠️ GHES Compatibility Considerations

### 1. **Context7 MCP Server - Requires Internet Access (RESOLVED)**

**Requirement**: Context7 is a cloud-hosted service by Upstash requiring `context7.com` connectivity.

**Status**: ✅ **Compatible** - With assumption of internet connectivity

**Location in code**:
- `mcp-config.json` - Line 3-12
- `.github/workflows/copilot-coder.yml` - Line 150 (MCP configuration step)
- `.github/workflows/copilot-coder.yml` - Line 166 (Check MCP Access step)
- `.github/workflows/copilot-coder.yml` - Line 200 (Copilot execution with CONTEXT7_API_KEY)

**Network Path Required**:
```
GHES Runner → context7.com:443 (HTTPS)
```

**Configuration**:
- `CONTEXT7_API_KEY` secret must be set in repository
- Context7 account required (sign up at https://context7.com)
- Firewall must allow outbound HTTPS to context7.com

**Note**: Currently no graceful fallback if Context7 is unavailable. Workflow will fail if API key missing or service unreachable. Consider making optional if needed in future.

---

### 2. **Copilot CLI Licensing - Clarification Needed (HIGH PRIORITY)**

**Status**: ⚠️ **Requires Verification** - Assumed compatible but not tested on GHES

**Questions to resolve**:
- Does `@github/copilot` npm package authenticate with GHES token or require GitHub.com account?
- Does Copilot for Enterprise license apply to GHES deployments?
- What authentication method should GHES runners use?

**Location in code**:
- `.github/workflows/copilot-coder.yml` - Lines 95-103 (Copilot CLI installation)
- `.github/workflows/copilot-coder.yml` - Line 200 (Copilot execution)

**Next Steps**:
- [ ] Contact GitHub support - confirm GHES compatibility and licensing
- [ ] Test: Install `@github/copilot` using GHES GH_TOKEN
- [ ] Document authentication approach for GHES

---

### 3. **Email Address Format - Hardcoded Domain (MODERATE)**

**Issue**: Code assumes hardcoded `@users.noreply.github.com` email domain.

**Status**: 🟡 **Needs Fix** - GHES instances use different noreply domains

**Location in code**:
- `scripts/prepare-commit.sh` - Line 35:
  ```bash
  CREATOR_EMAIL="${CREATOR_USERNAME}@users.noreply.github.com"
  ```

**GHES Noreply Domain Format**: `username@users.noreply.<your-ghes-domain>`

**Example**:
- GitHub.com: `user@users.noreply.github.com`
- GHES: `user@users.noreply.ghes.company.com`

**Solution**: Query GHES instance metadata to extract correct domain
```bash
# Extract GHES web URL
GHES_DOMAIN=$(gh api /meta --jq -r '.web_url' | sed 's|https://||' | sed 's|/||g')
CREATOR_EMAIL="${CREATOR_USERNAME}@users.noreply.${GHES_DOMAIN}"
```

**Impact if not fixed**: 
- Commit author attribution will use incorrect noreply email
- May cause issues with email routing or audit trails
- Not critical but inconsistent with GHES conventions

---

### 4. **NPM Registry Access (LOW)**

**Status**: ✅ **Compatible** - Requires firewall access

**Requirements**:
- Outbound HTTPS access to `registry.npmjs.org`
- Used by: `@github/copilot` package installation
- Used by: MCP server installation via npm/npx

**Network Paths Required**:
```
GHES Runner → registry.npmjs.org:443 (HTTPS)
```

**Configuration**:
- No special configuration needed if standard npm access available
- If behind corporate proxy: Configure `.npmrc` with proxy settings
- If using private npm registry: Update package.json with registry URL

**Note**: npm registry access is standard for GitHub Actions runners; unlikely to be blocked

---

### 5. **Python PyPI Access (LOW)**

**Status**: ✅ **Compatible** - Requires firewall access

**Requirements**:
- Outbound HTTPS access to `pypi.org`
- Used by: Python package installation (uv)
- Used by: MCP server dependencies

**Network Paths Required**:
```
GHES Runner → pypi.org:443 (HTTPS)
```

**Configuration**:
- Standard Python access; no special configuration needed
- If behind corporate proxy: Set PIP_PROXY environment variable
- Alternative: Pre-cache Python packages in runner image

---

### 6. **Documentation Links - GitHub.com References (LOW)**

**Issue**: Some documentation references link to github.com endpoints.

**Status**: 🟢 **Minor** - Affects end-user navigation only

**Locations**:
- `docs/GHES-SETUP.md` - External links to GitHub.com
- `docs/TROUBLESHOOTING.md` - External links to GitHub.com
- `README.md` - Badge links to github.com

**Solution**: Add GHES-equivalent documentation references
- Include GHES documentation links alongside GitHub.com links
- Document how to access equivalent features on GHES instance

---

## 🌐 Required Network/Firewall Paths

For the application to function fully on GHES, the following outbound network paths must be accessible from GHES runners:

### Critical Paths (Workflow Will Fail Without)

| Service | Host | Port | Protocol | Purpose | Severity |
|---------|------|------|----------|---------|----------|
| GHES API | `<your-ghes-host>` | 443 | HTTPS | GitHub CLI communication, API calls | 🔴 Critical |
| Copilot CLI | `registry.npmjs.org` | 443 | HTTPS | Download @github/copilot package | 🔴 Critical |
| Python | `pypi.org` | 443 | HTTPS | Install `uv` package manager | 🔴 Critical |
| Context7 | `api.context7.com` | 443 | HTTPS | MCP documentation service | 🔴 Critical |

### Optional Paths (Reduce Functionality if Blocked)

| Service | Host | Port | Protocol | Purpose | Impact if Blocked |
|---------|------|------|----------|---------|------------------|
| npm CDN | `cdn.jsdelivr.net` | 443 | HTTPS | npm package caching/delivery | Slower package installs |
| GitHub Docs | `docs.github.com` | 443 | HTTPS | External documentation links | User navigation only |

### Firewall Configuration Template

```bash
#!/bin/bash
# GHES Runner Firewall Configuration

# Critical outbound rules (must allow)
firewall_rule_allow_outbound "registry.npmjs.org" "443" "HTTPS" "npm package registry"
firewall_rule_allow_outbound "pypi.org" "443" "HTTPS" "Python package registry"
firewall_rule_allow_outbound "api.context7.com" "443" "HTTPS" "Context7 MCP service"
firewall_rule_allow_outbound "<your-ghes-host>" "443" "HTTPS" "GHES API"

# Optional rules (recommended)
firewall_rule_allow_outbound "cdn.jsdelivr.net" "443" "HTTPS" "CDN for package delivery"
firewall_rule_allow_outbound "docs.github.com" "443" "HTTPS" "Documentation"
```

### DNS Requirements

The following DNS records must resolve from GHES runners:

```
registry.npmjs.org          → npm package registry
pypi.org                    → Python package repository  
api.context7.com            → Context7 API endpoint
<your-ghes-host>            → Your GHES instance (internal DNS or hosts)
```

### Proxy Configuration (If Behind Corporate Proxy)

If GHES runners are behind a corporate proxy, configure the following:

**npm Proxy** (`.npmrc`):
```
registry=https://registry.npmjs.org/
proxy=http://proxy.company.com:8080
https-proxy=http://proxy.company.com:8080
```

**pip Proxy** (Workflow step):
```yaml
- name: Configure pip proxy
  run: |
    pip config set global.proxy [user[:passwd]@]proxy.server:port
```

**Git Proxy** (For repository operations):
```bash
git config --global http.proxy http://proxy.company.com:8080
git config --global https.proxy https://proxy.company.com:8080
```

---

## 🛠️ GHES Deployment Checklist

### Pre-Deployment: Network Connectivity

- [ ] **Verify outbound HTTPS access**
  ```bash
  # From GHES runner, test connectivity to all critical services
  curl -I https://registry.npmjs.org/
  curl -I https://pypi.org/
  curl -I https://api.context7.com/
  curl -I https://<your-ghes-host>/
  ```

- [ ] **Validate DNS resolution**
  ```bash
  # Ensure all domains resolve correctly
  nslookup registry.npmjs.org
  nslookup pypi.org
  nslookup api.context7.com
  nslookup <your-ghes-host>
  ```

- [ ] **Check firewall rules**
  - Allow outbound HTTPS (443) to npm, PyPI, Context7, GHES
  - Allow DNS (53) to resolve external services
  - If using proxy: Test proxy connectivity and authentication

- [ ] **Configure proxy (if needed)**
  - Set environment variables on GHES runner
  - Update `.npmrc`, `.pip.conf`, git config

### Pre-Deployment: GHES Instance Configuration

- [ ] **Verify GitHub Copilot for Enterprise license**
  - Confirm license is active
  - Check license usage/limits
  - Verify Copilot CLI access enabled

- [ ] **Create fine-grained Personal Access Token (PAT)**
  ```bash
  # Required permissions:
  - contents: write       (for push operations)
  - pull_requests: write  (for PR creation)
  - issues: write         (for issue operations)
  
  # Token expiration: Set appropriate retention (e.g., 90 days)
  # Store as GH_TOKEN secret in repository
  ```

- [ ] **Configure repository secrets**
  ```
  GH_TOKEN                = [fine-grained PAT from above]
  CONTEXT7_API_KEY        = [Context7 API key from context7.com]
  ```

- [ ] **Verify GitHub CLI authentication**
  ```bash
  gh auth login --hostname <your-ghes-host>
  gh auth status
  ```

### Pre-Deployment: GHES Noreply Email Configuration

- [ ] **Query GHES instance metadata**
  ```bash
  gh api /meta --jq '.'
  # Look for web_url field, e.g., "https://ghes.company.com"
  
  # Extract noreply domain
  GHES_DOMAIN=$(gh api /meta --jq -r '.web_url' | sed 's|https://||' | sed 's|/||g')
  echo "Noreply domain: users.noreply.${GHES_DOMAIN}"
  ```

- [ ] **Update prepare-commit.sh** (if not using automated extraction)
  - Replace hardcoded github.com with your GHES noreply domain
  - OR use script to query domain automatically

### Testing: Workflow Execution

- [ ] **Create test issue with copilot label**
  - Navigate to repository on GHES
  - Create new issue
  - Add `copilot` label
  - Monitor workflow execution

- [ ] **Verify each workflow step**
  - ✅ Checkout succeeds with GH_TOKEN
  - ✅ Python/Node.js setup completes
  - ✅ npm packages install (Copilot CLI, MCP servers)
  - ✅ MCP servers load successfully
  - ✅ Copilot CLI executes without auth errors
  - ✅ Changes committed with correct author email
  - ✅ Branch pushed to remote
  - ✅ PR created on GHES

- [ ] **Check workflow artifacts**
  - Review Copilot CLI logs in workflow artifacts
  - Verify no auth/permission errors
  - Check MCP server outputs

### Testing: Error Scenarios

- [ ] **Network connectivity failure**
  - Temporarily block outbound to Context7
  - Verify workflow behavior (should fail gracefully)

- [ ] **Missing credentials**
  - Remove CONTEXT7_API_KEY secret
  - Verify error message is clear

- [ ] **Token permission errors**
  - Use token with limited permissions
  - Verify specific permission requirement in error message

---

## 📋 Known Limitations

| Issue | Severity | Status | Resolution |
|-------|----------|--------|-----------|
| Copilot CLI licensing on GHES | ⚠️ High | Unverified | Contact GitHub support |
| Hardcoded noreply domain | 🟡 Moderate | Needs fix | Query instance metadata |
| Context7 required for docs | 🟡 Moderate | By design | Sign up for Context7 |
| No graceful Context7 fallback | 🟡 Moderate | Future enhancement | Make optional if needed |
| Documentation links to github.com | 🟢 Low | Cosmetic | Add GHES link equivalents |

---

## 🚨 Troubleshooting Network Issues

### Symptom: "npm ERR! 404 Not Found"
**Cause**: Cannot reach npm registry  
**Fix**: Check firewall allows `registry.npmjs.org:443`

### Symptom: "Connection refused" when installing uv
**Cause**: Cannot reach PyPI  
**Fix**: Check firewall allows `pypi.org:443`

### Symptom: "Context7 MCP server failed to initialize"
**Cause**: Cannot reach `api.context7.com` or invalid `CONTEXT7_API_KEY`  
**Fix**: 
- Verify firewall allows `api.context7.com:443`
- Verify `CONTEXT7_API_KEY` secret is set correctly
- Test Context7 API key manually at https://context7.com

### Symptom: "Permission denied" on git push
**Cause**: GH_TOKEN missing `contents:write` permission  
**Fix**: Verify PAT has correct permissions and hasn't expired

### Symptom: Commit author has wrong noreply domain
**Cause**: Hardcoded github.com domain used instead of GHES domain  
**Fix**: Update `prepare-commit.sh` with correct GHES noreply domain

---

## 📚 Verification Commands

Run these commands on GHES runner to verify setup:

```bash
# 1. Test GHES API access
gh api /user --hostname <your-ghes-host>

# 2. Verify npm registry access
npm view @github/copilot version

# 3. Check Python environment
python --version
uv --version

# 4. Validate MCP server installation
npx @upstash/context7-mcp --version

# 5. Test GitHub CLI with Copilot
copilot --version

# 6. Verify Context7 connectivity
curl -H "Authorization: Bearer $CONTEXT7_API_KEY" \
  https://api.context7.com/health
```

---

## 📞 Support Resources

- [GitHub Enterprise Server Docs](https://docs.github.com/en/enterprise-server)
- [GitHub Actions in GHES](https://docs.github.com/en/enterprise-server@latest/actions)
- [GitHub CLI Manual](https://cli.github.com/manual/)
- [Copilot for Enterprise](https://docs.github.com/en/copilot/overview-of-github-copilot/about-github-copilot-enterprise)
- [Context7 Documentation](https://context7.com)

For GitHub support: Contact your GitHub Enterprise Account Manager or support portal
