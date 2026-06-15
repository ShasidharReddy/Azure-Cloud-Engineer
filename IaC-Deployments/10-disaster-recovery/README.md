# 10 - Disaster Recovery

    Creates a disaster-recovery baseline combining Azure Site Recovery for VM replication, a Recovery Services Vault, recovery plan automation runbooks, Traffic Manager DNS failover, geo-redundant storage, and a SQL failover group.

    ## Architecture

    ```mermaid
    flowchart LR
  Primary[Primary Region] --> ASR[Azure Site Recovery]
  ASR --> Recovery[Recovery Region]
  Recovery --> Plan[Recovery Plan]
  Plan --> Runbooks[Automation Runbooks]
  Primary --> TM[Traffic Manager]
  Recovery --> TM
  Primary --> SQL1[Primary SQL]
  Recovery --> SQL2[Secondary SQL]
    ```

    ## Resources Created

    | Resource | Purpose |
    |---|---|
    | Recovery Services Vault | Stores Site Recovery configuration and failover metadata. |
| Site Recovery Fabrics and Containers | Model source and target replication boundaries. |
| Replication Policy | Defines retention and snapshot behavior. |
| Replicated VM | Protects an existing VM into the recovery region. |
| Recovery Plan | Bundles failover sequencing with automation actions. |
| Automation Account + Runbooks | Provide pre-check and post-failover automation. |
| Traffic Manager | Supplies DNS failover across public endpoints. |
| GRS Cache Storage | Supports Site Recovery staging requirements. |
| SQL Failover Group | Adds managed database continuity to the DR design. |

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
    | `source_vm_id` | Existing VM protected by Site Recovery. |
| `source_os_disk_id` | OS disk ID of the protected VM. |
| `source_network_interface_id` | NIC ID used for failover networking. |
| `primary_public_ip_resource_id` | Primary public IP used by Traffic Manager. |
| `secondary_public_ip_resource_id` | Secondary public IP used by Traffic Manager. |

    ## Remote State

    Keep backend configuration external. The recommended production backend is Azure Storage with RBAC, soft delete, versioning, and state locking enabled.

    ## Cost Estimate

    Typically **USD 300-1,200+/month** depending on replicated disk volume, Site Recovery usage, and SQL sizing.

    ## Notes

    - This project assumes the source VM already exists. Provide VM, disk, and NIC IDs in tfvars before planning.
