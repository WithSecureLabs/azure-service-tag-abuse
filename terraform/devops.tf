resource "azurerm_resource_group_template_deployment" "target_devops" {
  count               = can(local.active_scenarios.devops) ? 1 : 0
  provider            = azurerm.target

  name                = join("", [local.target_prefix, local.active_scenarios.devops.shortname, local.lab_id, local.resource_name.ado_org])
  resource_group_name = azurerm_resource_group.target.name
  deployment_mode     = "Incremental"
  template_content    = file(local.devops_org_template)
  parameters_content = jsonencode({
    "accountName" = {
      value = join("", [local.target_prefix, local.active_scenarios.devops.shortname, local.lab_id, local.resource_name.ado_org])
    }
  })
}

resource "azurerm_resource_group_template_deployment" "attacker_devops" {
  count               = can(local.active_scenarios.devops) ? 1 : 0
  provider            = azurerm.attacker

  name                = join("", [local.attacker_prefix, local.active_scenarios.devops.shortname, local.lab_id, local.resource_name.ado_org])
  resource_group_name = azurerm_resource_group.attacker.name
  deployment_mode     = "Incremental"
  template_content    = file(local.devops_org_template)
  parameters_content = jsonencode({
    "accountName" = {
      value = join("", [local.attacker_prefix, local.active_scenarios.devops.shortname, local.lab_id, local.resource_name.ado_org])
    }
  })
}

data "azapi_resource" "target_devops" {
  count     = can(local.active_scenarios.devops) ? 1 : 0
  name      = join("", [local.target_prefix, local.active_scenarios.devops.shortname, local.lab_id, local.resource_name.ado_org])

  parent_id = azurerm_resource_group.target.id
  type      = "microsoft.visualstudio/account@2014-04-01-preview"

  response_export_values = ["properties.AccountURL"]
  depends_on             = [azurerm_resource_group_template_deployment.target_devops]
}

resource "null_resource" "devops_pat" {
  for_each = can(local.active_scenarios.devops) ? local.scenarios.devops.target.pats : {}

  provisioner "local-exec" {
    command     = "${local.get_pat_script} ${data.azapi_resource.target_devops[0].name} ${each.key} '${join(" ", each.value.scopes)}' ${local.keys_dir}/${each.key}_pat"
    interpreter = ["bash", "-c"]
  }
}

resource "local_file" "devops_terraform" {
  for_each        = can(local.active_scenarios.devops) ? fileset("${local.assets_dir}/devops/gen_tf/", "**") : []

  content         = file("${local.assets_dir}/devops/gen_tf/${each.value}")
  filename        = "${local.generated_dir}/devops/terraform/${each.value}"
  file_permission = "0600"
}

resource "local_file" "github_config" {
  count = can(local.active_scenarios.devops) ? 1 : 0

  content = templatefile(
    "${local.assets_dir}/devops/gh_config.json.tftpl",
    {
      gh_host = "${azurerm_public_ip.target["devops_github"].fqdn}"
    }
  )
  filename        = "${local.generated_dir}/devops/gh_config.json"
  file_permission = "0600"
}

resource "local_sensitive_file" "devops_vars" {
  count = can(local.active_scenarios.devops) ? 1 : 0

  content = templatefile(
    "${local.assets_dir}/devops/devops.auto.tfvars.tftpl",
    {
      ado_url      = jsondecode(data.azapi_resource.target_devops[0].output).properties.AccountURL,
      ado_pat_file = "${local.keys_dir}/provisioning_pat"
      ado_pool     = local.scenarios.devops.target.agent_pool
      gh_url       = "https://${azurerm_public_ip.target["devops_github"].fqdn}/"
    }
  )
  filename        = "${local.generated_dir}/devops/terraform/devops.auto.tfvars"
  file_permission = "0600"
}

resource "ansible_group" "adorunner" {
  count = can(local.active_scenarios.devops) ? 1 : 0

  name  = "adorunner"
  variables = {
    ado_pat_file = "${local.keys_dir}/ado_runner_pat"
    ado_url      = jsondecode(data.azapi_resource.target_devops[0].output).properties.AccountURL
    runner_pool  = "agent-pool"
  }
}

resource "azurerm_network_security_rule" "target_devops_runner" {
  provider            = azurerm.target
  count = can(local.active_scenarios.devops) ? 1 : 0

  # needs to fix (only does one port)
  name                        = "runner_in"
  priority                    = 500
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = azurerm_linux_virtual_machine.target["devops_runner"].public_ip_address
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.target_vm_external["devops_github"].resource_group_name
  network_security_group_name = azurerm_network_security_group.target_vm_external["devops_github"].name
}
