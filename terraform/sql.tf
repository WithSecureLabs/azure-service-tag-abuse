resource "random_password" "sqladmin_password" {
  count   = can(local.active_scenarios.azservices) ? 1 : 0
  length  = 8
}

resource "azurerm_mysql_flexible_server" "target" {
  count    = can(local.active_scenarios.azservices) ? 1 : 0
  provider = azurerm.target

  name                   = join("", [local.target_prefix, local.active_scenarios.azservices.shortname, local.lab_id, local.resource_name.sql])
  resource_group_name    = azurerm_resource_group.target.name
  location               = azurerm_resource_group.target.location
  administrator_login    = "sqladmin"
  administrator_password = random_password.sqladmin_password[0].result
  backup_retention_days  = 7
  sku_name               = "B_Standard_B1s"
  zone                   = "1"
}

resource "azurerm_mysql_flexible_database" "target" {
  count    = can(local.active_scenarios.azservices) ? 1 : 0

  name                = "exampledb"
  resource_group_name = azurerm_resource_group.target.name
  server_name         = azurerm_mysql_flexible_server.target[0].name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

# https://learn.microsoft.com/en-gb/rest/api/sql/2022-08-01-preview/firewall-rules/create-or-update?tabs=HTTP#request-body

resource "azurerm_mysql_flexible_server_firewall_rule" "target" {
  count    = can(local.active_scenarios.azservices) ? 1 : 0
  provider = azurerm.target

  name                = "azc"
  resource_group_name = azurerm_resource_group.target.name
  server_name         = azurerm_mysql_flexible_server.target[0].name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}
