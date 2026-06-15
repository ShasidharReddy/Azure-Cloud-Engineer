# 09 - Landing Zone Base

    Builds a governance-first Azure landing-zone skeleton with a three-branch management group hierarchy, custom policy definitions and assignments, role assignments, activity-log forwarding, and subscription budget controls.

    ## Architecture

    ```mermaid
    flowchart TD
  Root[Root / Parent MG] --> Platform[Platform MG]
  Root --> Workloads[Workloads MG]
  Root --> Sandbox[Sandbox MG]
  Platform --> Policies[Custom Policies]
  Workloads --> Policies
  Subscription[Activity Logs] --> LAW[Governance Log Analytics]
    ```

    ## Resources Created

    | Resource | Purpose |
    |---|---|
    | Management Groups | Creates Platform, Workloads, and Sandbox branches beneath an existing root or parent MG. |
| Custom Policy Definitions | Implements allowed locations, required tags, and deny-public-IP guardrails. |
| Policy Assignments | Applies custom controls to the intended scopes. |
| RBAC Assignments | Seeds management-group-level access. |
| Log Analytics Workspace | Receives governance and activity telemetry. |
| Subscription Budget | Provides cost alerting. |

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
    | `root_management_group_id` | Parent management group that will own the hierarchy. |
| `allowed_locations` | Approved Azure regions. |
| `required_tags` | Tag keys enforced by policy. |
| `platform_owner_principal_id` | Optional platform owner principal. |

    ## Remote State

    Keep backend configuration external. The recommended production backend is Azure Storage with RBAC, soft delete, versioning, and state locking enabled.

    ## Cost Estimate

    Typically **USD 20-100+/month** driven mostly by Log Analytics ingestion.

    ## Notes

    - Apply this project with identities that have management-group, policy, and RBAC privileges in the target tenant.
