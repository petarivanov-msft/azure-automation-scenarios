# ============================================================================
# Variables for Start/Stop VMs Demo
# ============================================================================

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.location))
    error_message = "Location must be a valid Azure region name (lowercase, no spaces). Example: 'eastus', 'westeurope', 'southeastasia'."
  }
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

variable "schedule_start_time" {
  description = "Base start time for schedules (ISO 8601 format). If not provided, uses tomorrow at current time."
  type        = string
  default     = ""
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
