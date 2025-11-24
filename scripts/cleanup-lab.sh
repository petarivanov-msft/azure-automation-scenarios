#!/bin/bash

# ============================================================================
# Azure Automation Scenarios Lab - Cleanup Script
# ============================================================================
# This script helps you clean up the deployed lab resources
# ============================================================================

set -e

# Color codes
CYAN='\e[96m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Azure Automation Lab - Cleanup${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "terraform.tfvars" ] && [ ! -f "../terraform/terraform.tfvars" ]; then
  echo -e "${RED}Error: terraform.tfvars not found.${NC}"
  echo -e "${YELLOW}Please run this script from the terraform directory or repository root.${NC}"
  exit 1
fi

# Navigate to terraform directory if needed
if [ -f "terraform.tfvars" ]; then
  TERRAFORM_DIR="."
else
  TERRAFORM_DIR="../terraform"
  cd "$TERRAFORM_DIR"
fi

echo -e "${YELLOW}⚠️  WARNING: This will destroy all resources created by this lab!${NC}"
echo ""

# Show what will be destroyed
if [ -f "terraform.tfstate" ]; then
  echo -e "${CYAN}Resources to be destroyed:${NC}"
  terraform show -json | jq -r '.values.root_module.resources[].address' 2>/dev/null || echo "  (Run terraform plan to see resources)"
  echo ""
fi

read -rp "$(echo -e "${RED}Are you sure you want to destroy all resources? (yes/no): ${NC}")" confirm

if [ "$confirm" == "yes" ]; then
  echo ""
  echo -e "${CYAN}Destroying resources...${NC}"
  terraform destroy -auto-approve
  
  echo ""
  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN}Cleanup completed successfully!${NC}"
  echo -e "${GREEN}========================================${NC}"
  echo ""
  echo -e "${CYAN}All lab resources have been removed.${NC}"
  echo ""
else
  echo -e "${YELLOW}Cleanup cancelled.${NC}"
fi
