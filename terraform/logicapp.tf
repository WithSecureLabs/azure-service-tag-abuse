resource "azurerm_logic_app_workflow" "http_relay" {
  count    = can(local.active_scenarios.logicapp) ? 1 : 0
  provider = azurerm.attacker

  name                = join("", [local.attacker_prefix, local.active_scenarios.logicapp.shortname, local.lab_id, local.resource_name.logic_app])
  location            = azurerm_resource_group.attacker.location
  resource_group_name = azurerm_resource_group.attacker.name
}

data "local_file" "logic_app_definitions" {
  for_each = {
    parse_query_params          = "${local.assets_dir}/logicapp/logicapp/parse_query_params_action.json"
    parse_connection_properties = "${local.assets_dir}/logicapp/logicapp/parse_connection_properties_action.json"
    fix_authorization_header = "${local.assets_dir}/logicapp/logicapp/fix_authorization_header_action.json"
    cleanup_headers             = "${local.assets_dir}/logicapp/logicapp/cleanup_headers_action.json"
    call_api                    = "${local.assets_dir}/logicapp/logicapp/call_api_action.json"
    return_api_response         = "${local.assets_dir}/logicapp/logicapp/return_api_response_action.json"
  }

  filename = each.value
}

resource "azurerm_logic_app_trigger_http_request" "http_relay" {
  count        = can(local.active_scenarios.logicapp) ? 1 : 0
  provider = azurerm.attacker

  name         = "HTTP-Trigger"
  logic_app_id = azurerm_logic_app_workflow.http_relay[0].id
  schema       = "{}"
}

resource "azurerm_logic_app_action_custom" "parse_query_params" {
  count = can(local.active_scenarios.logicapp) ? 1 : 0
  provider = azurerm.attacker

  name         = "parse_query_params"
  logic_app_id = azurerm_logic_app_workflow.http_relay[0].id
  body         = data.local_file.logic_app_definitions["parse_query_params"].content

  depends_on = [ azurerm_logic_app_trigger_http_request.http_relay ]
}

resource "azurerm_logic_app_action_custom" "parse_connection_properties" {
  count = can(local.active_scenarios.logicapp) ? 1 : 0
  provider = azurerm.attacker

  name         = "parse_connection_properties"
  logic_app_id = azurerm_logic_app_workflow.http_relay[0].id
  body         = data.local_file.logic_app_definitions["parse_connection_properties"].content

  depends_on = [ azurerm_logic_app_action_custom.parse_query_params ]
}

resource "azurerm_logic_app_action_custom" "fix_authorization_header" {
  count = can(local.active_scenarios.logicapp) ? 1 : 0
  provider = azurerm.attacker

  name         = "fix_authorization_header"
  logic_app_id = azurerm_logic_app_workflow.http_relay[0].id
  body         = data.local_file.logic_app_definitions["fix_authorization_header"].content

  depends_on = [ azurerm_logic_app_action_custom.parse_connection_properties ]
}

resource "azurerm_logic_app_action_custom" "cleanup_headers" {
  count = can(local.active_scenarios.logicapp) ? 1 : 0
  provider = azurerm.attacker

  name         = "cleanup_headers"
  logic_app_id = azurerm_logic_app_workflow.http_relay[0].id
  body         = data.local_file.logic_app_definitions["cleanup_headers"].content

  depends_on = [ azurerm_logic_app_action_custom.fix_authorization_header ]
}

resource "azurerm_logic_app_action_custom" "call_api" {
  count = can(local.active_scenarios.logicapp) ? 1 : 0
  provider = azurerm.attacker

  name         = "call_target_api"
  logic_app_id = azurerm_logic_app_workflow.http_relay[0].id
  body         = data.local_file.logic_app_definitions["call_api"].content

  depends_on = [ azurerm_logic_app_action_custom.cleanup_headers ]
}

resource "azurerm_logic_app_action_custom" "return_api_response" {
  count = can(local.active_scenarios.logicapp) ? 1 : 0
  provider = azurerm.attacker

  name         = "return_api_response"
  logic_app_id = azurerm_logic_app_workflow.http_relay[0].id
  body         = data.local_file.logic_app_definitions["return_api_response"].content

  depends_on = [ azurerm_logic_app_action_custom.call_api ]
}
