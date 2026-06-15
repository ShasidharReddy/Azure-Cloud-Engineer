# 01 - Single VM

    Deploys a production-ready single Ubuntu VM baseline with its own network, security, premium disks, and boot diagnostics storage.

    ## Architecture

    ```mermaid
    flowchart LR
  Admin[Administrator] --> PIP[Public IP]
  PIP --> NIC[Network Interface]
  NIC --> VM[Ubuntu 22.04 VM]
  VM --> OSDisk[Premium SSD OS Disk]
  VM --> DataDisk[Managed Data Disk]
  NIC --> Subnet[Subnet]
  Subnet --> NSG[NSG with SSH/RDP]
  Subnet --> VNet[VNet]
  VM --> BootDiag[Boot Diagnostics Storage]
    ```

    ## Resources Created

    | Resource | Purpose |
    |---|---|
    | Resource Group | Logical container for all resources. |
| Virtual Network + Subnet | Private networking foundation for the VM. |
| Network Security Group | Allows SSH and optional RDP access. |
| Public IP + NIC | Provides external reachability. |
| Linux Virtual Machine | Ubuntu 22.04 Gen2 compute instance. |
| Managed Disks | Premium OS disk plus separate data disk. |
| Storage Account | Boot diagnostics storage. |

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
    | `subscription_id` | Target Azure subscription ID. |
| `vm_name` | Name of the Linux VM. |
| `location` | Region for the deployment. |
| `vm_size` | Azure compute SKU. |
| `admin_username` | Linux admin user. |
| `ssh_public_key` | Public key for access. |
| `vnet_cidr` | Address space for the VNet. |
| `subnet_cidr` | Address range for the subnet. |

    ## Remote State

    Keep backend configuration external. The recommended production backend is Azure Storage with RBAC, soft delete, versioning, and state locking enabled.

    ## Cost Estimate

    Typically **USD 80-160/month** depending on VM size and disk sizing.

    ## Notes

    - The NSG includes an RDP rule only because some teams reuse a shared baseline across Linux and Windows fleets.
- Tighten source ranges before production use.
