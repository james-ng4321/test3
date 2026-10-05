terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.62.0"
    }
  }

  backend "remote" {
    organization = "Chinachemgroup" # org name from step 2.
    workspaces {
      name = "pssrev-azure-tf-uat" # name for your app's state.
    }
  }
}

provider "azurerm" {
  features {}
  // Set this to true as we are using OIDC
  //
  # use_oidc = true
  # alias  = "main"

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  # client_id         = var.client_id
  # client_secret     = var.client_secret
}
