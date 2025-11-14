# ============================================================================
# Variables for Azure Automation Microsoft Graph API Demo
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
  default     = "graphauto"

  validation {
    condition     = can(regex("^[a-z0-9]{3,10}$", var.resource_prefix))
    error_message = "Resource prefix must be 3-10 lowercase alphanumeric characters."
  }
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
    Project     = "GraphAPIAutomation"
    ManagedBy   = "Terraform"
  }
}
