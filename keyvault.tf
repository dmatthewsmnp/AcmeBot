# Create Key Vault resource:
resource "azurerm_key_vault" "kv" {
  name                      = "kv-dmacme"
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name
  sku_name                  = "standard"
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled  = false
  enable_rbac_authorization = true
}
resource "azurerm_role_assignment" "keyvault_admin" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}