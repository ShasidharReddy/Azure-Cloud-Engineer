# 07 - Storage + Data Lake

    Creates a secure Azure Data Lake Storage Gen2 foundation with lifecycle automation, versioning, soft delete, private endpoints for blob and dfs, RBAC, diagnostics, and a basic Data Factory copy pipeline.

    ## Architecture

    ```mermaid
    flowchart LR
  Producers[Data Producers] --> Bronze[Bronze Container]
  Bronze --> ADF[Data Factory Pipeline]
  ADF --> Silver[Silver Container]
  Silver --> Gold[Gold Container]
  SA[ADLS Gen2 Storage] --> PE[Private Endpoints]
    ```

    ## Resources Created

    | Resource | Purpose |
    |---|---|
    | Storage Account | ADLS Gen2-enabled GPv2 storage with versioning and soft delete. |
| Blob Containers | Bronze, silver, and gold zones for staged data handling. |
| Lifecycle Policy | Moves older data to cool/archive and deletes stale objects. |
| Private Endpoints | Keep blob and dfs access on private IPs. |
| Private DNS Zones | Provide internal resolution for private endpoints. |
| Data Factory | Hosts a starter copy pipeline. |
| RBAC Assignments | Grant Storage Blob Data Contributor to selected principals. |
| Diagnostic Settings | Stream storage telemetry to Log Analytics. |

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
    | `location` | Deployment region. |
| `vnet_cidr` | Address space for private access. |
| `private_endpoint_subnet_cidr` | Subnet for private endpoints. |
| `soft_delete_retention_days` | Retention window for deleted blobs and containers. |

    ## Remote State

    Keep backend configuration external. The recommended production backend is Azure Storage with RBAC, soft delete, versioning, and state locking enabled.

    ## Cost Estimate

    Typically **USD 100-400+/month** depending on data volume, access patterns, and retention.

    ## Notes

    - Blob and DFS private endpoints are both created because ADLS Gen2 workloads often require both namespaces.
