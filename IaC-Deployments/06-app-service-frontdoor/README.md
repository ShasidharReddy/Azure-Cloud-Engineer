# 06 - App Service + Front Door

    Deploys a globally distributed web application platform with two regional App Service instances fronted by Azure Front Door Standard, protected by WAF, instrumented with Application Insights, and scaled automatically based on CPU.

    ## Architecture

    ```mermaid
    flowchart TD
  Users[Global Users] --> AFD[Azure Front Door]
  AFD --> WAF[WAF Policy]
  AFD --> App1[Primary App Service]
  AFD --> App2[Secondary App Service]
  App1 --> Slot1[Staging Slot]
  App2 --> Slot2[Staging Slot]
    ```

    ## Resources Created

    | Resource | Purpose |
    |---|---|
    | Regional Service Plans | Host the web apps in two Azure regions. |
| Linux Web Apps | Run the application workload with HTTPS-only enforcement. |
| Staging Slots | Support safer deployment swaps. |
| Autoscale Settings | Scale App Service Plans up or down using CPU thresholds. |
| Application Insights | Collect regional application telemetry. |
| Front Door Standard | Provides global anycast entry and origin routing. |
| WAF Policy | Applies managed rule protection in prevention mode. |
| Optional DNS + Custom Domain | Supports custom hostnames and managed TLS. |

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
    | `primary_location` | Primary deployment region. |
| `secondary_location` | Secondary deployment region. |
| `app_service_sku` | Plan SKU for App Services. |
| `enable_custom_domain` | Toggles custom domain and Azure DNS resources. |
| `dns_zone_name` | Azure DNS zone name when custom domain is enabled. |

    ## Remote State

    Keep backend configuration external. The recommended production backend is Azure Storage with RBAC, soft delete, versioning, and state locking enabled.

    ## Cost Estimate

    Typically **USD 350-900+/month** depending on App Service sizing, Front Door traffic, and retention.

    ## Notes

    - Azure Front Door Standard is used instead of Front Door Classic because Standard/Premium is the current production path.
