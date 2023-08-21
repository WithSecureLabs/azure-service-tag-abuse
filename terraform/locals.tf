locals {
  assets_dir             = abspath("${path.module}/../assets")
  generated_dir          = abspath("${path.module}/../generated")
  keys_dir               = abspath("${path.module}/../keys")
  devops_org_template    = "${local.assets_dir}/devops/org_template.json"
  attacker_prefix        = "${var.prefix}atk"
  target_prefix          = "${var.prefix}tgt"
  lab_id                 = random_string.lab_id.result
  couchdb_config         = "${local.assets_dir}/logicapp/couchdb_data"
  target_network_space   = "10.128.0.0/16"
  attacker_network_space = "10.127.0.0/16"
  get_pat_script         = "${local.assets_dir}/devops/get_devops_pat.sh"
  ansible_playbook       = abspath("${path.module}/../ansible/playbook.yml")
  scenarios = {
    logicapp = {
      shortname = "la"
      target = {
        subnet = "10.128.10.0/24"
        virtual_machines = [{
          label      = "couchdb"
          ip_address = "10.128.10.4"
          image = {
            publisher = "debian"
            offer     = "debian-11"
            sku       = "11"
            version   = "latest"
          }
          size           = "Standard_B2ms"
          bastion_ports  = ["22"]
          ansible_groups = ["couchdb"]
          service_tags   = ["LogicApps"]
        }]
      }
    }
    devops = {
      shortname = "ado"
      target = {
        subnet     = "10.128.11.0/24"
        agent_pool = "agent-pool"
        pats = {
          ado_runner = {
            scopes = ["vso.agentpools_manage", "vso.machinegroup_manage"]
          }
          provisioning = {
            scopes = ["app_token"]
          }
        }
        virtual_machines = [
          {
            label      = "github"
            ip_address = "10.128.11.4"
            image = {
              publisher = "github"
              offer     = "github-enterprise"
              sku       = "github-enterprise"
              version   = "latest"
            }
            size             = "Standard_E4as_v4"
            data_disk        = 170
            ansible_ssh_port = 122
            bastion_ports    = ["122"]
            ansible_groups   = ["github"]
            public_ports     = ["80"]
            service_tags     = ["AzureDevOps"]
            ansible_vars = {
              gh_settings_file = "${path.module}/../generated/devops/gh_config.json"
            }
          },
          {
            label      = "runner"
            ip_address = "10.128.11.5"
            image = {
              publisher = "debian"
              offer     = "debian-11"
              sku       = "11"
              version   = "latest"
            }
            size            = "Standard_B2ms"
            ansible_groups  = ["adorunner"]
            ansible_autorun = false
            ansible_vars = {
              ado_pat_file = "${local.keys_dir}/ado_runner_pat"
            }
            bastion_ports = ["22"]
          }
        ]
      }
    }
    general = {
      shortname = "general"
      target = {
        subnet = "10.128.12.0/24"
        virtual_machines = [{
          label      = "bastion"
          ip_address = "10.128.12.4"
          image = {
            publisher = "debian"
            offer     = "debian-11"
            sku       = "11"
            version   = "latest"
          }
          size            = "Standard_B2ms"
          me_ports        = ["22"]
          ansible_autorun = false
        }]
      }
    }
    azurecloud = {
      shortname = "azc"
      target = {
        subnet = "10.128.13.0/24"
        virtual_machines = [{
          label      = "couchdb"
          ip_address = "10.128.13.4"
          image = {
            publisher = "debian"
            offer     = "debian-11"
            sku       = "11"
            version   = "latest"
          }
          size           = "Standard_B2ms"
          bastion_ports  = ["22"]
          ansible_groups = ["couchdb"]
          service_tags   = ["AzureCloud"]
        }]
      }
      attacker = {
        subnet = "10.127.13.0/24"
        virtual_machines = [
          {
            label      = "attack"
            ip_address = "10.127.13.4"
            image = {
              publisher = "debian"
              offer     = "debian-11"
              sku       = "11"
              version   = "latest"
            }
            size     = "Standard_B2ms"
            me_ports = ["22"]
          }
        ]
      }
    }
    azservices = {
      shortname = "azsvc"
      attacker = {
        subnet = "10.127.14.0/24"
        virtual_machines = [
          {
            label      = "attack"
            ip_address = "10.127.14.4"
            image = {
              publisher = "debian"
              offer     = "debian-11"
              sku       = "11"
              version   = "latest"
            }
            size           = "Standard_B2ms"
            me_ports       = ["22"]
            ansible_groups = ["mysqlclient"]
          }
        ]
      }
    }
  }
  active_scenarios = merge(
  { for s in var.scenarios : s => local.scenarios[s] if can(local.scenarios[s]) }, { general = local.scenarios["general"] })
  resource_name = {
    storage_account        = "sa"
    resource_group         = "rg"
    network_watcher        = "nw"
    network_security_group = "nsg"
    vnet                   = "vnet"
    subnet                 = "sn"
    nic                    = "nic"
    virtual_machine        = "vm"
    logic_app              = "la"
    public_ip              = "pip"
    ado_org                = "ado"
    disk                   = "dsk"
    sql                    = "sql"
  }
  target_virtual_machines = merge([
    for s, v in local.active_scenarios : {
      for i, vm in v.target.virtual_machines : join("_", [s, vm.label]) => {
        name             = "${local.target_prefix}${v.shortname}${local.lab_id}${vm.label}${local.resource_name.virtual_machine}"
        scenario         = s
        size             = vm.size
        ip_address       = vm.ip_address
        custom_data      = can(vm.custom_data) ? vm.custom_data : null
        image            = can(vm.image) ? vm.image : null
        plan             = can(vm.plan) ? vm.plan : null
        bastion_ports    = can(vm.bastion_ports) ? vm.bastion_ports : null
        me_ports         = can(vm.me_ports) ? vm.me_ports : null
        public_ports     = can(vm.public_ports) ? vm.public_ports : null
        ansible_groups   = can(vm.ansible_groups) ? vm.ansible_groups : []
        ansible_ssh_port = can(vm.ansible_ssh_port) ? vm.ansible_ssh_port : 22
        ansible_vars     = can(vm.ansible_vars) ? vm.ansible_vars : null
        service_tags     = can(vm.service_tags) ? vm.service_tags : null
        data_disk        = can(vm.data_disk) ? vm.data_disk : null
      }
    } if can(v.target.virtual_machines)
  ]...)
  attacker_virtual_machines = merge([
    for s, v in local.active_scenarios : {
      for i, vm in v.attacker.virtual_machines : join("_", [s, vm.label]) => {
        name             = "${local.attacker_prefix}${v.shortname}${local.lab_id}${vm.label}${local.resource_name.virtual_machine}"
        scenario         = s
        size             = vm.size
        ip_address       = vm.ip_address
        custom_data      = can(vm.custom_data) ? vm.custom_data : null
        image            = can(vm.image) ? vm.image : null
        plan             = can(vm.plan) ? vm.plan : null
        me_ports         = can(vm.me_ports) ? vm.me_ports : null
        public_ports     = can(vm.public_ports) ? vm.public_ports : null
        ansible_groups   = can(vm.ansible_groups) ? vm.ansible_groups : []
        ansible_ssh_port = can(vm.ansible_ssh_port) ? vm.ansible_ssh_port : 22
        ansible_vars     = can(vm.ansible_vars) ? vm.ansible_vars : null
      }
    } if can(v.attacker.virtual_machines)
  ]...)
}
