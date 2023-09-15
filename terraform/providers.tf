

terraform {
  backend "azurerm" {
      resource_group_name  = "Utilities-DevOps"
      storage_account_name = "terraformstoragedevops"
      container_name       = "statefilespoc"
      key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  skip_provider_registration = true

  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }


}
# if you dont want aws provider to be installed comment the below section

provider "aws" {
  region = "us-east-1"
}
