variable "attacker_tenant_id" {
  type = string
}

variable "attacker_subscription_id" {
  type = string
}


variable "target_tenant_id" {
  type = string
}

variable "debug" {
  type    = bool
  default = false
}

variable "target_subscription_id" {
  type = string
}

variable "prefix" {
  type        = string
  description = "Name prefix for the deployed resources"
  default     = "sta"
}

variable "default_vm_size" {
  type    = string
  default = "Standard_B2ms"
}

variable "location" {
  type    = string
}

variable "scenarios" {
  type = set(string)

  validation {
    condition = alltrue(
      [for s in var.scenarios :
        contains(
          [
            "logicapp",
            "devops",
            "azurecloud",
            "azservices"
          ],
          s
        )
      ]
    )
    error_message = "Invalid scenario found in [${join(", ", var.scenarios)}]"
  }
}
