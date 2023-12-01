# AKS Well-Architected Assessment

## Project Introduction
Kubernetes and its Azure implementation has become a market standard for deploying modern cloud-oriented microservice applications. 
The purpose of the assessment is to verify that Microsoft good practices are applied to prevent security or reliability problems from compromising compliance with the service level agreements guaranteed by the hosted applications in the future.


## Checks implemented

### Security
- Cluster must be private
- NSG should be linked to node pools subnets
- External IP addresses should not be associated with AKS load balancer 
- Network policies (Azure or Calico) should be enabled
- Public FQDN should be disabled
- Defender profile should be enabled
- Policy add-on should be enabled
- KMS should be enabled
- RBAC should be enabled
- Microsoft Entra ID authentication should be enabled
- Workload Identity should be enabled
- AAD PodIdentity should not be used
- Leverage Cluster Managed Identity
- Disable local accounts

### Observability
- Container Insights should be enabled
- Diagnostic Settings should be enabled
  
### Resiliency
- Availability zones should be used
- Uptime SLA should be enabled
- Control plane and node pools version should not be outdated
- Cluster should have at least one system and one user node pool

### Networking
- Azure Overlay network should be used

### Performance
- Leverage Ephemeral OS Disk

## Getting started

### Prerequisites
- Windows PowerShell 5+ / PowerShell Core 7+
- Azure CLI 
- "account" extension installed on Azure CLI: `az extension add --name account`

### Permissions
In order to complete the assessment, the user must have at least Reader permission/role over the Azure Kubernetes Service resources

### Execution
Login to the Azure CLI and execute the script

```powershell
az login # -t [tenant id] (optional)

# Optionally specify the output path and the CSV Delimiter as argument
.\StartAKSClusterAssessment.ps1 #-Path "C:\MyPath" -csvDelimiter ","

```

### Output 
An output folder named "AKSClusterAssessment_YYYY-MM-DD_hh-mm-ss" will be created for each assessment execution. The folder will contain the following files:

- Assessment_Result_YYYY-MM-DD_hh-mm-ss - CSV Results of the assessment
- Assessment_Log_YYYY-MM-DD_hh-mm-ss - Transcript of the PowerShell execution
