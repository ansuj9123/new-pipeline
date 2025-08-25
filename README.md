# Azure Sandpit — **Everything via Terraform** (Bootstrap + Env) + GitHub OIDC + Key Vault

This repo lets you do everything **through Terraform**:

1) **Bootstrap stack** (`bootstrap/`) — run locally once with your own Azure creds (e.g., `az login`):
   - Creates **tfstate** Resource Group + Storage Account + Blob container
   - Creates **Azure AD App** + **Service Principal**
   - Adds a **Federated Identity Credential** for your GitHub repo/branch (OIDC)
   - Assigns **Contributor** (+ optional **User Access Administrator**) at subscription scope

2) **Env stack** (`env/`) — uses the remote backend you just created:
   - Provisions a simple sandpit: **Resource Group**, **VNet+Subnet**, **NSG**, **Storage Account**, **Key Vault (RBAC)**

3) **GitHub Actions** (`.github/workflows/terraform.yml`) — uses **OIDC** (no client secret) to run `terraform init/plan/apply` on `env/`.

> Why two stacks? The backend and identity must exist **before** we can use them. Terraforming them first (bootstrap) solves the chicken-and-egg, still keeping everything IaC.

---

## Quick start

### 0) Prereqs
- Azure CLI (`az`) and permissions to create App/SP + assign roles (subscription-level)  
- Terraform v1.6+
- A GitHub repo (owner/name) where you will push this code

### 1) Run **bootstrap** locally
```bash
cd bootstrap
terraform init
terraform apply -auto-approve   -var="project=demo"   -var="location=westeurope"   -var="repo_owner=YOUR_GH_OWNER"   -var="repo_name=YOUR_REPO"   -var="repo_branch=main"
```
> You must be authenticated to Azure (e.g., `az login`) before running.

**Outputs** will include:
- `client_id` (AZURE_CLIENT_ID)
- `tenant_id` (AZURE_TENANT_ID)
- `subscription_id` (AZURE_SUBSCRIPTION_ID)
- `tf_state_rg`, `tf_state_sa`, `tf_state_container`, `tf_state_key`

### 2) Add **GitHub Variables** (Settings → Secrets and variables → Variables)
Add the following **Variables** (not secrets):
- `AZURE_SUBSCRIPTION_ID` = from bootstrap output
- `AZURE_TENANT_ID` = from bootstrap output
- `AZURE_CLIENT_ID` = from bootstrap output
- `TF_STATE_RG` = from bootstrap output
- `TF_STATE_SA` = from bootstrap output
- `TF_STATE_CONTAINER` = from bootstrap output
- `TF_STATE_KEY` = from bootstrap output
- `TF_VAR_project` = e.g., `demo`
- `TF_VAR_environment` = `dev`
- `TF_VAR_location` = e.g., `westeurope`

### 3) Push to GitHub
Commit and push this repo to `main`. The included workflow will:
- Log in via **OIDC**
- Init Terraform **remote backend** using your tfstate storage
- Plan/Apply the **env** stack

### 4) Customize
- Edit `env/environments/dev.tfvars` for address space, subnet, tags, etc.
- Add more resources (AKS, ACR, App Service, etc.) to `env/main.tf` or modules.

---

## Notes
- The Key Vault is **RBAC-enabled**. Give your workflow identity the role **Key Vault Secrets User** (subscription/RG/vault scope) if you want TF to read secrets at plan/apply time.
- Avoid storing real secrets as `azurerm_key_vault_secret` values managed by TF unless you understand the risk that secret values can end up in TF state.
