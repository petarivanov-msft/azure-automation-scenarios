# Terraform Configuration Enhancements

This document summarizes the enhancements made to improve reliability and reduce errors.

## Summary of Changes

All Terraform configurations have been enhanced for better reliability, Azure Cloud Shell compatibility, and reduced chance of errors.

## Key Enhancements

### 1. Azure Cloud Shell Compatibility
- ✅ All scenarios work in both PowerShell (default) and Bash modes
- ✅ Requires Terraform 1.5+ (available in Cloud Shell)
- ✅ Uses Azure CLI authentication (pre-configured in Cloud Shell)

### 2. Fixed Schedule Drift Issue (Critical)
- **Problem**: Using `timestamp()` caused schedules to change on every apply
- **Solution**: Changed to `plantimestamp()` with `ignore_changes` lifecycle rule
- **Impact**: Schedules now remain stable across multiple applies

### 3. Resource Timeouts
Added explicit timeouts to prevent hanging operations:
- Automation Accounts: 30 minutes (create/update/delete)
- Module Imports: 30 minutes (create/update), 10 minutes (delete)

### 4. Lifecycle Rules
- Added `prevent_destroy = false` to Automation Accounts (set to `true` for production)
- Added `ignore_changes = [start_time]` to schedules

### 5. Input Validation
- Location: Must be lowercase, no spaces (e.g., "eastus" not "East US")
- Resource prefix: 3-10 lowercase alphanumeric characters
- Better error messages for validation failures

### 6. Configuration Examples
Created example files for easy customization:
- `terraform.tfvars.example` - Variable examples for each scenario
- `backend.tf.example` - Remote state configuration template
- `.tflint.hcl` - TFLint configuration for code quality

## Files Changed

### Scenario 1 - Graph API Automation
- `main.tf`: Added timeouts, lifecycle rules, Cloud Shell comments
- `variables.tf`: Added location validation
- `terraform.tfvars.example`: New configuration example

### Scenario 2 - Start/Stop VMs
- `main.tf`: Fixed schedule drift, added timeouts, lifecycle rules, locals block
- `variables.tf`: Added location validation, `schedule_start_time` variable
- `terraform.tfvars.example`: New configuration example

### Scenario 3 - PowerShell 7.4 Runtime
- `main.tf`: Added timeouts, lifecycle rules, Cloud Shell comments
- `variables.tf`: Added location validation
- `terraform.tfvars.example`: New configuration example

### Scenario 4 - Hybrid Worker Setup
- `variables.tf`: Fixed location inconsistency, added validation
- `terraform.tfvars.example`: New configuration example

### Repository Root
- `backend.tf.example`: Remote state template (new)
- `.tflint.hcl`: Linter configuration (new)

## Usage in Azure Cloud Shell

### Quick Start
```bash
# 1. Open Azure Cloud Shell (https://shell.azure.com)

# 2. Clone repository
git clone https://github.com/petarivanov-msft/azure-automation-scenarios.git
cd azure-automation-scenarios

# 3. Choose a scenario
cd 01-graph-api-automation

# 4. (Optional) Customize variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your preferred values

# 5. Deploy
terraform init
terraform plan
terraform apply

# 6. Clean up when done
terraform destroy
```

### PowerShell Mode (Default)
```powershell
# All terraform commands work the same
terraform init
terraform apply
```

### Bash Mode
```bash
# Switch to bash mode
bash

# All terraform commands work the same
terraform init
terraform apply
```

## Best Practices Applied

1. **Explicit Dependencies**: Using `depends_on` where needed
2. **Timeout Configuration**: Prevents indefinite waits
3. **Lifecycle Management**: Safer resource operations
4. **Input Validation**: Catches errors early
5. **Consistent Formatting**: All files formatted with `terraform fmt`
6. **Documentation**: Clear comments and examples

## Validation

All configurations have been:
- ✅ Formatted with `terraform fmt`
- ✅ Validated with `terraform validate`
- ✅ Tested for syntax errors
- ✅ Verified for Cloud Shell compatibility

## Version Requirements

- **Terraform**: >= 1.5.0 (for `plantimestamp()` function)
- **Azure CLI**: Pre-installed in Cloud Shell
- **Providers**:
  - azurerm: ~> 3.0
  - azuread: ~> 2.0
  - azapi: ~> 1.0
  - random: ~> 3.0

---

**Last Updated**: November 2025  
**Tested In**: Azure Cloud Shell (PowerShell and Bash modes)
