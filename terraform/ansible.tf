resource "ansible_host" "target" {
  for_each = local.target_virtual_machines

  name   = azurerm_linux_virtual_machine.target[each.key].name
  groups = concat(each.value.ansible_groups, each.value.scenario != "general" ? ["private"] : [])
  variables = merge({
    ansible_ssh_host = azurerm_linux_virtual_machine.target[each.key].public_ip_address

    ansible_ssh_private_key_file  = local_sensitive_file.target_vm_key[each.key].filename
    ansible_ssh_user              = azurerm_linux_virtual_machine.target[each.key].admin_username
    ansible_ssh_host_key_checking = false
    ansible_ssh_port              = each.value.ansible_ssh_port
    asset_dir                     = "${local.assets_dir}/${each.value.scenario}"
  }, each.value.ansible_vars)
}

resource "ansible_group" "target_private" {
  name = "private"
  variables = {
    ansible_ssh_common_args = "-o ProxyCommand=\"ssh -oStrictHostKeyChecking=no -i ${abspath(local_sensitive_file.target_vm_key["general_bastion"].filename)} -W %h:%p -q ${azurerm_linux_virtual_machine.target["general_bastion"].admin_username}@${azurerm_linux_virtual_machine.target["general_bastion"].public_ip_address}\""
  }
}

resource "ansible_host" "attacker" {
  for_each = local.attacker_virtual_machines

  name   = azurerm_linux_virtual_machine.attacker[each.key].name
  groups = each.value.ansible_groups
  variables = merge({
    ansible_ssh_host = azurerm_linux_virtual_machine.attacker[each.key].public_ip_address

    ansible_ssh_private_key_file  = local_sensitive_file.attacker_vm_key[each.key].filename
    ansible_ssh_user              = azurerm_linux_virtual_machine.attacker[each.key].admin_username
    ansible_ssh_host_key_checking = false
    ansible_ssh_port              = each.value.ansible_ssh_port
    asset_dir                     = "${local.assets_dir}/${each.value.scenario}"
  }, each.value.ansible_vars)
}
