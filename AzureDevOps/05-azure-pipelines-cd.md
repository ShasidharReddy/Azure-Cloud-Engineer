> **Screenshot Disclaimer:** Screenshots in this guide are sourced from [Microsoft Learn](https://learn.microsoft.com/en-us/azure/devops/) documentation. © Microsoft Corporation. All rights reserved. Used here for educational and reference purposes only. For the latest UI and features, always refer to the official documentation.

# 05 Azure Pipelines CD

Continuous delivery in Azure Pipelines turns validated artifacts into controlled deployments. This guide explains how to model environments, use approvals and checks, design rollout strategies, and keep rollback and deployment evidence strong enough for production operations.

> [!NOTE]
> Delivery speed and delivery safety can coexist. The key is to make approvals, checks, and post-deployment validation explicit rather than manual and improvised.

> [!TIP]
> Name environments after the way operations teams actually think about them: dev, test, staging, production, regional production, or ephemeral review. Clear names make approval history and troubleshooting easier.

> [!IMPORTANT]
> Production deployment should never depend on personal credentials or hidden tribal knowledge. Use reviewed YAML, service connections, environment checks, and documented rollback paths.

## Guide objectives

- Model delivery around real environments and promotion boundaries.
- Use service connections, checks, and approvals safely.
- Choose rollout strategies that match workload risk and architecture.
- Capture deployment evidence that supports operations and audit review.

## Microsoft Learn screenshots

> ![Azure Resource Manager service connection subscription selection](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/media/azure-resource-manager-subscription.png)
>
> *Screenshot source: [Microsoft Learn — Use an Azure Resource Manager service connection](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/connect-to-azure?view=azure-devops). © Microsoft Corporation. Used for educational reference only.*

> ![Azure overview page for Azure Pipelines service connection creation](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/media/azure-overview-page.png)
>
> *Screenshot source: [Microsoft Learn — Use an Azure Resource Manager service connection](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/connect-to-azure?view=azure-devops). © Microsoft Corporation. Used for educational reference only.*

> ![Azure DevOps project dashboard overview](https://learn.microsoft.com/en-us/azure/devops/user-guide/media/dashboard-overview.png)
>
> *Screenshot source: [Microsoft Learn — What is Azure DevOps?](https://learn.microsoft.com/en-us/azure/devops/user-guide/what-is-azure-devops?view=azure-devops). © Microsoft Corporation. Used for educational reference only.*

## Prerequisites

- A CI pipeline that publishes a versioned artifact or package.
- Approved Azure service connections or deployment identities.
- Defined target environments and approver groups.
- Observability signals that indicate whether a deployment is healthy.

## Quick decision guide

| Decision area | Why it matters | Recommended baseline |
|---|---|---|
| Environment model | Defines promotion boundaries | Represent real operational targets |
| Approval scope | Controls risk at release points | Apply stronger checks for production than for lower environments |
| Artifact strategy | Improves reproducibility | Deploy versioned CI outputs instead of rebuilding |
| Rollout pattern | Controls blast radius | Use simple stage promotion first, then blue-green or canary where justified |
| Rollback plan | Reduces incident time | Define it before go-live |

## 5. Overview

- Modern Azure DevOps delivery should prefer YAML multi stage pipelines.
- Classic release pipelines remain useful for legacy estates and teams still transitioning.
- Production delivery should always include approvals, observability, and rollback planning.

## 5.1 Deployment strategy overview

```mermaid
flowchart LR
  Package[Package] --> Dev[Deploy Dev]
  Dev --> Validate[Validate]
  Validate --> Approve[Approval]
  Approve --> Prod[Deploy Prod]
  Prod --> Monitor[Monitor]
```

## 5.2 Environment approval flow

```mermaid
flowchart TD
  Deploy[Deployment Job] --> Check[Checks]
  Check --> Manual[Manual Approval]
  Manual --> Gate[Gate Evaluation]
  Gate --> Release[Release]
```

## 5.3 Rollback model

```mermaid
flowchart LR
  Release[Release] --> Health[Health Check]
  Health --> Success[Keep Release]
  Health --> Failure[Rollback]
  Failure --> Previous[Previous Version]
```

## 6. Classic release pipelines vs YAML multi stage

| Model | Best fit | Strengths | Limitations |
|---|---|---|---|
| Classic release pipeline | Legacy environments or existing approvals in UI | Visual editor and familiar release gates | Configuration drift and less version control |
| YAML multi stage | Modern platform engineering | Versioned, reviewable, template friendly | Requires YAML discipline and repo governance |

## 7. Deployment strategies

### 7.1 Rolling deployment

```mermaid
flowchart LR
  BatchOne[Batch One] --> BatchTwo[Batch Two]
  BatchTwo --> BatchThree[Batch Three]
  BatchThree --> Complete[Complete]
```

- Deploys to a subset of targets at a time.
- Best for VM scale sets or cluster nodes.
- Validate each batch before continuing.

### 7.2 Blue green deployment

```mermaid
flowchart LR
  Blue[Blue Environment] --> Switch[Traffic Switch]
  Green[Green Environment] --> Switch
  Switch --> Live[Live Traffic]
```

- Maintain two full environments.
- Cut traffic over only after validation.
- Costs more but rollback is fast.

### 7.3 Canary deployment

```mermaid
flowchart LR
  Small[Small Traffic] --> Medium[Medium Traffic]
  Medium --> Full[Full Traffic]
```

- Sends a small percentage of traffic to the new version.
- Best when strong monitoring and feature metrics exist.
- Roll back quickly if error rates rise.

### 7.4 Feature flags

```mermaid
flowchart TB
  Deploy[Deploy Code] --> Flag[Feature Flag Off]
  Flag --> Test[Test Internally]
  Test --> Enable[Enable Gradually]
```

- Decouple deployment from release.
- Useful for trunk based development and low risk rollback.

## 8. Environments and approvals

### 8.1 Create environments

- Navigation: `dev.azure.com` → project → `Pipelines` → `Environments` → `New environment`.
- Common environments:
  - dev
  - test
  - staging
  - production
- Portal landmarks:
  - the environments list shows each environment name with status indicators and recent deployment history
  - the creation dialog asks for a name first, then optionally lets you associate specific target resources
  - once an environment exists, deployment history becomes the anchor for approvals, checks, and audit review

### 8.2 Manual approvals and checks

- Navigation: `Pipelines` → `Environments` → select environment → `Approvals and checks`.
- Available controls commonly include:
  - manual approval
  - business hours
  - Azure Monitor query or alert checks
  - REST API checks
  - exclusive lock
  - branch control

### 8.3 Pre and post deployment conditions

- Pre deployment:
  - approvals
  - branch control
  - change window checks
- Post deployment:
  - smoke tests
  - monitoring gates
  - ticket updates or notifications

## 9. Deployment targets and YAML task examples

### 9.1 Azure App Service

```yaml
- task: AzureWebApp@1
  inputs:
    azureSubscription: sc-azure-dev
    appType: webAppLinux
    appName: app-web-dev
    package: $(Pipeline.Workspace)/app-drop/*.zip
```

### 9.2 Azure Kubernetes Service

```yaml
- task: KubernetesManifest@1
  inputs:
    action: deploy
    kubernetesServiceConnection: sc-aks-dev
    namespace: app
    manifests: |
      k8s/deployment.yml
      k8s/service.yml
    containers: |
      contoso.azurecr.io/app-api:$(Build.BuildId)
```

### 9.3 Azure Container Instances

```yaml
- task: AzureCLI@2
  inputs:
    azureSubscription: sc-azure-dev
    scriptType: bash
    scriptLocation: inlineScript
    inlineScript: |
      az container create --resource-group rg-demo --name app-api-demo --image contoso.azurecr.io/app-api:$(Build.BuildId) --ip-address Public
```

### 9.4 Azure Functions

```yaml
- task: AzureFunctionApp@2
  inputs:
    azureSubscription: sc-azure-dev
    appType: functionAppLinux
    appName: fn-orders-dev
    package: $(Pipeline.Workspace)/app-drop/*.zip
```

### 9.5 Azure VM Scale Sets

```yaml
- task: AzureCLI@2
  inputs:
    azureSubscription: sc-azure-prod
    scriptType: bash
    scriptLocation: inlineScript
    inlineScript: |
      az vmss extension set --resource-group rg-prod --vmss-name vmss-app-prod --name CustomScript --publisher Microsoft.Azure.Extensions --version 2.1 --settings '{"fileUris":[],"commandToExecute":"/opt/deploy.sh $(Build.BuildId)"}'
```

## 10. Infrastructure as Code in pipelines

### 10.1 Terraform pipeline steps

```yaml
- task: AzureCLI@2
  inputs:
    azureSubscription: sc-azure-platform
    scriptType: bash
    scriptLocation: inlineScript
    inlineScript: |
      terraform init
      terraform plan -out tfplan
      terraform apply -auto-approve tfplan
```

### 10.2 ARM or Bicep deployment

```yaml
- task: AzureResourceManagerTemplateDeployment@3
  inputs:
    deploymentScope: Resource Group
    azureResourceManagerConnection: sc-azure-dev
    subscriptionId: $(subscriptionId)
    action: Create Or Update Resource Group
    resourceGroupName: rg-app-dev
    location: eastus
    templateLocation: Linked artifact
    csmFile: infra/main.bicep
```

### 10.3 Ansible integration

```yaml
- task: Ansible@0
  inputs:
    ansibleInterface: agentMachine
    playbookPathOnAgentMachine: ansible/site.yml
```

## 11. Secrets management

### 11.1 Azure Key Vault integration

- Navigation: `Pipelines` → `Library` → `Variable groups` → `Link secrets from an Azure key vault as variables`.
- Use Key Vault for secret rotation and central management.

```yaml
variables:
  - group: vg-kv-prod
steps:
  - task: AzureKeyVault@2
    inputs:
      azureSubscription: sc-azure-prod
      KeyVaultName: kv-prod-platform
      SecretsFilter: db-password,api-key
      RunAsPreJob: true
```

### 11.2 Secret variable guidance

- Mark secrets as secret variables.
- Avoid command line arguments for highly sensitive values when logs may capture them.
- Use managed identity for agent to Azure auth when feasible.

## 12. Monitoring deployments and rollback

### 12.1 Deployment gates

- Azure Monitor alert based checks.
- REST API validation checks.
- Query work item or CAB system before promotion where required.

### 12.2 Rollback strategies

- Redeploy previous artifact.
- Switch traffic back in blue green pattern.
- Revert flag state for feature flag release.
- Run infrastructure rollback only when state model supports it safely.

## 13. End to end multi stage pipeline

```yaml
trigger:
  branches:
    include:
      - main
pool:
  vmImage: ubuntu-latest
variables:
  - group: vg-app-common
stages:
  - stage: Build
    jobs:
      - job: BuildAndTest
        steps:
          - script: npm ci
          - script: npm test
          - script: npm run build
          - task: PublishPipelineArtifact@1
            inputs:
              targetPath: dist
              artifact: app-drop
  - stage: DeployDev
    dependsOn: Build
    jobs:
      - deployment: DevDeploy
        environment: dev
        strategy:
          runOnce:
            deploy:
              steps:
                - download: current
                  artifact: app-drop
                - task: AzureWebApp@1
                  inputs:
                    azureSubscription: sc-azure-dev
                    appName: app-web-dev
                    package: $(Pipeline.Workspace)/app-drop/*.zip
  - stage: ProdApproval
    dependsOn: DeployDev
    jobs:
      - job: WaitForApproval
        pool: server
        steps:
          - script: echo Approval handled by environment checks
  - stage: DeployProd
    dependsOn: ProdApproval
    jobs:
      - deployment: ProdDeploy
        environment: production
        strategy:
          runOnce:
            deploy:
              steps:
                - download: current
                  artifact: app-drop
                - task: AzureWebApp@1
                  inputs:
                    azureSubscription: sc-azure-prod
                    appName: app-web-prod
                    package: $(Pipeline.Workspace)/app-drop/*.zip
```

## 14. CLI commands and expected output

```bash
az pipelines release definition list --organization https://dev.azure.com/contoso --project Platform --output table
az pipelines runs show --id <runId> --organization https://dev.azure.com/contoso --project Platform --output table
```

Expected output:
- Release definition list shows classic release definitions if present.
- Run details show stage state, result, and links to logs.

## 15. Best practices checklist

- Use environments for every real deployment target.
- Keep deployment logic versioned in YAML.
- Separate build artifacts from deploy configuration.
- Require approval and monitoring for production.
- Prefer progressive delivery over all at once release.
- Test rollback regularly.


## 16. Classic release pipeline screen guide

- Navigation: `dev.azure.com` → project → `Pipelines` → `Releases`.
- Portal landmarks:
  - classic release definitions present stage boxes from left to right to emphasize promotion order
  - artifact sources remain pinned at the top of the canvas so teams can confirm exactly what build output is being released
  - trigger and condition icons surface predeployment controls, while each stage exposes its own task list and approval settings
- Use classic release only when you must preserve a legacy process that is not yet modeled in YAML.

## 17. Environment checks examples

### 17.1 Branch control

- Permit deployments only from protected branches such as `main` or `release/*`.
- Useful for production environments that should never deploy directly from feature branches.

### 17.2 Exclusive lock

- Prevent concurrent deployments into the same target.
- Important for shared test or production environments.

### 17.3 REST API gate

- Query an approval or CAB system before allowing deployment.
- Fail closed when the downstream system is unavailable unless policy states otherwise.

## 18. Operational best practices

- Keep deployment jobs idempotent.
- Record artifact version, git commit, and environment name in deployment logs.
- Run smoke tests immediately after deployment.
- Notify teams through approved chat or incident systems.
- Restrict production service connections to deployment jobs only.

## 19. Official Microsoft references

- [Deployment jobs](https://learn.microsoft.com/azure/devops/pipelines/process/deployment-jobs)
- [Environments](https://learn.microsoft.com/azure/devops/pipelines/process/environments)
- [Approvals and checks](https://learn.microsoft.com/azure/devops/pipelines/process/approvals)
- [Deploy to App Service](https://learn.microsoft.com/azure/devops/pipelines/apps/cd/deploy-webdeploy-webapps)
- [Deploy to AKS](https://learn.microsoft.com/azure/devops/pipelines/ecosystems/kubernetes/deploy)
- [Azure Key Vault task](https://learn.microsoft.com/azure/devops/pipelines/tasks/reference/azure-key-vault-v2)

## Real-world scenarios and examples

### Scenario 1: Web application promoted from staging to production

A team wants automated staging deployment, visible approval, and controlled production release from the same versioned artifact. Azure Pipelines environments and deployment history fit this model well.



Implementation flow:

1. Deploy to staging automatically.
2. Run smoke tests.
3. Require production approval based on visible evidence.
4. Deploy the same versioned artifact to production.



Success indicators:

- Approvers see meaningful evidence.
- Production history is traceable.
- Rollback points are easier to identify.

### Scenario 2: Infrastructure deployment with production change windows

A platform team needs to deliver landing zone changes only during approved windows, with strict Azure access and visible deployment evidence. Azure Pipelines can support that without reverting to manual deployment scripts.



Implementation flow:

1. Create a production environment with checks.
2. Scope the Azure service connection tightly.
3. Require platform approval.
4. Capture deployment history and validation output.



Success indicators:

- Change-window compliance improves.
- Manual release steps are reduced.
- Audit evidence is easier to retrieve.

### Scenario 3: High-availability service using progressive rollout

A high-availability workload may need blue-green or canary promotion instead of all-at-once deployment. Azure Pipelines can orchestrate the stages while monitoring and traffic control determine whether rollout continues.



Implementation flow:

1. Deploy to a small slice or inactive target.
2. Validate telemetry and smoke tests.
3. Promote traffic gradually or switch fully.
4. Rollback quickly if health degrades.



Success indicators:

- Blast radius is reduced.
- Rollback becomes faster.
- Operational confidence improves.

## Operating model checklist

- Review approvals, failed releases, and rollback events as part of platform operations.
- Keep environment ownership and support contacts current.
- Audit which pipelines are authorized to use production service connections.
- Retain enough deployment history to support incident review and compliance.

## Official Microsoft References

- [What is Azure Pipelines?](https://learn.microsoft.com/en-us/azure/devops/pipelines/get-started/what-is-azure-pipelines?view=azure-devops)
- [Create and target Azure DevOps environments for pipelines](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/environments?view=azure-devops)
- [Use an Azure Resource Manager service connection](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/connect-to-azure?view=azure-devops)
- [Deployment jobs](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/deployment-jobs?view=azure-devops)
- [Approvals and checks](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/approvals?view=azure-devops)
- [Azure DevOps CLI reference](https://learn.microsoft.com/en-us/azure/devops/cli/?view=azure-devops)
