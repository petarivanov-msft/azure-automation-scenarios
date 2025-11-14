# Azure Automation - Start/Stop VMs with Tags

Automated VM power management using Azure Automation with tag-based scheduling.

## 🎯 What This Does

- ✅ Azure Automation Account with managed identity
- ✅ 3 test VMs with different power schedules
- ✅ Custom runbooks to start/stop VMs by tag
- ✅ Tag-based power management (AlwaysOn, BusinessHours, NightShutdown)
- ✅ Power state reporting

## 🚀 Quick Start

```bash
# Clone and deploy
git clone https://github.com/petarivanov-msft/azure-automation-demos.git
cd azure-automation-demos/02-startstop-vms

terraform init
terraform apply -auto-approve
```

## 🏷️ Power Schedule Tags

The demo creates 3 VMs with different schedules:

| VM | PowerSchedule Tag | Behavior |
|----|------------------|----------|
| vm-prod | **AlwaysOn** | Never stopped automatically |
| vm-dev | **BusinessHours** | Run 8 AM - 6 PM weekdays |
| vm-test | **NightShutdown** | Stop at night (10 PM - 6 AM) |

## 📜 Runbooks

### 1. Start-VMsByTag
Starts VMs with matching PowerSchedule tag.

**Usage**:
```bash
az automation runbook start \
  --automation-account-name <name> \
  --resource-group <rg> \
  --name "Start-VMsByTag" \
  --parameters '{"Schedule":"BusinessHours"}'
```

### 2. Stop-VMsByTag
Stops VMs with matching PowerSchedule tag (excludes AlwaysOn).

**Usage**:
```bash
az automation runbook start \
  --automation-account-name <name> \
  --resource-group <rg> \
  --name "Stop-VMsByTag" \
  --parameters '{"Schedule":"BusinessHours","Force":false}'
```

### 3. Get-VMPowerStateReport
Reports current power state of all VMs.

## 🎮 Usage Examples

```bash
# Get current status
az automation runbook start \
  --automation-account-name $(terraform output -raw automation_account_name) \
  --resource-group $(terraform output -raw resource_group_name) \
  --name "Get-VMPowerStateReport"

# Start development VMs (morning)
az automation runbook start \
  --automation-account-name $(terraform output -raw automation_account_name) \
  --resource-group $(terraform output -raw resource_group_name) \
  --name "Start-VMsByTag" \
  --parameters '{"Schedule":"BusinessHours"}'

# Stop development VMs (evening)
az automation runbook start \
  --automation-account-name $(terraform output -raw automation_account_name) \
  --resource-group $(terraform output -raw resource_group_name) \
  --name "Stop-VMsByTag" \
  --parameters '{"Schedule":"BusinessHours"}'
```

## 🔧 How It Works

1. **Tag your VMs** with `PowerSchedule` tag (AlwaysOn, BusinessHours, NightShutdown, etc.)
2. **Create schedules** in Automation Account to run runbooks at specific times
3. **Runbooks filter VMs** by PowerSchedule tag and start/stop them

### Architecture
```
Automation Account (Managed Identity)
  ├── Runbook: Start-VMsByTag
  ├── Runbook: Stop-VMsByTag
  └── Runbook: Get-VMPowerStateReport
       │
       ▼ (Queries VMs by tag)
       │
3 VMs with PowerSchedule tags:
  ├── vm-prod (AlwaysOn)
  ├── vm-dev (BusinessHours) ← Start at 8 AM, Stop at 6 PM
  └── vm-test (NightShutdown) ← Stop at 10 PM, Start at 6 AM
```

## 📝 Next Steps

1. **Add schedules** - Create recurring schedules in Portal
2. **Customize tags** - Add your own PowerSchedule values
3. **Add more VMs** - Apply PowerSchedule tags to existing VMs

## 💡 Production Tips

- Use **consistent tag names** across your organization
- Create **multiple schedules** for different regions/timezones
- Add **email notifications** when VMs are stopped
- Consider **Azure Advisor** recommendations

## 🧹 Cleanup

```bash
terraform destroy -auto-approve
```

---

**Deployment Time**: ~10 minutes  
**Terraform Version**: >= 1.0
