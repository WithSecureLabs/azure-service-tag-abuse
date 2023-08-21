resource "azurerm_network_watcher" "attacker" {
  provider            = azurerm.attacker
  
  name                = join("", [local.attacker_prefix, local.lab_id, local.resource_name.network_watcher])
  location            = azurerm_resource_group.attacker.location
  resource_group_name = azurerm_resource_group.attacker.name
}

resource "azurerm_virtual_network" "attacker" {
  provider            = azurerm.attacker

  name                = join("", [local.attacker_prefix, local.lab_id, local.resource_name.vnet])
  address_space       = [local.attacker_network_space]
  location            = azurerm_resource_group.attacker.location
  resource_group_name = azurerm_resource_group.attacker.name

  depends_on = [azurerm_network_watcher.attacker]
}

resource "azurerm_subnet" "attacker" {
  for_each = { for k, v in local.active_scenarios : k => v if can(v.attacker.subnet) }
  provider = azurerm.attacker

  name                 = join("", [local.attacker_prefix, each.value.shortname, local.lab_id, "default", local.resource_name.subnet])
  virtual_network_name = azurerm_virtual_network.attacker.name
  address_prefixes     = [each.value.attacker.subnet]
  resource_group_name  = azurerm_resource_group.attacker.name
}

resource "azurerm_network_security_group" "attacker" {
  for_each = azurerm_subnet.attacker
  provider = azurerm.attacker

  name                = join("", [each.value.name, local.resource_name.network_security_group])
  location            = azurerm_resource_group.attacker.location
  resource_group_name = azurerm_resource_group.attacker.name
}

resource "azurerm_network_security_rule" "attacker_me" {
  for_each = merge([
    for vk, vm in local.attacker_virtual_machines : {
      for pi, port in vm.me_ports : join("_", [vk, pi]) => {
        vk   = vk
        port = port
      }
    } if vm.me_ports != null
  ]...)
  provider = azurerm.attacker

  name                        = "myip_inbound"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = each.value.port
  source_address_prefix       = chomp(data.http.myip.body)
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.attacker.name
  network_security_group_name = azurerm_network_security_group.attacker_vm_external[each.value.vk].name
}

resource "azurerm_network_security_rule" "attacker_vm_debug" {
  for_each = var.debug ? local.attacker_virtual_machines : {}
  provider = azurerm.attacker

  name                        = "debug"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = chomp(data.http.myip.body)
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.attacker_vm_external[each.key].resource_group_name
  network_security_group_name = azurerm_network_security_group.attacker_vm_external[each.key].name
}

resource "azurerm_network_security_rule" "attacker_vm_public" {
  # needs to fix (only does one port)
  for_each = { for vk, vm in local.attacker_virtual_machines : vk => vm if vm.public_ports != null }
  provider = azurerm.attacker

  name                        = "public_in"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = each.value.public_ports[0]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.attacker_vm_external[each.key].resource_group_name
  network_security_group_name = azurerm_network_security_group.attacker_vm_external[each.key].name
}
