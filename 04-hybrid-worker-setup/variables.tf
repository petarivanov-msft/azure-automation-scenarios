# ============================================================================
# Variables for Azure Hybrid Worker Lab
# ============================================================================

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-hybrid-worker-lab"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.location))
    error_message = "Location must be a valid Azure region name (lowercase, no spaces). Example: 'eastus', 'westeurope', 'southeastasia'."
  }
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "hwlab"
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureadmin"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "Lab"
    Purpose     = "HybridWorker"
    ManagedBy   = "Terraform"
  }
}

variable "run_test_runbook" {
  description = "Whether to automatically run the test runbook after deployment"
  type        = bool
  default     = true
}
