resource "azurerm_resource_group" "target" {
  provider = azurerm.target
  name     = join("", [local.target_prefix, local.lab_id, local.resource_name.resource_group])
  location = var.location
}

resource "azurerm_resource_group" "attacker" {
  provider = azurerm.attacker
  name     = join("", [local.attacker_prefix, local.lab_id, local.resource_name.resource_group])
  location = var.location
}
