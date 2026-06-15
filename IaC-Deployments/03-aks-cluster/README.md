# 03 - AKS Cluster

    Deploys a production-oriented AKS baseline with isolated networking, Microsoft Entra-backed RBAC, Azure CNI, Calico network policy, system and user node pools, ACR integration, Key Vault CSI, and Container Insights.

    ## Architecture

    ```mermaid
    flowchart LR
  Devs[Platform Engineers] --> AKS[AKS Cluster]
  AKS --> SystemPool[System Node Pool]
  AKS --> UserPool[User Node Pool]
  AKS --> LAW[Log Analytics]
  AKS --> ACR[Azure Container Registry]
  AKS --> KV[Key Vault]
  AKS --> VNet[VNet/Subnets]
  AKS --> Entra[Microsoft Entra RBAC]
    ```

    ## Resources Created

    | Resource | Purpose |
    |---|---|
    | Resource Group | Hosts all AKS platform resources. |
| AKS Cluster | Managed Kubernetes control plane with Azure Policy and workload identity. |
| System Node Pool | Runs critical add-ons and infrastructure workloads. |
| User Node Pool | Autoscaled workload pool for application pods. |
| Container Registry | Private image registry with AcrPull granted to AKS. |
| Key Vault | Secrets store used with the CSI provider pattern. |
| Log Analytics Workspace | Receives Container Insights telemetry. |
| VNet + Subnets | Provides Azure CNI IP allocation and private endpoint space. |

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
    | `private_cluster_enabled` | Controls private API endpoint behavior. |
| `kubernetes_version` | Pinned AKS version. |
| `admin_group_object_ids` | Entra groups granted cluster admin access. |
| `system_node_count` | System-pool node count. |
| `user_node_pool_min_count` | Minimum user-pool size. |
| `user_node_pool_max_count` | Maximum user-pool size. |

    ## Remote State

    Keep backend configuration external. The recommended production backend is Azure Storage with RBAC, soft delete, versioning, and state locking enabled.

    ## Cost Estimate

    Typically **USD 450-1,000+/month** depending on node sizes, counts, and log retention.

    ## Notes

    - Validate API reachability and DNS before enabling private clusters in production.
- Add GitOps, ingress, and CSI SecretProviderClass manifests as follow-on platform work.
