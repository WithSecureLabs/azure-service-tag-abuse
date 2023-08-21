resource "azurerm_network_watcher" "target" {
  provider = azurerm.target

  name                = join("", [local.target_prefix, local.lab_id, local.resource_name.network_watcher])
  location            = azurerm_resource_group.target.location
  resource_group_name = azurerm_resource_group.target.name
}

resource "azurerm_virtual_network" "target" {
  provider = azurerm.target

  name                = join("", [local.target_prefix, local.lab_id, local.resource_name.vnet])
  address_space       = [local.target_network_space]
  location            = azurerm_resource_group.target.location
  resource_group_name = azurerm_resource_group.target.name

  depends_on = [azurerm_network_watcher.target]
}

resource "azurerm_subnet" "target" {
  for_each = { for k, v in local.active_scenarios : k => v if can(v.target.subnet) }
  provider = azurerm.target

  name                 = join("", [local.target_prefix, each.value.shortname, local.lab_id, "default", local.resource_name.subnet])
  virtual_network_name = azurerm_virtual_network.target.name
  address_prefixes     = [each.value.target.subnet]
  resource_group_name  = azurerm_resource_group.target.name
}

resource "azurerm_network_security_group" "target" {
  for_each = azurerm_subnet.target
  provider = azurerm.target

  name                = join("", [each.value.name, local.resource_name.network_security_group])
  location            = azurerm_resource_group.target.location
  resource_group_name = azurerm_resource_group.target.name
}

resource "azurerm_network_security_rule" "target_bastion" {
  for_each = merge([
    for vk, vm in local.target_virtual_machines : {
      for pi, port in vm.bastion_ports : join("_", [vk, pi]) => {
        scenario = vm.scenario
        port     = port
      }
    } if vm.bastion_ports != null
  ]...)
  provider = azurerm.target

  name                        = "bastion${each.key}"
  priority                    = sum([100, each.value.port])
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = each.value.port
  source_address_prefix       = azurerm_subnet.target["general"].address_prefixes[0]
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.target.name
  network_security_group_name = azurerm_network_security_group.target[each.value.scenario].name
}

resource "azurerm_network_security_rule" "target_me" {
  for_each = merge([
    for vk, vm in local.target_virtual_machines : {
      for pi, port in vm.me_ports : join("_", [vk, pi]) => {
        vk   = vk
        port = port
      }
    } if vm.me_ports != null
  ]...)
  provider = azurerm.target

  name                        = "myip_inbound"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = each.value.port
  source_address_prefix       = chomp(data.http.myip.body)
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.target.name
  network_security_group_name = azurerm_network_security_group.target_vm_external[each.value.vk].name
}

resource "azurerm_network_security_rule" "service_tag_inbound" {
  for_each = merge([
    for vk, vm in local.target_virtual_machines : {
      for ti, tag in vm.service_tags : join("_", [vk, ti]) => {
        vk  = vk
        tag = tag
      }
    } if vm.service_tags != null
  ]...)
  provider = azurerm.target

  name                        = "${each.value.tag}_inbound"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = each.value.tag
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.target.name
  network_security_group_name = azurerm_network_security_group.target_vm_external[each.value.vk].name
}

resource "azurerm_network_security_rule" "target_vm_debug" {
  for_each = var.debug ? local.target_virtual_machines : null
  provider = azurerm.target

  name                        = "debug"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = chomp(data.http.myip.body)
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.target_vm_external[each.key].resource_group_name
  network_security_group_name = azurerm_network_security_group.target_vm_external[each.key].name
}

resource "azurerm_network_security_rule" "target_vm_public" {
  # needs to fix (only does one port)
  for_each = { for vk, vm in local.target_virtual_machines : vk => vm if vm.public_ports != null }
  provider = azurerm.target

  name                        = "public_in"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = each.value.public_ports[0]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.target_vm_external[each.key].resource_group_name
  network_security_group_name = azurerm_network_security_group.target_vm_external[each.key].name
}

resource "azurerm_network_security_rule" "target_vm_bastion" {
  # needs to fix (only does one port)
  for_each = { for vk, vm in local.target_virtual_machines : vk => vm if vm.bastion_ports != null }
  provider = azurerm.target

  name                        = "bastion_in"
  priority                    = 400
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = azurerm_linux_virtual_machine.target["general_bastion"].public_ip_address
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.target_vm_external[each.key].resource_group_name
  network_security_group_name = azurerm_network_security_group.target_vm_external[each.key].name
}
