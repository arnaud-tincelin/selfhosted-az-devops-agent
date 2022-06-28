terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.10.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1.1"
    }
  }
}
