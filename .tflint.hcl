# ============================================================================
# TFLint Configuration for Azure Automation Scenarios
# ============================================================================
# TFLint is a Terraform linter that helps catch errors and enforce best practices.
# Installation: https://github.com/terraform-linters/tflint
#
# Usage:
#   tflint --init          # Install plugins (run once)
#   tflint                 # Lint current directory
#   tflint --recursive     # Lint all subdirectories
#   tflint --format=compact # Compact output
#
# ============================================================================

config {
  # Enable module inspection
  module = true

  # Force provider downloads even if not needed
  force = false

  # Disable color output for CI/CD
  disabled_by_default = false
}

plugin "azurerm" {
  enabled = true
  version = "0.25.1"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

plugin "terraform" {
  enabled = true
  version = "0.5.0"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
}

# ============================================================================
# Terraform Best Practices Rules
# ============================================================================

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_standard_module_structure" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_unused_required_providers" {
  enabled = true
}

rule "terraform_workspace_remote" {
  enabled = false # We allow local workspace for demos
}

# ============================================================================
# Azure-Specific Rules
# ============================================================================

rule "azurerm_resource_missing_tags" {
  enabled = false # We define tags per scenario
}

rule "azurerm_virtual_machine_use_managed_disk" {
  enabled = true
}
