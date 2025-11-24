#!/bin/bash

# ============================================================================
# Azure Automation Scenarios Lab - Initialization Script
# ============================================================================
# This script collects Azure input values and deploys the lab environment
# 
# ❗ No data is ever sent or uploaded back to GitHub or anywhere else.
# ❗ No telemetry, logging, or push occurs.
# ✅ All data remains local to your current shell session.
# ============================================================================

set -e

# Color codes
CYAN='\e[96m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ============================================================================
# Functions
# ============================================================================

register_provider() {
  local ns=$1
  local status=$(az provider show --namespace "$ns" --query "registrationState" -o tsv 2>/dev/null || echo "NotRegistered")

  if [ "$status" != "Registered" ]; then
    echo -e "${CYAN}Registering provider: ${YELLOW}$ns${CYAN}...${NC}"
    az provider register --namespace "$ns"
    until [ "$(az provider show --namespace "$ns" --query "registrationState" -o tsv)" == "Registered" ]; do
      echo -e "${CYAN}Waiting for ${YELLOW}$ns${CYAN} registration...${NC}"
      sleep 5
    done
    echo -e "${GREEN}Provider ${YELLOW}$ns${GREEN} registered successfully.${NC}"
  else
    echo -e "${GREEN}Provider ${YELLOW}$ns${GREEN} already registered.${NC}"
  fi
}

prompt_input() {
  local prompt_msg=$1
  local var_name=$2
  local current_value="${!var_name}"
  
  if [ -n "$current_value" ]; then
    read -rp "$(echo -e "${CYAN}$prompt_msg ${YELLOW}[$current_value]${CYAN}: ${NC}")" input
    if [ -n "$input" ]; then
      eval $var_name="$input"
    fi
  else
    while [ -z "${!var_name}" ]; do
      read -rp "$(echo -e "${CYAN}$prompt_msg: ${NC}")" $var_name
    done
  fi
}

# ============================================================================
# Main Script
# ============================================================================

echo -e "${BLUE}========================================${NC}"
echo -e "${CYAN}Azure Automation Scenarios Lab${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Clone the repo (skip if already cloned)
if [ ! -d "azure-automation-scenarios" ]; then
  echo -e "${CYAN}Cloning repository...${NC}"
  git clone https://github.com/petarivanov-msft/azure-automation-scenarios.git
fi

cd azure-automation-scenarios

# Set default values
RESOURCE_GROUP="rg-automation-lab"
LOCATION="eastus"
AUTOMATION_ACCOUNT="auto-lab-$(date +%s)"
VM_ADMIN_USERNAME="azureadmin"

# Register necessary Azure providers
echo -e "${CYAN}Registering Azure providers...${NC}"
for ns in Microsoft.Automation Microsoft.Compute Microsoft.Network; do
  register_provider "$ns"
done

echo ""
echo -e "${CYAN}🔧 Configuration Setup${NC}"
echo -e "${CYAN}Please provide the following configuration values:${NC}"
echo ""

# Prompt for deployment parameters
prompt_input "Enter the name for the Azure Resource Group" RESOURCE_GROUP
prompt_input "Enter the Azure region (e.g., eastus, westus2)" LOCATION
prompt_input "Enter the Automation Account name" AUTOMATION_ACCOUNT
prompt_input "Enter VM admin username" VM_ADMIN_USERNAME

# Generate a secure password for VMs
echo ""
echo -e "${CYAN}Generating secure password for VMs...${NC}"
VM_ADMIN_PASSWORD=$(openssl rand -base64 16)

# Scenario selection
echo ""
echo -e "${CYAN}Select which scenarios to deploy:${NC}"
echo -e "${YELLOW}1. Graph API Automation (requires elevated permissions)${NC}"
echo -e "${YELLOW}2. Start/Stop VMs with Tag-Based Scheduling${NC}"
echo -e "${YELLOW}3. PowerShell 7.4 Runtime Environment${NC}"
echo -e "${YELLOW}4. Hybrid Worker Setup${NC}"
echo ""
read -rp "$(echo -e "${CYAN}Enable Graph API scenario? (y/n) [y]: ${NC}")" enable_graph
enable_graph=${enable_graph:-y}
ENABLE_GRAPH_API=$([ "$enable_graph" == "y" ] && echo "true" || echo "false")

read -rp "$(echo -e "${CYAN}Enable Start/Stop VMs scenario? (y/n) [y]: ${NC}")" enable_startstop
enable_startstop=${enable_startstop:-y}
ENABLE_STARTSTOP_VMS=$([ "$enable_startstop" == "y" ] && echo "true" || echo "false")

read -rp "$(echo -e "${CYAN}Enable PowerShell 7.4 scenario? (y/n) [y]: ${NC}")" enable_ps74
enable_ps74=${enable_ps74:-y}
ENABLE_POWERSHELL74=$([ "$enable_ps74" == "y" ] && echo "true" || echo "false")

read -rp "$(echo -e "${CYAN}Enable Hybrid Worker scenario? (y/n) [y]: ${NC}")" enable_hybrid
enable_hybrid=${enable_hybrid:-y}
ENABLE_HYBRID_WORKER=$([ "$enable_hybrid" == "y" ] && echo "true" || echo "false")

# Create terraform.tfvars file
echo ""
echo -e "${CYAN}Creating terraform configuration file...${NC}"
cd terraform

cat > terraform.tfvars <<EOF
resource_group_name     = "$RESOURCE_GROUP"
location                = "$LOCATION"
automation_account_name = "$AUTOMATION_ACCOUNT"
vm_admin_username       = "$VM_ADMIN_USERNAME"
vm_admin_password       = "$VM_ADMIN_PASSWORD"

# Scenario toggles
enable_graph_api       = $ENABLE_GRAPH_API
enable_startstop_vms   = $ENABLE_STARTSTOP_VMS
enable_powershell74    = $ENABLE_POWERSHELL74
enable_hybrid_worker   = $ENABLE_HYBRID_WORKER
EOF

echo -e "${GREEN}Configuration file created successfully!${NC}"
echo ""

# Initialize Terraform
echo -e "${CYAN}Initializing Terraform...${NC}"
terraform init

# Run Terraform plan
echo ""
echo -e "${CYAN}Generating deployment plan...${NC}"
terraform plan -out=tfplan

# Apply Terraform
echo ""
read -rp "$(echo -e "${YELLOW}Deploy the lab environment? (yes/no): ${NC}")" confirm
if [ "$confirm" == "yes" ]; then
  echo -e "${CYAN}Deploying lab environment...${NC}"
  echo -e "${YELLOW}This will take approximately 15-25 minutes...${NC}"
  terraform apply tfplan
  
  echo ""
  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN}Deployment completed successfully!${NC}"
  echo -e "${GREEN}========================================${NC}"
  echo ""
  echo -e "${CYAN}Resource Group:${NC} $RESOURCE_GROUP"
  echo -e "${CYAN}Location:${NC} $LOCATION"
  echo -e "${CYAN}Automation Account:${NC} $AUTOMATION_ACCOUNT"
  echo ""
  echo -e "${YELLOW}🔐 VM Credentials:${NC}"
  echo -e "  Username: $VM_ADMIN_USERNAME"
  echo -e "  Password: (saved in terraform.tfvars, retrieve with: terraform output -raw vm_admin_password)"
  echo ""
  echo -e "${CYAN}View all outputs:${NC} terraform output"
  echo ""
  echo -e "${YELLOW}⚠️  Remember to clean up resources when done:${NC}"
  echo -e "  cd $(pwd)"
  echo -e "  terraform destroy -auto-approve"
  echo ""
else
  echo -e "${YELLOW}Deployment cancelled.${NC}"
  rm -f tfplan
fi
