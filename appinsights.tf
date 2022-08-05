# Create log analytics workspace to place app insights into:
resource "azurerm_log_analytics_workspace" "log_workspace" {
  name                = "log-dmacme"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 365
}

# Create app insights instance for all DIH modules to log into:
resource "azurerm_application_insights" "appinsights" {
  name                = "appi-dmacme"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id        = azurerm_log_analytics_workspace.log_workspace.id
  application_type    = "web"
}
