# Developer Tools Guide

This repository includes several utility scripts to help maintain code quality and consistency.

## Quick Reference

```powershell
# Deploy a scenario interactively
.\deploy.ps1

# Clean up deployed scenarios
.\destroy.ps1

# Format all Terraform files
.\format-all.ps1

# Validate repository health
.\validate-repo.ps1
```

## Detailed Tool Documentation

### deploy.ps1
**Purpose**: Interactive deployment script for Azure Automation scenarios

**Features**:
- Interactive menu for scenario selection
- Prerequisite checking (Terraform, Azure CLI)
- Automated Terraform initialization, planning, and deployment
- Post-deployment summary with cleanup instructions
- Azure subscription verification

**Usage**:
```powershell
.\deploy.ps1
```

**What it does**:
1. Checks prerequisites (Terraform, Azure CLI)
2. Displays available scenarios
3. Shows detailed scenario information
4. Confirms Azure subscription
5. Runs Terraform init, plan, and apply
6. Displays deployment summary

---

### destroy.ps1
**Purpose**: Interactive cleanup script for deployed scenarios

**Features**:
- Automatic detection of deployed scenarios
- Interactive selection of scenarios to destroy
- Option to destroy all scenarios at once
- Confirmation prompts to prevent accidental deletion
- Automatic cleanup of Terraform state files

**Usage**:
```powershell
.\destroy.ps1
```

**What it does**:
1. Scans for deployed scenarios (checks for .terraform directories)
2. Displays list of deployed scenarios
3. Allows selection of which scenarios to destroy
4. Confirms before destruction
5. Runs terraform destroy
6. Cleans up local Terraform files

---

### format-all.ps1
**Purpose**: Format and validate all Terraform configurations

**Features**:
- Formats all .tf files using `terraform fmt`
- Checks for formatting issues
- Shows diff of changes
- Optionally validates configurations (if initialized)
- Processes all scenario directories

**Usage**:
```powershell
.\format-all.ps1
```

**When to use**:
- Before committing changes
- After editing Terraform files
- As part of pre-commit hooks
- To ensure consistent formatting

**Output**:
- Lists each scenario processed
- Shows formatting changes
- Reports summary of formatted files

---

### validate-repo.ps1
**Purpose**: Repository health check and validation

**Features**:
- Validates scenario structure (required files)
- Checks .gitignore patterns
- Detects improperly tracked files
- Validates PowerShell syntax
- Verifies required repository files

**Usage**:
```powershell
.\validate-repo.ps1
```

**Checks performed**:
1. **Scenario structure** - Ensures each scenario has main.tf, variables.tf, outputs.tf, README.md
2. **Git ignore** - Verifies .gitignore exists and contains important patterns
3. **Tracked files** - Checks for tfstate, tfplan, or .terraform files in git
4. **PowerShell syntax** - Validates all .ps1 files for syntax errors
5. **Required files** - Ensures README.md, LICENSE, CONTRIBUTING.md, etc. exist

**Exit codes**:
- `0` - All checks passed
- `1` - Issues found

---

### common-functions.ps1
**Purpose**: Shared PowerShell functions library

**Features**:
- UI functions (Write-Success, Write-Info, Write-Warning2, Write-ErrorMsg)
- Scenario definitions (Get-ScenarioDefinitions)
- Prerequisite checking (Test-Prerequisites)
- Azure subscription helpers (Get-AzureSubscriptionInfo)
- Menu display helpers (Show-ScenarioMenu, Get-ScenarioSelection)

**Usage**:
```powershell
# In your script
. (Join-Path $PSScriptRoot "common-functions.ps1")

# Use functions
Write-Success "Operation completed"
$scenarios = Get-ScenarioDefinitions
```

**Available functions**:
- `Write-ColorOutput` - Write colored text to console
- `Write-Header` - Display formatted section header
- `Write-Success` - Display success message with ✅
- `Write-Info` - Display info message with ℹ️
- `Write-Warning2` - Display warning with ⚠️
- `Write-ErrorMsg` - Display error with ❌
- `Get-ScenarioDefinitions` - Get scenario metadata
- `Test-Prerequisites` - Check for Terraform and Azure CLI
- `Get-AzureSubscriptionInfo` - Get current Azure subscription
- `Show-ScenarioMenu` - Display interactive scenario menu
- `Get-ScenarioSelection` - Get user's scenario choice

---

## Configuration Files

### .editorconfig
Ensures consistent formatting across different editors and IDEs.

**Configured for**:
- Terraform files (2-space indentation)
- PowerShell files (4-space indentation)
- Markdown files (2-space indentation)
- JSON/YAML files (2-space indentation)
- Unix-style line endings (LF)
- UTF-8 encoding

**Supported editors**:
- Visual Studio Code
- Visual Studio
- JetBrains IDEs (IntelliJ, Rider, PyCharm, etc.)
- Vim
- Emacs
- Many others

### .gitignore
Prevents committing sensitive or generated files.

**Key patterns**:
- Terraform state files (*.tfstate, *.tfstate.*)
- Terraform plan files (*.tfplan, tfplan)
- Terraform directories (.terraform/)
- Terraform lock files (.terraform.lock.hcl)
- IDE directories (.vscode/, .idea/)
- Log files (*.log)
- Temporary files (*.tmp, *.bak)

---

## Best Practices

### Before Committing
1. Run `.\format-all.ps1` to format Terraform files
2. Run `.\validate-repo.ps1` to check for issues
3. Review changes with `git status` and `git diff`
4. Ensure no sensitive data in files

### When Adding New Scenarios
1. Follow existing directory structure (XX-scenario-name)
2. Include all required files (main.tf, variables.tf, outputs.tf, README.md)
3. Add scenario definition to common-functions.ps1
4. Update main README.md
5. Run validation tools

### When Modifying Scripts
1. Maintain consistent style (follow existing patterns)
2. Use functions from common-functions.ps1
3. Test syntax before committing
4. Update this documentation if adding new tools

---

## Troubleshooting

### PowerShell Execution Policy
If scripts won't run:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Terraform Not Found
Ensure Terraform is in PATH:
```powershell
# Check installation
terraform version

# If not found, download from https://www.terraform.io/downloads
```

### Azure CLI Not Found
Install Azure CLI:
```powershell
# Check installation
az version

# If not found, download from https://docs.microsoft.com/cli/azure/install-azure-cli
```

### Script Errors
1. Ensure you're in the repository root directory
2. Check that common-functions.ps1 exists
3. Verify PowerShell version (7.0+ recommended)
4. Check for syntax errors with validation tool

---

## Contributing

When adding new tools:
1. Follow existing patterns and style
2. Use common-functions.ps1 for consistency
3. Add documentation to this file
4. Update CONTRIBUTING.md if needed
5. Test thoroughly before committing

---

## Additional Resources

- [Main README](README.md) - Repository overview and quick start
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines
- [terraform-modules/README.md](terraform-modules/README.md) - Terraform patterns and best practices
