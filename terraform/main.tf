# ============================================================================
# Azure Automation Scenarios - Unified Lab Environment
# ============================================================================
# This configuration deploys all Azure Automation scenarios in a single
# unified environment:
# - Graph API Automation with Managed Identity
# - Start/Stop VMs with Tag-Based Scheduling
# - PowerShell 7.4 Runtime Environment
# - Hybrid Worker Setup
# ============================================================================

# Data sources
data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Random password for VMs
resource "random_password" "vm_password" {
  length  = 16
  special = true
}

locals {
  vm_password = var.vm_admin_password != "" ? var.vm_admin_password : random_password.vm_password.result
}

# ============================================================================
# Core Automation Account Module
# ============================================================================

module "automation_account" {
  source              = "./modules/automation_account"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  automation_account_name = var.automation_account_name
  tags                = var.tags
}

# ============================================================================
# Network Module (Shared for all VMs)
# ============================================================================

module "network" {
  source              = "./modules/network"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tags                = var.tags
}

# ============================================================================
# Scenario 1: Graph API Automation
# ============================================================================

module "graph_api" {
  count = var.enable_graph_api ? 1 : 0
  
  source                     = "./modules/graph_api"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = var.location
  automation_account_name    = module.automation_account.automation_account_name
  automation_account_id      = module.automation_account.automation_account_id
  managed_identity_principal_id = module.automation_account.managed_identity_principal_id
  tags                       = var.tags
}

# ============================================================================
# Scenario 2: Start/Stop VMs
# ============================================================================

module "vm_startstop" {
  count = var.enable_startstop_vms ? 1 : 0
  
  source                     = "./modules/vm_startstop"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = var.location
  automation_account_name    = module.automation_account.automation_account_name
  automation_account_id      = module.automation_account.automation_account_id
  managed_identity_principal_id = module.automation_account.managed_identity_principal_id
  subnet_id                  = module.network.subnet_id
  vm_admin_username          = var.vm_admin_username
  vm_admin_password          = local.vm_password
  tags                       = var.tags
}

# ============================================================================
# Scenario 3: PowerShell 7.4 Runtime
# ============================================================================

module "powershell74_runtime" {
  count = var.enable_powershell74 ? 1 : 0
  
  source                     = "./modules/powershell74_runtime"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = var.location
  automation_account_name    = module.automation_account.automation_account_name
  automation_account_id      = module.automation_account.automation_account_id
  subscription_id            = data.azurerm_client_config.current.subscription_id
  tags                       = var.tags
}

# ============================================================================
# Scenario 4: Hybrid Worker
# ============================================================================

module "hybrid_worker" {
  count = var.enable_hybrid_worker ? 1 : 0
  
  source                        = "./modules/hybrid_worker"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = var.location
  automation_account_name       = module.automation_account.automation_account_name
  automation_account_id         = module.automation_account.automation_account_id
  automation_identity_principal_id = module.automation_account.managed_identity_principal_id
  subnet_id                     = module.network.subnet_id
  vm_admin_username             = var.vm_admin_username
  vm_admin_password             = local.vm_password
  subscription_id               = data.azurerm_client_config.current.subscription_id
  tags                          = var.tags
}
