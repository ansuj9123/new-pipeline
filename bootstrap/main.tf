data "azurerm_client_config" "current" {}
data "azuread_client_config" "aad" {}
data "azurerm_subscription" "current" {}

locals {
  name_prefix = "${var.project}-bootstrap"
  tf_rg = coalesce(var.tf_state_rg_name, "rg-${var.project}-tfstate")
  tf_sa = coalesce(var.tf_state_sa_name, "tf${replace(var.project, "-", "")}${random_string.sa_suffix.result}")
}

resource "random_string" "sa_suffix" {
  length = 8
  upper = false
  special = false
}

# State RG/SA/Container
resource "azurerm_resource_group" "tfstate" {
  name     = local.tf_rg
  location = var.location
  tags = { managed-by = "terraform", stack = "bootstrap" }
}

resource "azurerm_storage_account" "tfstate" {
  name                     = local.tf_sa
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags = { managed-by = "terraform", stack = "bootstrap" }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = var.tf_state_container
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

# Azure AD App + SP for GitHub OIDC
resource "azuread_application" "gh_oidc" {
  display_name = "gh-oidc-${var.project}"
}

resource "azuread_service_principal" "gh_oidc_sp" {
  client_id = azuread_application.gh_oidc.client_id
}

# Federated identity credential for GitHub OIDC
resource "azuread_federated_identity_credential" "repo_main" {
  application_object_id = azuread_application.gh_oidc.object_id
  display_name          = "github-${var.repo_owner}-${var.repo_name}-${var.repo_branch}"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = "https://token.actions.githubusercontent.com"
  subject               = "repo:${var.repo_owner}/${var.repo_name}:ref:refs/heads/${var.repo_branch}"
}

# Role assignments at subscription scope
data "azurerm_role_definition" "contributor" {
  name  = "Contributor"
  scope = data.azurerm_subscription.current.id
}

resource "azurerm_role_assignment" "ra_contrib" {
  scope              = data.azurerm_subscription.current.id
  role_definition_id = data.azurerm_role_definition.contributor.role_definition_id
  principal_id       = azuread_service_principal.gh_oidc_sp.object_id
}

data "azurerm_role_definition" "uaa" {
  name  = "User Access Administrator"
  scope = data.azurerm_subscription.current.id
}

resource "azurerm_role_assignment" "ra_uaa" {
  count             = var.grant_user_access_admin ? 1 : 0
  scope              = data.azurerm_subscription.current.id
  role_definition_id = data.azurerm_role_definition.uaa.role_definition_id
  principal_id       = azuread_service_principal.gh_oidc_sp.object_id
}
