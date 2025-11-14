# ============================================================================
# Variables for Start/Stop VMs Demo
# ============================================================================

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "resource_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "startstop"
  
  validation {
    condition     = can(regex("^[a-z0-9]{3,10}$", var.resource_prefix))
    error_message = "Resource prefix must be 3-10 lowercase alphanumeric characters."
  }
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "azureadmin"
}

variable "vm_size" {
  description = "Size of the VMs"
  type        = string
  default     = "Standard_B2s"
}

variable "timezone" {
  description = "Timezone for scheduling (e.g., Eastern Standard Time, UTC)"
  type        = string
  default     = "Eastern Standard Time"
}

variable "auto_test_runbook" {
  description = "Automatically execute test runbook after deployment"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Demo"
    Project     = "StartStopVMs"
    ManagedBy   = "Terraform"
  }
}
