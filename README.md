# Service Tag Abuse

This repository houses terraform templates and ansible playbooks used to explore security risks associated with Azure Service Tag usage. It was created to accompany Aled Mehta's talk 'Tag You're Exposed: Exploring Service Tags and their Impact on Your Security Boundary' at the Cloud Village at DEF CON 31 (link pending).

> All templates and scripts have been provided to represent specific behaviour relating to Azure Service Tags and similar network controls. Deployed resources should not be used outside of the demonstration scenarios presented within this repository.

## Scenarios

| Scenario ID  | Service Tag                   | Docs                                         |
|--------------|-------------------------------|----------------------------------------------|
| `azurecloud` | `AzureCloud`                  | [Azure Cloud](./docs/azurecloud.md)          |
| `azservices` | N/A (similar to `AzureCloud`) | [Allow Azure Services](./docs/azservices.md) |
| `logicapp`   | `LogicApps`                   | [Logic Apps](./docs/logicapps.md)            |
| `devops`     | `AzureDevOps`                 | [Azure DevOps](./docs/devops.md)             |

## Usage

The deployment of these scenarios typically consists of two stages:

- Resource deployment using Terraform
- Resource configuration using Ansible

Some of the scenarios do require further configuration outside the above steps. Further details can be found within the respective documentation as per the above scenarios table.

### Configuration

A configuration file is available at `terraform/config.auto.tfvars` to define which scenarios to deploy, and which Azure environment to deploy them to. The available configuration options are listed below:

| Variable                   | Value                                                  | Required |
|----------------------------|--------------------------------------------------------|----------|
| `attacker_subscription_id` | Subscription ID of the attacker environment            | Y        |
| `attacker_tenant_id`       | Tenant ID of the attacker environment                  | Y        |
| `target_subscription_id`   | Subscription ID of the target environment              | Y        |
| `target_tenant_id`         | Tenant ID of the target environment                    | Y        |
| `scenarios`                | List of scenario IDs as detailed above                 | Y        |
| `location`                 | Azure region to deploy resources to                    | Y        |
| `debug`                    | Boolean to allow all traffic to VMs for debug purposes | N        |

### Deployment

Please ensure that you have read the respective documentation pages for the scenarios that you wish to deploy as the steps differ (e.g. for the `devops` scenario). In general the deployment can be run as follows:

- Terraform:
  - navigate to `terraform/`
  - install providers: `terraform init -upgrade`
  - apply templates: `terraform apply`

- Ansible:
  - navigate to `ansible/`
  - install collections: `ansible-galaxy collection install -r requirements.yml`
  - run playbook: `ansible-playbook -i ./inventory.yml ./playbook.yml`

### Supported Regions

Some features used for these scenarios are not available in all regions. Below is a list of regions that should support all features required for scenario deployment.

- `northcentralus`
- `southcentralus`
- `westcentralus`
- `eastus`
- `eastus2`
- `westus`
- `centralus`
- `northeurope`
- `westeurope`
- `eastasia`
- `southeastasia`
- `japaneast`
- `japanwest`
- `brazilsouth`
- `australiaeast`
- `westindia`
- `centralindia`
- `southindia`
- `westus2`
- `canadacentral`
- `uksouth`
