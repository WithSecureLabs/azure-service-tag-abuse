resource "tls_private_key" "target_vm" {
  for_each = local.target_virtual_machines

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "target_vm_key" {
  for_each = local.target_virtual_machines

  content         = tls_private_key.target_vm[each.key].private_key_openssh
  filename        = "${local.keys_dir}/${azurerm_linux_virtual_machine.target[each.key].name}_rsa"
  file_permission = 0400
}

resource "tls_private_key" "attacker_vm" {
  for_each = local.attacker_virtual_machines

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "attacker_vm_key" {
  for_each = local.attacker_virtual_machines

  content         = tls_private_key.attacker_vm[each.key].private_key_openssh
  filename        = "${local.keys_dir}/${azurerm_linux_virtual_machine.attacker[each.key].name}_rsa"
  file_permission = 0400
}
