## Virtual Machine

resource "azurerm_linux_virtual_machine" "target" {
  for_each = local.target_virtual_machines
  provider = azurerm.target

  name                = each.value.name
  location            = azurerm_resource_group.target.location
  resource_group_name = azurerm_resource_group.target.name
  size                = each.value.size != null ? each.value.size : var.default_vm_size
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.target_vm[each.key].id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.target_vm[each.key].public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = each.value.image.publisher
    offer     = each.value.image.offer
    sku       = each.value.image.sku
    version   = each.value.image.version
  }

  custom_data = each.value.custom_data

  dynamic "plan" {
    for_each = each.value.plan != null ? [each.value.plan] : []
    content {
      name      = azurerm_marketplace_agreement.target["${each.value.plan.publisher}_${each.value.plan.product}_${each.value.plan.name}"].plan
      product   = plan.value["product"]
      publisher = plan.value["publisher"]
    }
  }

  depends_on = [
    azurerm_network_security_rule.target_bastion,
    azurerm_network_security_rule.target_me
  ]
}

resource "azurerm_public_ip" "target" {
  for_each = local.target_virtual_machines
  provider = azurerm.target

  name                = "${each.value.name}${local.resource_name.public_ip}"
  location            = azurerm_resource_group.target.location
  resource_group_name = azurerm_resource_group.target.name
  allocation_method   = "Static"
  domain_name_label   = each.value.name
}

resource "azurerm_network_interface" "target_vm" {
  for_each = local.target_virtual_machines
  provider = azurerm.target

  name                = "${each.value.name}${local.resource_name.nic}"
  location            = azurerm_resource_group.target.location
  resource_group_name = azurerm_resource_group.target.name

  ip_configuration {
    name                          = "external"
    subnet_id                     = azurerm_subnet.target[each.value.scenario].id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.ip_address
    public_ip_address_id          = azurerm_public_ip.target[each.key].id
  }
}

## Network Interface

resource "azurerm_network_security_group" "target_vm_external" {
  for_each = local.target_virtual_machines
  provider = azurerm.target

  name                = join("", [local.target_prefix, local.active_scenarios[each.value.scenario].shortname, local.lab_id, each.key, local.resource_name.network_security_group])
  location            = azurerm_resource_group.target.location
  resource_group_name = azurerm_resource_group.target.name
}

resource "azurerm_network_interface_security_group_association" "target_vm_external_nic" {
  for_each = local.target_virtual_machines
  provider = azurerm.target

  network_interface_id      = azurerm_network_interface.target_vm[each.key].id
  network_security_group_id = azurerm_network_security_group.target_vm_external[each.key].id
}

## Data Disk

resource "azurerm_managed_disk" "target_data" {
  for_each = { for vk, vm in local.target_virtual_machines : vk => vm if vm.data_disk != null }
  provider = azurerm.target

  name                 = "${each.value.name}${local.resource_name.disk}"
  location             = azurerm_resource_group.target.location
  resource_group_name  = azurerm_resource_group.target.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = each.value.data_disk
}

resource "azurerm_virtual_machine_data_disk_attachment" "target_data" {
  for_each = { for vk, vm in local.target_virtual_machines : vk => vm if vm.data_disk != null }
  provider = azurerm.target

  managed_disk_id    = azurerm_managed_disk.target_data[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.target[each.key].id
  lun                = "0"
  caching            = "ReadWrite"
}
