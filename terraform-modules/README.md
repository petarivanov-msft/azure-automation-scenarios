# Terraform Modules

This directory contains shared resources and documentation for Terraform configurations.

## Purpose

While each scenario maintains its own complete Terraform configuration for independence and ease of use, this directory provides:

1. **Common Variables** - Reference implementations for consistent variable definitions
2. **Provider Versions** - Recommended provider version constraints
3. **Best Practices** - Documentation for Terraform patterns used across scenarios

## Why Not Shared Modules?

Each scenario in this repository is designed to be:
- **Self-contained** - Can be deployed independently
- **Educational** - Easy to understand without external dependencies
- **Portable** - Can be copied and modified without breaking dependencies

Therefore, we intentionally keep each scenario's Terraform code independent rather than creating shared modules that would add complexity.

## Common Patterns

All scenarios follow these patterns:

### Provider Configuration
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
```

### Variable Definitions
```hcl
variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "resource_prefix" {
  description = "Prefix for resource names"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9]{3,10}$", var.resource_prefix))
    error_message = "Resource prefix must be 3-10 lowercase alphanumeric characters."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}
```

### Resource Naming
- Format: `${var.resource_prefix}-<resource-type>-<purpose>`
- Example: `graphauto-automation-graph`

## Directory Structure

```
terraform-modules/
├── README.md                    # This file
└── common-variables/
    └── versions.tf             # Reference provider versions
```
