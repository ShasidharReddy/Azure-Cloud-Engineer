# 02 - Multi-Region High Availability

    Builds an active/active Azure compute pattern across two regions with zonal VM placement, a regional load balancer in each region, global routing through Traffic Manager, VNet peering, and shared geo-redundant storage.

    ## Architecture

    ```mermaid
    flowchart TD
  Users[Global Users] --> TM[Traffic Manager]
  TM --> LB1[East US Load Balancer]
  TM --> LB2[West US 2 Load Balancer]
  LB1 --> VM1[Regional VMs]
  LB2 --> VM2[Regional VMs]
  VNet1[East US VNet] <-. Peering .-> VNet2[West US 2 VNet]
  VM1 --> GRS[GRS Shared Storage]
  VM2 --> GRS
    ```

    ## Resources Created

    | Resource | Purpose |
    |---|---|
    | Regional Resource Groups | Separate failure domains and simplify operations. |
| Regional VNets/Subnets | Provide isolated address spaces in both regions. |
| NSGs | Allow HTTP via Azure Load Balancer and controlled SSH. |
| Load Balancers | Distribute traffic across VMs in each region. |
| Traffic Manager | Provides global DNS-based failover. |
| Linux VM Fleet | Hosts the workload with simple bootstrap content. |
| GRS Storage Account | Shared geo-redundant storage. |
| VNet Peering | Enables private connectivity between regions. |

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
    | `regions` | Ordered list of deployment regions. |
| `vm_count_per_region` | Number of VMs per region. |
| `zones` | Availability zones for each region. |
| `region_cidrs` | Per-region network CIDRs. |
| `vm_size` | VM SKU. |
| `ssh_public_key` | Public key used for administration. |

    ## Remote State

    Keep backend configuration external. The recommended production backend is Azure Storage with RBAC, soft delete, versioning, and state locking enabled.

    ## Cost Estimate

    Typically **USD 300-700/month** depending on VM size, traffic, and retention.

    ## Notes

    - The cloud-init bootstrap installs NGINX so health probes have a valid endpoint.
- Tighten SSH ingress or replace it with Bastion for stronger control.
