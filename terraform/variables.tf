variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "automation_account_name" {
  description = "Name of the Azure Automation Account"
  type        = string
}

variable "vm_admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "azureadmin"
}

variable "vm_admin_password" {
  description = "Admin password for VMs"
  type        = string
  sensitive   = true
}

variable "enable_graph_api" {
  description = "Enable Graph API automation scenario"
  type        = bool
  default     = true
}

variable "enable_startstop_vms" {
  description = "Enable Start/Stop VMs scenario"
  type        = bool
  default     = true
}

variable "enable_powershell74" {
  description = "Enable PowerShell 7.4 runtime scenario"
  type        = bool
  default     = true
}

variable "enable_hybrid_worker" {
  description = "Enable Hybrid Worker scenario"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Lab"
    Purpose     = "Azure Automation Scenarios"
    ManagedBy   = "Terraform"
  }
}
