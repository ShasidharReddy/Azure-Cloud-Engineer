# 05 - SQL Database High Availability

    Creates a cross-region Azure SQL topology with private endpoints, customer-managed transparent data encryption, diagnostics to Log Analytics, and a failover group for read/write continuity.

    ## Architecture

    ```mermaid
    flowchart LR
  Apps[Application Tier] --> PE1[Primary Private Endpoint]
  Apps --> PE2[Secondary Private Endpoint]
  PE1 --> SQL1[Primary SQL Server]
  PE2 --> SQL2[Secondary SQL Server]
  SQL1 <--> FOG[Failover Group]
  SQL1 --> KV[Key Vault CMK]
  SQL2 --> KV
    ```

    ## Resources Created

    | Resource | Purpose |
    |---|---|
    | Primary and Secondary Resource Groups | Separate SQL resources by region. |
| MSSQL Servers | Provide logical SQL endpoints in both regions. |
| Azure SQL Database | Hosts the workload database. |
| Failover Group | Coordinates automatic cross-region failover. |
| Key Vault + RSA Key | Backs customer-managed TDE protection. |
| Private Endpoints + Private DNS | Provide private connectivity and name resolution. |
| Diagnostic Settings | Send SQL logs and metrics to Log Analytics. |

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
    | `primary_location` | Primary Azure region. |
| `secondary_location` | Secondary/failover region. |
| `sql_administrator_login` | SQL admin username. |
| `sql_administrator_password` | SQL admin password. |
| `enable_elastic_pool` | Toggles elastic pool mode. |

    ## Remote State

    Keep backend configuration external. The recommended production backend is Azure Storage with RBAC, soft delete, versioning, and state locking enabled.

    ## Cost Estimate

    Typically **USD 500-1,500+/month** depending on SQL compute tier and retention.

    ## Notes

    - Keep public access disabled where possible and validate private DNS and routing before production use.
