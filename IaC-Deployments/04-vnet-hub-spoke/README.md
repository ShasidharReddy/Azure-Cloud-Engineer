# 04 - VNet Hub-Spoke

    Creates an enterprise-ready hub-spoke networking pattern with centralized ingress, egress, and management services in the hub while forcing spoke traffic through Azure Firewall.

    ## Architecture

    ```mermaid
    flowchart LR
  OnPrem[On-Prem / Branch] --> VPN[VPN Gateway]
  Admins[Admins] --> Bastion[Azure Bastion]
  Bastion --> Hub[Hub VNet]
  Hub --> Firewall[Azure Firewall]
  Firewall --> Apps[Apps Spoke]
  Firewall --> Data[Data Spoke]
  Firewall --> Shared[Shared Spoke]
    ```

    ## Resources Created

    | Resource | Purpose |
    |---|---|
    | Hub VNet | Contains shared network services and management paths. |
| Azure Firewall | Provides centralized inspection and routing. |
| Azure Bastion | Secure browser-based admin access. |
| VPN Gateway | Supports branch/on-prem connectivity expansion. |
| Spoke VNets | Separate workload address spaces. |
| Route Tables | Force outbound traffic from spokes through the firewall. |
| NSGs | Apply subnet-level control per spoke. |
| Diagnostic Settings | Forward logs to Log Analytics. |

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
    | `hub_vnet_cidr` | Address space for the hub VNet. |
| `hub_subnets` | CIDRs for hub service subnets. |
| `spoke_vnets` | Map of spoke address spaces and workload subnets. |
| `firewall_sku_tier` | Firewall tier. |
| `vpn_gateway_sku` | VPN gateway SKU. |

    ## Remote State

    Keep backend configuration external. The recommended production backend is Azure Storage with RBAC, soft delete, versioning, and state locking enabled.

    ## Cost Estimate

    Typically **USD 900-2,500+/month** because Firewall, Bastion, and VPN Gateway are premium services.

    ## Notes

    - Add firewall policy rule collections and VPN connections as follow-on steps.
