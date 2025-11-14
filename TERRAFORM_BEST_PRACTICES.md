# Terraform Best Practices for Azure Cloud Shell

This document outlines the Terraform best practices implemented in this repository and provides guidance for working with these configurations in Azure Cloud Shell.

## Table of Contents

1. [Azure Cloud Shell Compatibility](#azure-cloud-shell-compatibility)
2. [State Management](#state-management)
3. [Provider Configuration](#provider-configuration)
4. [Resource Configuration](#resource-configuration)
5. [Error Handling](#error-handling)
6. [Validation and Testing](#validation-and-testing)
7. [Common Issues and Solutions](#common-issues-and-solutions)

---

## Azure Cloud Shell Compatibility

### Overview

All Terraform configurations in this repository are designed to work seamlessly in **Azure Cloud Shell**, which can run in both PowerShell and Bash modes.

### Requirements

- **Terraform**: Version 1.5.0 or higher (for `plantimestamp()` function support)
- **Azure CLI**: Pre-authenticated in Cloud Shell
- **Shell**: Compatible with both PowerShell and Bash modes

### Shell Mode Notes

Azure Cloud Shell defaults to **PowerShell** mode but also supports Bash:

```powershell
# In PowerShell mode (default)
terraform init
terraform plan
terraform apply
```

```bash
# In Bash mode (switch with 'bash' command)
terraform init
terraform plan
terraform apply
```

All Terraform commands work identically in both modes since Terraform is shell-agnostic.

---

## State Management

### Local State (Default)

By default, Terraform stores state locally in a `terraform.tfstate` file. This is suitable for:
- Individual learning and testing
- Single-user scenarios
- Temporary deployments

**Important**: Local state files are excluded from git via `.gitignore`.

### Remote State (Recommended for Teams)

For team collaboration and production use, configure remote state using Azure Storage:

1. Copy `backend.tf.example` to your scenario directory as `backend.tf`
2. Create an Azure Storage Account following the instructions in the example
3. Update the backend configuration with your storage account details
4. Run `terraform init` to migrate state

**Benefits:**
- State locking prevents concurrent modifications
- Team collaboration with shared state
- Enhanced security and audit trail
- Automatic state versioning

---

## Provider Configuration

### Version Constraints

All scenarios use explicit version constraints for predictable behavior:

```hcl
terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}
```

**Why version constraints matter:**
- `~> 3.0`: Allows minor version updates (3.1, 3.2) but not major (4.0)
- Prevents breaking changes from automatic upgrades
- Ensures reproducible deployments

### Provider Features

The `azurerm` provider is configured with specific features for safe resource management:

```hcl
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine {
      delete_os_disk_on_deletion     = true
      skip_shutdown_and_force_delete = true
    }
  }
}
```

---

## Resource Configuration

### Timeouts

Long-running operations have explicit timeouts to prevent hanging:

```hcl
resource "azurerm_automation_account" "main" {
  # ... other configuration ...

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}
```

**Applied to:**
- Automation Accounts (30 minutes)
- Automation Modules (30 minutes for create/update, 10 minutes for delete)
- Virtual Machines (default timeout)

### Lifecycle Rules

Resources include lifecycle rules for safer operations:

```hcl
resource "azurerm_automation_account" "main" {
  # ... other configuration ...

  lifecycle {
    prevent_destroy = false  # Set to true for production
  }
}
```

**Schedule Resources:**
```hcl
resource "azurerm_automation_schedule" "morning_start" {
  # ... other configuration ...
  start_time = local.base_start_time

  lifecycle {
    ignore_changes = [start_time]  # Prevents drift on subsequent applies
  }
}
```

### Naming Conventions

Resources follow consistent naming patterns:

- **Resource Groups**: `rg-{prefix}-{purpose}`
- **Automation Accounts**: `{prefix}-automation-{purpose}`
- **Virtual Machines**: `{prefix}-vm-{role}`
- **Networks**: `{prefix}-vnet`, `{prefix}-subnet`, `{prefix}-nsg`

---

## Error Handling

### Input Validation

All variables include validation rules:

```hcl
variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.location))
    error_message = "Location must be a valid Azure region name (lowercase, no spaces)."
  }
}

variable "resource_prefix" {
  description = "Prefix for resource names"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,10}$", var.resource_prefix))
    error_message = "Resource prefix must be 3-10 lowercase alphanumeric characters."
  }
}
```

### Schedule Time Handling

Schedules use `plantimestamp()` for consistent time calculations:

```hcl
locals {
  base_start_time = var.schedule_start_time != "" ? 
    var.schedule_start_time : 
    formatdate("YYYY-MM-DD'T'hh:mm:ss'Z'", timeadd(plantimestamp(), "24h"))
}
```

**Key Points:**
- Uses `plantimestamp()` instead of `timestamp()` to avoid drift
- Includes `ignore_changes` lifecycle rule for stability
- Allows custom start time via variable

### Dependency Management

Explicit dependencies ensure correct resource ordering:

```hcl
resource "azurerm_automation_module" "az_compute" {
  # ... configuration ...
  
  depends_on = [azurerm_automation_module.az_accounts]
}
```

---

## Validation and Testing

### Pre-Deployment Validation

Before deploying, validate your configuration:

```bash
# Initialize providers
terraform init

# Validate syntax and logic
terraform validate

# Preview changes
terraform plan

# Check formatting
terraform fmt -check -recursive
```

### Using TFLint

TFLint provides additional validation:

```bash
# Install TFLint (if not already installed)
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Initialize TFLint plugins
tflint --init

# Run linting
tflint --recursive
```

### Scenario-Specific Testing

Each scenario includes test runbooks that validate functionality:

1. **01-graph-api-automation**: Tests Graph API connectivity
2. **02-startstop-vms**: Tests VM power management
3. **03-powershell74-runtime**: Tests PowerShell 7.4 features
4. **04-hybrid-worker-setup**: Tests hybrid worker registration

---

## Common Issues and Solutions

### Issue: "Error acquiring the state lock"

**Cause**: Another Terraform operation is in progress or a previous operation was interrupted.

**Solution:**
```bash
# Force unlock (use with caution!)
terraform force-unlock <LOCK_ID>
```

### Issue: Module import times out

**Cause**: PowerShell Gallery may be slow or network latency.

**Solution:**
- Module imports include 30-minute timeouts
- Wait for completion or re-run `terraform apply`
- Check Azure Portal for module import status

### Issue: Schedule drift detected on subsequent applies

**Cause**: Using `timestamp()` function causes changes on every plan.

**Solution:**
- ✅ Fixed: Now uses `plantimestamp()` and `ignore_changes`
- Schedules remain stable across multiple applies

### Issue: "location must be lowercase"

**Cause**: Location specified with spaces or capital letters (e.g., "East US").

**Solution:**
```hcl
# ❌ Wrong
location = "East US"

# ✅ Correct
location = "eastus"
```

### Issue: Provider initialization fails in Cloud Shell

**Cause**: Network issues or Azure CLI not authenticated.

**Solution:**
```bash
# Verify Azure CLI authentication
az account show

# Re-authenticate if needed
az login

# Verify subscription
az account list --output table
```

### Issue: Resources fail to create due to naming conflicts

**Cause**: Resource names must be globally unique or unique within subscription.

**Solution:**
```hcl
# Use a unique prefix
variable "resource_prefix" {
  default = "myunique123"
}
```

---

## Quick Start Checklist

Before deploying any scenario in Azure Cloud Shell:

- [ ] Verify Azure CLI authentication: `az account show`
- [ ] Choose a unique resource prefix
- [ ] Review and customize `variables.tf` if needed
- [ ] Run `terraform init` to initialize providers
- [ ] Run `terraform validate` to check configuration
- [ ] Run `terraform plan` to preview changes
- [ ] Run `terraform apply` to deploy resources
- [ ] Test the deployed resources
- [ ] Run `terraform destroy` when done to clean up

---

## Additional Resources

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Cloud Shell Documentation](https://docs.microsoft.com/azure/cloud-shell/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
- [TFLint Rules](https://github.com/terraform-linters/tflint)

---

## Version History

- **v1.1** (Current): Added Azure Cloud Shell optimizations, timeouts, lifecycle rules, and enhanced validation
- **v1.0**: Initial Terraform configurations

---

**Last Updated**: November 2025  
**Terraform Version**: >= 1.5.0  
**Tested In**: Azure Cloud Shell (PowerShell and Bash modes)
