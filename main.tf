# Set up required providers and backend
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.16.0"
    }
  }
  required_version = ">= 1.2.2"
}
provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = "DM-AcmeBot-PoC"
  location = "Canada Central"
  tags     = var.tags
}
