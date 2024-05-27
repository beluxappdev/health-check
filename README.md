# AKS Well-Architected Assessment

## Project Introduction

Kubernetes and its Azure implementation has become a market standard for
deploying modern cloud-oriented microservice applications. The purpose of the
assessment is to verify that Microsoft good practices are applied to prevent
security or reliability problems from compromising compliance with the service
level agreements guaranteed by the hosted applications in the future.

## Checks implemented

### Resiliency

- Cluster Autoscaling should be enabled
- Availability zones should be used
- User node pools should be used

### Private Cluster

- Cluster should be private
- Cluster should not have public FQDN
- Public IP addresses should not be associated with AKS load balancer

### Network best practices

- Standard SKU of Load Balancer should be used
- Network policies (Azure or Calico) should be enabled
- Azure CNI Overlay network should be used

### Performance

- OS Disk should be ephemeral

### Compliance

- Kubernetes version should be supported
- Auto-upgrade should be enabled
- Uptime SLA should be enabled
- Azure Policies should be enabled

### Add-ons

- Container Insights should be enabled
- Diagnostic Settings should be enabled
- Defender profile should be enabled
- KMS should be enabled
- HTTP Application Routing should not be used in production

### Authentication and Authorization

- RBAC should be enabled
- Microsoft Entra ID authentication should be enabled
- Local accounts should be disabled
- Managed Identity should be used
- Workload Identity should be enabled
- Pod Identity should not be used

## Getting started

### Prerequisites

- PowerShell Core 7+
- Azure CLI
- "account" extension installed on Azure CLI: `az extension add --name account`

### Permissions

In order to complete the assessment, the user must have at least Reader
permission/role over the Azure Kubernetes Service resources

### Execution

Login to the Azure CLI and execute the script

```powershell
az login # -t [tenant id] (optional)

# Optionally specify the output path and the CSV Delimiter as argument
.\StartAKSClusterAssessment.ps1 #-OutPath "C:\MyPath" -csvDelimiter ","

```

### Parameters

| Parameter    | Default Value | Description                                                                  |
| ------------ | ------------- | ---------------------------------------------------------------------------- |
| OutPath      | ""            | The output path where the assessment results will be saved.                  |
| csvDelimiter | ","           | The delimiter to be used in the CSV file generated by the assessment script. |
| AuthType     | "user"        | The authentication type to be used (either "user" or "sp").                  |
| ClientId     | ""            | The client ID for service principal authentication.                          |
| ClientSecret | ""            | The client secret for service principal authentication.                      |
| TenantId     | ""            | The tenant ID for service principal authentication.                          |

### Output

An output folder named `AKS_Assessment_YYYY-MM-DD_HH-mm-ss` will be created for
each assessment execution. The folder will contain the following files:

- `assess_YYYY-MM-DD_HH-mm-ss` - CSV Results of the assessment
- `log_YYYY-MM-DD_HH-mm-ss` - Transcript of the PowerShell execution
