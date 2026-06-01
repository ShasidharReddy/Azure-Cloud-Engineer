# Azure Cloud Engineer — Reference & Lab Notes

A curated collection of Azure command references, architecture diagrams, scripts, and step-by-step guides covering core Azure services. Organized by topic — use this as a quick reference while working on Azure projects.

---

## 📁 Directory Structure

| Directory | Description |
|-----------|-------------|
| [`Architecture/`](./Architecture/) | 🔷 **Visual diagrams** — 20+ Mermaid flow diagrams for all major Azure services |
| [`Networking/`](./Networking/) | VNet, NSGs, Azure Firewall, ExpressRoute, VPN Gateway, Front Door, Traffic Manager, Private Link |
| [`IAM-Security/`](./IAM-Security/) | Entra ID, RBAC, Managed Identities, PIM, Key Vault, Defender, Sentinel, Policy |
| [`Compute/`](./Compute/) | VMs, VMSS, App Service, Managed Disks, Availability Sets/Zones, Batch, Bastion |
| [`Storage/`](./Storage/) | Blob, Files, ADLS Gen2, Managed Disks, Data Box, Backup, Site Recovery |
| [`Database/`](./Database/) | Azure SQL, Cosmos DB, PostgreSQL, MySQL, Redis Cache, Synapse, DMS |
| [`Monitoring/`](./Monitoring/) | Azure Monitor, Log Analytics, Application Insights, Network Watcher, Managed Grafana |
| [`DataPipeline/`](./DataPipeline/) | Data Factory, Synapse, Event Hubs, Service Bus, Databricks, Stream Analytics, Purview |
| [`CostOptimization/`](./CostOptimization/) | Reserved Instances, Savings Plans, Spot VMs, Hybrid Benefit, Cost Management, FinOps |
| [`Serverless/`](./Serverless/) | Functions, Logic Apps, Event Grid, APIM, Container Apps, Static Web Apps, Durable Functions |
| [`Containers/`](./Containers/) | AKS, Container Apps, ACI, ACR, ARO, Service Mesh, KEDA |
| [`Migration/`](./Migration/) | Azure Migrate, DMS, Site Recovery, Data Box, AWS/GCP → Azure mapping |
| [`CICD/`](./CICD/) | Azure DevOps, Pipelines, Bicep, ARM Templates, Terraform, GitHub Actions |

---

## 🚀 Quick Start

### Prerequisites

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed and configured
- An Azure subscription:
  ```bash
  az login
  az account set --subscription "YOUR_SUBSCRIPTION_ID"
  az account show
  ```

### Recommended Reading Order

1. Start with [`Architecture/`](./Architecture/) for visual overview of all services
2. Explore [`Compute/`](./Compute/) for VMs, VMSS, and App Service
3. Review [`Networking/`](./Networking/) for VNets, NSGs, and connectivity
4. Use the topic directories for specific service deep-dives

---

## 🏷️ Topics Covered

`Virtual Machines` · `VMSS` · `App Service` · `VNet` · `NSG` · `Azure Firewall` · `Entra ID` · `RBAC` · `Key Vault` · `Blob Storage` · `ADLS Gen2` · `Azure SQL` · `Cosmos DB` · `Azure Monitor` · `Log Analytics` · `Application Insights` · `AKS` · `Container Apps` · `Azure Functions` · `Logic Apps` · `Event Grid` · `Data Factory` · `Synapse Analytics` · `Databricks` · `Event Hubs` · `Service Bus` · `Azure DevOps` · `Bicep` · `ARM Templates` · `Terraform` · `ExpressRoute` · `Front Door` · `Application Gateway` · `Traffic Manager` · `Azure Migrate` · `Site Recovery` · `Cost Management` · `Defender for Cloud` · `Sentinel` · `Policy`

---

## 🔷 Visual Diagrams

This repo includes **Mermaid flow diagrams** that render directly on GitHub — no images needed. See [`Architecture/`](./Architecture/) for:

- Azure Global Infrastructure (Regions, AZs, Region Pairs, Edge Zones)
- Compute decision tree (VMs vs App Service vs AKS vs Functions vs Container Apps)
- VM lifecycle state diagram
- VNet multi-AZ architecture with Azure Firewall
- Application Gateway / Front Door request flow
- Azure Storage account tiers and lifecycle
- AKS cluster architecture
- Azure Functions event-driven sequence flow
- Azure SQL HA and Cosmos DB global distribution
- Entra ID / RBAC hierarchy
- Azure DevOps CI/CD pipeline
- 3-tier web application reference architecture
- Data lake architecture (ADLS Gen2 → Synapse → Power BI)
- Disaster recovery with Site Recovery
- Well-Architected Framework pillars
- On-premises and cross-cloud migration flows

---

## 📝 Notes

- All guides include practical `az` CLI commands — replace placeholder values before running.
- Each guide includes Mermaid diagrams, best practices, and comparison tables.
- Guides are for **learning and reference** purposes — review before running in production.
