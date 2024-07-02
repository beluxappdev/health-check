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
- KeyVault Secret Provider should be used

### Authentication and Authorization

- RBAC should be enabled
- Microsoft Entra ID authentication should be enabled
- Local accounts should be disabled
- Managed Identity should be used
- Workload Identity should be enabled
- Pod Identity should not be used
