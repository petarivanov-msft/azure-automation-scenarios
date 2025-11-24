# Migration Guide: Old Structure → New Structure

This guide helps users transition from the old multi-scenario structure to the new unified lab environment.

## What Changed?

### Old Structure (Before)
```
azure-automation-scenarios/
├── deploy.ps1                    # PowerShell deployment script
├── destroy.ps1                   # PowerShell cleanup script
├── common-functions.ps1          # Shared PowerShell functions
├── 01-graph-api-automation/      # Separate scenario
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
├── 02-startstop-vms/             # Separate scenario
├── 03-powershell74-runtime/      # Separate scenario
└── 04-hybrid-worker-setup/       # Separate scenario
```

### New Structure (After)
```
azure-automation-scenarios/
├── init-lab.sh                   # ⭐ Bash deployment script
├── README.md                     # ⭐ New amelabs-style docs
├── SECURITY.md                   # ⭐ New security policy
├── terraform/                    # ⭐ Unified terraform config
│   ├── main.tf                   # Single entry point
│   ├── variables.tf              # Feature flags
│   ├── outputs.tf                # All outputs
│   └── modules/                  # Modular scenarios
│       ├── automation_account/   # Shared
│       ├── network/              # Shared
│       ├── graph_api/            # Scenario 1
│       ├── vm_startstop/         # Scenario 2
│       ├── powershell74_runtime/ # Scenario 3
│       └── hybrid_worker/        # Scenario 4
└── scripts/
    └── cleanup-lab.sh
```

## Key Differences

### Deployment Method

**Old:**
```powershell
# PowerShell script with menu
./deploy.ps1

# Or manual per-scenario
cd 01-graph-api-automation
terraform init
terraform apply
```

**New:**
```bash
# One-liner Cloud Shell deployment
bash <(curl -s https://raw.githubusercontent.com/.../init-lab.sh)

# Or manual unified deployment
cd terraform
terraform init
terraform apply
```

### Scenario Selection

**Old:**
- Interactive menu in deploy.ps1
- Deploy scenarios one at a time
- Each scenario isolated

**New:**
- Feature flags in terraform.tfvars
- Deploy all or selected scenarios together
- Shared resources (automation account, network)

### Configuration

**Old:**
- Variables in each scenario's variables.tf
- Separate state per scenario
- Manual cleanup per scenario

**New:**
- Central variables.tf with feature flags
- Single terraform state
- Single cleanup command

## Migration Steps

### For Users of Old Structure

1. **Update Your Clone**
   ```bash
   git pull origin main
   ```

2. **Review New Structure**
   ```bash
   cat README.md
   ls -R terraform/
   ```

3. **If You Have Existing Deployments**
   
   **Option A: Keep Old Deployments, Start Fresh**
   ```bash
   # Old deployments are independent
   # They continue to work
   # Deploy new structure separately
   cd terraform
   terraform init
   terraform apply
   ```

   **Option B: Cleanup Old, Deploy New**
   ```bash
   # Cleanup old deployments
   cd 01-graph-api-automation
   terraform destroy -auto-approve
   cd ../02-startstop-vms
   terraform destroy -auto-approve
   # ... repeat for all scenarios
   
   # Deploy new unified structure
   cd ../terraform
   terraform init
   terraform apply
   ```

4. **Use New Deployment Method**
   ```bash
   # Cloud Shell (recommended)
   bash <(curl -s https://raw.githubusercontent.com/.../init-lab.sh)
   ```

### Configuration Examples

**Old terraform.tfvars (per scenario):**
```hcl
# In 01-graph-api-automation/terraform.tfvars
resource_prefix = "mylab"
location = "eastus"
```

**New terraform.tfvars (unified):**
```hcl
# In terraform/terraform.tfvars
resource_group_name     = "rg-automation-lab"
location                = "eastus"
automation_account_name = "auto-lab-12345"
vm_admin_username       = "azureadmin"
vm_admin_password       = "SecurePass123!"

# Enable/disable scenarios
enable_graph_api       = true   # Was: 01-graph-api-automation
enable_startstop_vms   = true   # Was: 02-startstop-vms
enable_powershell74    = true   # Was: 03-powershell74-runtime
enable_hybrid_worker   = true   # Was: 04-hybrid-worker-setup
```

## Benefits of New Structure

### Cost Optimization
- **Old**: 4 automation accounts (1 per scenario)
- **New**: 1 shared automation account
- **Savings**: ~75% on automation account costs

### Simplified Management
- **Old**: 4 separate terraform states
- **New**: 1 unified terraform state
- **Benefit**: Easier to manage, single cleanup

### Cloud Shell Ready
- **Old**: Required PowerShell locally
- **New**: Works in Cloud Shell (Bash)
- **Benefit**: No local setup needed

### Modular Design
- **Old**: Duplicate code across scenarios
- **New**: Shared modules (automation_account, network)
- **Benefit**: DRY principle, easier maintenance

## Feature Parity

All scenarios from the old structure are preserved:

| Old Scenario | New Module | Status |
|--------------|------------|--------|
| 01-graph-api-automation | graph_api | ✅ Complete |
| 02-startstop-vms | vm_startstop | ✅ Complete |
| 03-powershell74-runtime | powershell74_runtime | ✅ Complete |
| 04-hybrid-worker-setup | hybrid_worker | ✅ Complete |

## Troubleshooting

### "I can't find the old deploy.ps1"

The old PowerShell scripts have been replaced with `init-lab.sh`. The old files are archived in `.archive/` directory (not committed).

### "Can I still deploy scenarios separately?"

Yes! Use feature flags:

```hcl
# Deploy only Graph API
enable_graph_api       = true
enable_startstop_vms   = false
enable_powershell74    = false
enable_hybrid_worker   = false
```

### "Where are the individual scenario READMEs?"

All documentation is now in the main README.md. Module-specific details are in the module files and code comments.

### "My old terraform state is incompatible"

The new structure uses a different state format. You cannot migrate old states to the new structure. Either:
1. Keep old deployments running (they're independent)
2. Destroy old deployments and redeploy with new structure

## Questions?

- Check the new [README.md](README.md)
- Review the [SECURITY.md](SECURITY.md)
- Open an issue on GitHub
- Check individual module code

## Timeline

- **Old Structure**: Archived in `.archive/` directory
- **New Structure**: Active in main branch
- **Support**: Old structure is deprecated but reference files kept
- **Recommendation**: Use new structure for all new deployments
