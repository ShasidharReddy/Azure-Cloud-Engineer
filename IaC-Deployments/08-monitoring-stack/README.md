# 08 - Monitoring Stack

    Deploys a centralized observability baseline with Log Analytics, workspace-based Application Insights, an action group, metric and KQL alerts, diagnostic settings, a workbook, and a budget alert.

    ## Architecture

    ```mermaid
    flowchart LR
  Resources[Azure Resources] --> Diag[Diagnostic Settings]
  Diag --> LAW[Log Analytics]
  Apps[Applications] --> AI[Application Insights]
  AI --> LAW
  LAW --> Alerts[Metric and Log Alerts]
  Alerts --> AG[Action Group]
    ```

    ## Resources Created

    | Resource | Purpose |
    |---|---|
    | Log Analytics Workspace | Central log store for platform and application telemetry. |
| Application Insights | Workspace-based app monitoring target. |
| Action Group | Routes notifications to email, SMS, and webhooks. |
| Metric Alerts | Monitor CPU, memory, and disk signals. |
| Scheduled Query Alerts | Run KQL-based heartbeat and exception detection. |
| Diagnostic Settings | Stream logs and metrics from arbitrary Azure resources. |
| Workbook | Provides a starting dashboard for operations teams. |
| Budget | Raises cost-awareness for the monitoring resource group. |

    ## Usage

    ```bash
    terraform fmt
    terraform init
    cp terraform.tfvars.example terraform.tfvars
    terraform plan -out tfplan
    terraform apply tfplan
    ```

    ## Key Variables

    | Variable | Description |
    |---|---|
    | `vm_resource_ids` | VMs watched by metric alerts. |
| `diagnostic_resource_ids` | Resources sending diagnostics to Log Analytics. |
| `email_receivers` | Email recipients in the action group. |
| `webhook_receivers` | Webhook integrations for incident tooling. |

    ## Remote State

    Keep backend configuration external. The recommended production backend is Azure Storage with RBAC, soft delete, versioning, and state locking enabled.

    ## Cost Estimate

    Typically **USD 50-300+/month** depending mostly on data ingestion and retention.

    ## Notes

    - Adjust memory and disk metric namespaces to match your VM Insights or guest-metric standard.
