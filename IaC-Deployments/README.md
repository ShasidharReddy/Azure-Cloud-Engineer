# Azure Terraform IaC Deployments

This directory contains ten self-contained Terraform deployment projects for Microsoft Azure. Each folder includes complete `main.tf`, `variables.tf`, `outputs.tf`, `terraform.tfvars.example`, and project-specific documentation so you can use the examples directly and adapt them to your platform standards.

## Prerequisites

- Terraform `>= 1.6`
- Azure CLI authenticated to the correct tenant and subscription
- An Azure subscription with permissions suitable for the selected project
- Access to an Azure Storage backend if you plan to store state remotely
- Network connectivity to Azure Resource Manager and any private DNS, Key Vault, or remote-state dependencies

## How To Use

1. Clone the repository.
2. Change into the required project folder.
3. Copy `terraform.tfvars.example` to `terraform.tfvars`.
4. Update subscription, naming, CIDRs, credentials, and optional feature values.
5. Run Terraform init, plan, and apply.

```bash
git clone <repo-url>
cd Azure-Cloud-Engineer/IaC-Deployments/01-single-vm
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

## Common Commands Reference

```bash
terraform fmt -recursive
terraform init
terraform init -upgrade
terraform validate
terraform plan
terraform plan -out tfplan
terraform apply tfplan
terraform apply -auto-approve
terraform destroy
terraform output
terraform state list
```

## Remote State Best Practices

Do not keep production Terraform state only on a laptop. These examples intentionally **do not** hardcode a backend so you can bind each workload to the correct landing zone, subscription, and storage account.

Example backend block for Azure Storage:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-prod"
    storage_account_name = "sttfstateprod001"
    container_name       = "tfstate"
    key                  = "01-single-vm/terraform.tfstate"
    use_azuread_auth     = true
  }
}
```

Recommended backend practices:

- separate state keys by workload and environment
- use RBAC instead of shared storage keys where possible
- enable versioning and blob soft delete
- restrict access with firewalls or private endpoints
- emit diagnostics from the state storage account
- protect backend changes with peer review and CI/CD

## Project Catalog

| Project | Description | Complexity |
|---|---|---|
| `01-single-vm` | Single Ubuntu VM with networking, NSG, public IP, premium OS disk, data disk, and diagnostics storage | Foundation |
| `02-multi-region-ha` | Dual-region VM fleet with zonal placement, load balancers, Traffic Manager, VNet peering, and GRS storage | Advanced |
| `03-aks-cluster` | AKS with Azure CNI, system and user node pools, ACR, Entra ID RBAC, CSI, and monitoring | Advanced |
| `04-vnet-hub-spoke` | Enterprise hub-spoke topology with Azure Firewall, Bastion, VPN Gateway, route tables, and diagnostics | Advanced |
| `05-sql-database-ha` | Azure SQL primary/secondary pattern with failover groups, private endpoints, CMK TDE, and auditing | Advanced |
| `06-app-service-frontdoor` | Two-region App Service deployment fronted by Azure Front Door Standard and WAF | Intermediate |
| `07-storage-data-lake` | ADLS Gen2 baseline with lifecycle, versioning, private endpoints, RBAC, diagnostics, and Data Factory | Intermediate |
| `08-monitoring-stack` | Log Analytics, Application Insights, alerts, workbook, diagnostics, and budget controls | Intermediate |
| `09-landing-zone-base` | Management groups, custom policy, RBAC, activity logs, and budget controls | Advanced |
| `10-disaster-recovery` | Recovery Services Vault, Site Recovery, recovery plans, Traffic Manager, and SQL failover | Advanced |

## Suggested Team Workflow

1. `terraform fmt -recursive`
2. `terraform init -backend=false`
3. `terraform validate`
4. `terraform plan`
5. peer review and approval
6. `terraform apply`

## Operational Guidance

- review SKU availability in the target region before applying
- replace placeholder passwords, object IDs, and DNS domains
- constrain source ranges for administrative ports
- use Key Vault or pipeline secrets instead of storing secrets in plaintext
- enable diagnostics early so troubleshooting is easier later
- test failover, scaling, and rollback procedures before production rollout

## Cleanup

```bash
terraform plan -destroy
terraform destroy
```

Validate dependencies such as DNS, peerings, private endpoints, and policy assignments before destroying shared resources.
