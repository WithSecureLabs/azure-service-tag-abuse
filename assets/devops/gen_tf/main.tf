terraform {
  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">=0.1.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

locals {
  ado_pat = jsondecode(file(var.ado_pat_file)).token
}

provider "azuredevops" {
  org_service_url       = var.ado_url
  personal_access_token = local.ado_pat
}
