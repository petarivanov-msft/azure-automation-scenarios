# Contributing to Azure Automation Scenarios

Thank you for your interest in contributing! This document provides guidelines and best practices for contributing to this repository.

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help maintain a welcoming environment

## How to Contribute

### Reporting Issues

1. Check if the issue already exists
2. Provide detailed description
3. Include steps to reproduce
4. Share Terraform/Azure CLI versions
5. Provide error messages and logs

### Submitting Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Make your changes
4. Test your changes thoroughly
5. Commit with clear messages
6. Push to your fork
7. Submit a pull request

## Development Guidelines

### Code Style

This repository uses consistent formatting enforced by:

- **EditorConfig** - Configure your editor to use `.editorconfig`
- **Terraform** - Use `terraform fmt` before committing
- **PowerShell** - Follow 4-space indentation

### Formatting Tools

Before submitting a PR, run:

```powershell
# Format all Terraform files
.\format-all.ps1
```

### File Structure

Each scenario should maintain:
```
scenario-directory/
├── main.tf         # Main Terraform configuration
├── variables.tf    # Variable definitions
├── outputs.tf      # Output values
└── README.md       # Scenario-specific documentation
```

### Terraform Best Practices

1. **Provider Versions** - Use version constraints:
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
   ```

2. **Variables** - Always include descriptions and validation:
   ```hcl
   variable "example" {
     description = "Clear description of purpose"
     type        = string
     
     validation {
       condition     = can(regex("^pattern$", var.example))
       error_message = "Helpful error message"
     }
   }
   ```

3. **Outputs** - Provide useful information:
   ```hcl
   output "example" {
     description = "What this output contains"
     value       = azurerm_resource.example.id
   }
   ```

4. **Comments** - Use section headers:
   ```hcl
   # ============================================================================
   # Section Name
   # ============================================================================
   ```

### PowerShell Best Practices

1. **Use Common Functions** - Import and use `common-functions.ps1`:
   ```powershell
   . (Join-Path $PSScriptRoot "common-functions.ps1")
   ```

2. **Error Handling** - Always handle errors gracefully:
   ```powershell
   try {
       # Your code
   } catch {
       Write-ErrorMsg "Helpful error message"
       return $false
   }
   ```

3. **User Feedback** - Use consistent messaging:
   ```powershell
   Write-Success "Operation completed"
   Write-Info "Informational message"
   Write-Warning2 "Warning message"
   Write-ErrorMsg "Error message"
   ```

### Documentation

1. **README Files** - Each scenario must have:
   - Overview and purpose
   - Prerequisites
   - Deployment instructions
   - Testing/validation steps
   - Cleanup instructions

2. **Comments** - Add comments for:
   - Complex logic
   - Non-obvious decisions
   - Workarounds
   - API limitations

3. **Commit Messages** - Use clear, descriptive messages:
   ```
   Add: New feature or file
   Fix: Bug fix
   Update: Modification to existing feature
   Refactor: Code restructuring
   Docs: Documentation changes
   ```

## Testing Your Changes

Before submitting:

1. **Format Check**
   ```powershell
   .\format-all.ps1
   ```

2. **Manual Testing**
   - Deploy the scenario
   - Verify all resources are created
   - Test functionality
   - Verify cleanup works
   - Check documentation accuracy

3. **Cross-Scenario Impact**
   - Ensure changes to shared files don't break other scenarios
   - Test `deploy.ps1` and `destroy.ps1` if modified

## Scenario Independence

Each scenario should remain:
- **Self-contained** - No external module dependencies
- **Portable** - Can be copied independently
- **Educational** - Easy to understand without deep Terraform knowledge

Avoid creating complex shared modules that would reduce clarity.

## Pull Request Checklist

Before submitting your PR:

- [ ] Code is formatted (`.\format-all.ps1`)
- [ ] All files follow naming conventions
- [ ] Documentation is updated
- [ ] Changes are tested end-to-end
- [ ] Commit messages are clear
- [ ] No sensitive information in code
- [ ] `.gitignore` updated if needed
- [ ] README updated if structure changed

## Questions?

If you have questions:
1. Check existing issues and discussions
2. Review scenario README files
3. Open a discussion for general questions
4. Open an issue for specific bugs

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing! 🚀
