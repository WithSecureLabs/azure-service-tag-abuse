resource "azuredevops_project" "target" {
  name        = "Target Project"
  visibility  = "private"
  description = "Target Project"
  features = {
    "testplans"    = "disabled"
    "artifacts"    = "disabled"
    "boards"       = "disabled"
    "repositories" = "disabled"
  }
}

resource "azuredevops_agent_pool" "target" {
  name           = var.ado_pool
  auto_provision = false
  auto_update    = true
}

resource "azuredevops_agent_queue" "target" {
  project_id    = azuredevops_project.target.id
  agent_pool_id = azuredevops_agent_pool.target.id
}

resource "azuredevops_pipeline_authorization" "target" {
  project_id  = azuredevops_project.target.id
  resource_id = azuredevops_agent_queue.target.id
  type        = "queue"
}

resource "azuredevops_serviceendpoint_github_enterprise" "target" {
  project_id            = azuredevops_project.target.id
  service_endpoint_name = "GitHub Enterprise Server"
  url                   = var.gh_url

  auth_personal {
    personal_access_token = local.ado_pat
  }
}
