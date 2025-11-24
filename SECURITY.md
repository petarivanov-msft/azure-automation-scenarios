# Security Policy

## Reporting Security Vulnerabilities

If you discover a security vulnerability in this project, please report it by sending an email to the repository maintainers. Please do not report security vulnerabilities through public GitHub issues.

### What to Include

When reporting a security issue, please include:

- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact
- Suggested fix (if available)

## Security Best Practices

This lab environment is designed for **learning and demonstration purposes**. When adapting this code for production use, consider the following security best practices:

### Authentication & Authorization

- **Managed Identities**: Always use managed identities instead of service principals with client secrets
- **RBAC**: Apply principle of least privilege - grant only necessary permissions
- **Graph API Permissions**: Review and limit permissions to only what's required
- **Key Rotation**: Regularly rotate VM passwords and any stored credentials

### Network Security

- **Network Isolation**: Consider using private endpoints for Automation Accounts
- **NSG Rules**: Restrict network access to VMs using Network Security Groups
- **Public IPs**: Avoid exposing VMs with public IPs in production environments
- **VNet Integration**: Use VNet integration for secure communication

### Data Protection

- **Sensitive Data**: Never store secrets, passwords, or sensitive data in runbooks or variables
- **Azure Key Vault**: Use Azure Key Vault for storing and retrieving secrets
- **Encryption**: Enable encryption at rest for all data stores
- **Logging**: Be careful not to log sensitive information in runbook outputs

### Infrastructure Security

- **Terraform State**: Secure Terraform state files (use Azure Storage with encryption)
- **Resource Locks**: Apply resource locks to prevent accidental deletion
- **Tags**: Use tags for resource management and cost allocation
- **Auto-shutdown**: Implement auto-shutdown policies for non-production resources

### Operational Security

- **Monitoring**: Enable Azure Monitor and Log Analytics for security monitoring
- **Alerts**: Configure alerts for unusual activities
- **Updates**: Keep all modules and dependencies up to date
- **Audit Logs**: Regularly review Azure Activity Logs and Automation job history

## Known Limitations

1. **VM Passwords**: This lab generates and stores VM passwords in Terraform state. In production, use Azure Key Vault or managed identities.

2. **Public Network Access**: VMs are deployed with public IPs for easy access. In production, use Azure Bastion or VPN.

3. **Graph API Permissions**: This lab requires elevated Entra ID permissions. In production, carefully review and limit API permissions.

4. **Development Environment**: This is a lab environment. Production deployments should include additional security hardening.

## Compliance

- Review your organization's compliance requirements before deployment
- Ensure data residency requirements are met by selecting appropriate Azure regions
- Document and review all permissions and access controls
- Maintain audit logs as required by your compliance framework

## Support

For security-related questions or concerns, please open an issue on GitHub or contact the maintainers directly.
