output "client_id" { value = azuread_application.gh_oidc.client_id }
output "tenant_id" { value = data.azurerm_client_config.current.tenant_id }
output "subscription_id" { value = data.azurerm_subscription.current.subscription_id }

output "tf_state_rg" { value = azurerm_resource_group.tfstate.name }
output "tf_state_sa" { value = azurerm_storage_account.tfstate.name }
output "tf_state_container" { value = azurerm_storage_container.tfstate.name }
output "tf_state_key" { value = var.tf_state_key }

output "github_oidc_subject" {
  value = azuread_federated_identity_credential.repo_main.subject
  description = "Use this subject in diagnostics if needed"
}
