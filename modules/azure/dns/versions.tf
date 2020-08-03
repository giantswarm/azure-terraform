terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # a features block must be defined, even if it is empty
      features {}
    }
  }
  required_version = ">= 0.13"
}
