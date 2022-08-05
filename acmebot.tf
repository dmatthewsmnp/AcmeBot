locals {
  funcapp_name = "funcapp-acmebot-${substr(var.env, 0, 4)}01"
  allowed_ips  = [for entry in var.allowed_ips : length(regexall("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$", entry)) > 0 ? "${entry}/32" : entry]
}

resource "azurerm_storage_account" "acme_storage" {
  name                     = replace(local.funcapp_name, "-", "")
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = merge(var.tags, { "WhatIsThis" = "Storage account for function app ${local.funcapp_name}" })

  # Security settings:
  enable_https_traffic_only       = true
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"
}

resource "azurerm_service_plan" "acme_plan" {
  name                = "plan-funcapp-acmebot-${substr(var.env, 0, 4)}01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Windows"
  sku_name            = "Y1"
  tags                = merge(var.tags, { "WhatIsThis" = "Consumption plan for ${local.funcapp_name}" })
}

resource "azurerm_windows_function_app" "acme_funcapp" {
  name                        = local.funcapp_name
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  service_plan_id             = azurerm_service_plan.acme_plan.id
  storage_account_name        = azurerm_storage_account.acme_storage.name
  storage_account_access_key  = azurerm_storage_account.acme_storage.primary_access_key
  functions_extension_version = "~4"
  https_only                  = true
  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"        = "https://stacmebotprod.blob.core.windows.net/keyvault-acmebot/v4/latest.zip"
    "WEBSITE_TIME_ZONE"               = "UTC"
    "Acmebot:Contacts"                = "darryl.matthews@mnp.ca"
    "Acmebot:Endpoint"                = "https://acme-v02.api.letsencrypt.org/"
    "Acmebot:VaultBaseUrl"            = azurerm_key_vault.kv.vault_uri
    "Acmebot:Environment"             = "AzureCloud"
    "Acmebot:MitigateChainOrder"      = false
    "Acmebot:AzureDns:SubscriptionId" = data.azurerm_client_config.current.subscription_id
  }

  site_config {
    application_insights_connection_string = azurerm_application_insights.appinsights.connection_string
    application_insights_key               = azurerm_application_insights.appinsights.instrumentation_key
    ftps_state                             = "Disabled"
    minimum_tls_version                    = "1.2"

    application_stack {
      dotnet_version = "6"
    }

    dynamic "ip_restriction" {
      for_each = local.allowed_ips
      content {
        name       = ip_restriction.value
        ip_address = ip_restriction.value
        action     = "Allow"
        headers    = []
      }
    }
  }
}

data "azurerm_dns_zone" "environment_dns" {
  name                = "dev.mnp.ca"
  resource_group_name = "Shared-Services"
}
resource "azurerm_role_assignment" "funcapp_dns" {
  scope                = data.azurerm_dns_zone.environment_dns.id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azurerm_windows_function_app.acme_funcapp.identity[0].principal_id
}
resource "azurerm_role_assignment" "funcapp_kv" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = azurerm_windows_function_app.acme_funcapp.identity[0].principal_id
}

resource "azurerm_dns_a_record" "darryl" {
  name                = "darryl"
  zone_name           = data.azurerm_dns_zone.environment_dns.name
  resource_group_name = data.azurerm_dns_zone.environment_dns.resource_group_name
  ttl                 = 3600
  records             = ["127.0.0.1"]
}
