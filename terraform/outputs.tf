output "logicapp" {
  value = can(local.active_scenarios.logicapp) ? {
    target_url   = "http://${azurerm_public_ip.target["logicapp_couchdb"].fqdn}:5984/}"
    relay_url    = azurerm_logic_app_trigger_http_request.http_relay[0].callback_url
    cdb_username = "admin"
    cdb_password = "admin"
  } : null
}

output "azurecloud" {
  value = can(local.active_scenarios.azurecloud) ? {
    target_url   = "http://${azurerm_public_ip.target["azurecloud_couchdb"].fqdn}:5984/}"
    cdb_username = "admin"
    cdb_password = "admin"
    ssh_command  = "ssh -i ${local_sensitive_file.attacker_vm_key["azurecloud_attack"].filename} ${azurerm_linux_virtual_machine.attacker["azurecloud_attack"].admin_username}@${azurerm_public_ip.attacker["azurecloud_attack"].fqdn}"
  } : null
}

output "sql" {
  sensitive = true
  value = can(local.active_scenarios.sql) ? {
    ssh_command  = "ssh -i ${local_sensitive_file.attacker_vm_key["sql_attack"].filename} ${azurerm_linux_virtual_machine.attacker["sql_attack"].admin_username}@${azurerm_public_ip.attacker["sql_attack"].fqdn}"
    sql_uri      = azurerm_mysql_flexible_server.target[0].fqdn
    sql_username = "sqladmin"
    sql_password = random_password.sqladmin_password[0].result
    sql_cmd      = "mysql --host=${azurerm_mysql_flexible_server.target[0].fqdn} --user=sqladmin --password=${random_password.sqladmin_password[0].result} --ssl"
  } : null
}

output "devops" {
  value = can(local.active_scenarios.devops) ? {
    attacker_ado_url    = jsondecode(data.azapi_resource.attacker_devops[0].output).properties.AccountURL
    github_url = "https://${azurerm_public_ip.target["devops_github"].fqdn}/"
    proxy_cmd  = "ssh -N -D 8080 -i ${local_sensitive_file.target_vm_key["general_bastion"].filename} ${azurerm_linux_virtual_machine.target["general_bastion"].admin_username}@${azurerm_public_ip.target["general_bastion"].fqdn}"
    proxy_host = "127.0.0.1"
    proxy_port = "8080"
  } : null
}
