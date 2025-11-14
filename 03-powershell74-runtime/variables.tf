# ============================================================================
# Variables for PowerShell 7.4 Runtime Demo
# ============================================================================

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "resource_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "ps74demo"
  
  validation {
    condition     = can(regex("^[a-z0-9]{3,10}$", var.resource_prefix))
    error_message = "Resource prefix must be 3-10 lowercase alphanumeric characters."
  }
}

variable "auto_test_runbook" {
  description = "Automatically execute test runbook after deployment"
  type        = bool
  default     = false  # Disabled by default (bash script not compatible with Windows)
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Demo"
    Project     = "PowerShell74Runtime"
    ManagedBy   = "Terraform"
  }
}
