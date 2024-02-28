class AKSClusterResult {
    [string]$Compliant
    [string]$SubscriptionId
    [string]$SubscriptionName
    [string]$ResourceGroup
    [string]$ClusterName
    [string]$ProvisioningState
    [string]$Region
    [string]$Version
    [string]$ManagedResourceGroup
    [string]$PrivateCluster
    [string]$HasPrivateFQDN
    [string]$LoadBalancerHasPublicIP
    [string]$NodePoolSubnetWithNSG
    [string]$NetworkPolicies
    [string]$CNIOverlay
    [string]$IsKubernetesVersionSupported
    [string]$ContainerInsights
    [string]$DiagnosticSettings
    [string]$UserAssignedIdentity
    [string]$PodIdentityDeprecated
    [string]$MicrosoftDefender
    [string]$RBAC
    [string]$AzureADIntegration
    [string]$DisableLocalAccounts
    [string]$KMSConfigured
    [string]$AzurePolicy
    [string]$WorkloadIdentity
    [string]$SystemAndUserNodePool
    [string]$AvailabilityZones
    [string]$UptimeSlaConfiguration
    [string]$CurrentNodepoolCount
    [string]$CurrentTotalNodeCount
    [string]$OsDiskType
    [string]$ErrorMessage
    [string]$NodePoolsWithoutAutoscaling
    [string]$AutoUpgradeProfile	
    [string]$HttpApplicationRouting
    [string]$StandardLoadBalancer
}

class AKSCluster {
    [string]$SubscriptionId
    [string]$SubscriptionName
    [object]$ClusterObject
    [AKSClusterResult]$Result


    AKSCluster([object] $cluster, [string] $subscriptionId, [string] $subscriptionName) {
        $this.SubscriptionId = $subscriptionId
        $this.SubscriptionName = $subscriptionName
        $this.ClusterObject = $cluster
        $this.Result = [AKSClusterResult]::new()
    }

    [string] getNodeResourceGroup() {
        return $this.ClusterObject.nodeResourceGroup
    }

    [int] getNodepoolCount() {
        return $this.ClusterObject.agentPoolProfiles.Length
    }

    [int] getTotalNodeCount() {
        $totalNodeCount = 0
         
        foreach ($nodePool in $this.ClusterObject.agentPoolProfiles) {
            $totalNodeCount += $nodePool.count
        }

        return $totalNodeCount
    }

    # Checks if the cluster is private
    [bool] isClusterPrivate() {
        return ![string]::IsNullOrEmpty($this.ClusterObject.apiServerAccessProfile.enablePrivateCluster)
    }

    # Checks if the cluster has a private FQDN
    [bool] hasPrivateFQDN() {
        return ![string]::IsNullOrEmpty($this.ClusterObject.privateFqdn)
    }

    # Checks if the cluster has a public outbound IP
    [bool] hasLoadBalancerWithPublicOutboundIp() {
        $outboundIps = $this.ClusterObject.networkProfile.loadBalancerProfile.effectiveOutboundIPs
        foreach ($ip in $outboundIps) {
            try {
                # Making sure it is a public ip
                $publicIp = az network public-ip show --ids $ip.id -o json | ConvertFrom-Json
                if ($publicIp.type -eq "Microsoft.Network/publicIPAddresses") {
                    return $true
                }
            }
            catch {
                # If the public IP is not found, it means it's private
            }
        }
        return $false
    }

    # Checks if the nodepools have autoscaler enabled
    [int] countNodepoolsWithoutAutoscaling() {
        $count = 0
        foreach ($nodePool in $this.ClusterObject.agentPoolProfiles) {
            if ($nodePool.enableAutoScaling -eq $null) {
                $count++
            }
        }
        return $count
    }
    

    # Checks if the cluster has network policies enabled
    [bool] hasNetworkPoliciesEnabled() {
        return $this.ClusterObject.networkProfile.networkPolicy -eq "azure" -or $this.ClusterObject.networkProfile.networkPolicy -eq "calico"
    }

    # Checks if the cluster has network plugin mode set cni overlay
    [bool] isCNIOverlay() {
        return $this.ClusterObject.networkProfile.networkPlugin -eq "azure" -and $this.ClusterObject.networkProfile.networkPluginMode -eq "overlay"
    }

    # Checks if RBAC is enabled
    [bool] hasRBACEnabled() {
        return $this.ClusterObject.enableRbac
    }

    # Checks if Azure AD integration is enabled
    [bool] hasAzureADIntegrationEnabled() {
        return [string]::IsNullOrEmpty($this.ClusterObject.aadProfile) -eq $false
    }

    # Checks if local accounts are disabled
    [bool] hasLocalAccountsDisabled() {
        return $this.ClusterObject.disableLocalAccounts
    }

    # Checks if uses Managed Identity
    [bool] hasManagedIdentity() {
        return $this.ClusterObject.identity.type -eq "UserAssigned" -or $this.ClusterObject.identity.type -eq "SystemAssigned"
    }

    # Checks if Pod Identities are used (should not)
    [bool] hasPodIdentities() {
        return [string]::IsNullOrEmpty($this.ClusterObject.podIdentityProfile) -eq $false
    }

    # Checks if Container Insights is enabled
    [bool] isContainerInsightsEnabled() {
        return  $this.ClusterObject.addonProfiles.omsAgent.enabled
    }

    # Checks if Azure Policies are enabled
    [bool] hasAzurePoliciesEnabled() {
        return $this.ClusterObject.addonProfiles.azurepolicy.enabled
    }

    # Checks if keyvault secret provider is enabled
    [bool] hasKeyVaultSecretProviderEnabled() {
        return $this.ClusterObject.addonProfiles.azureKeyvaultSecretsProvider.enabled
    }

    # Checks if diagnostic settings are enabled
    [bool] hasDiagnosticSettings() {
        $diagnosticSettings = az monitor diagnostic-settings list --resource $this.ClusterObject.id -o json | ConvertFrom-Json
        return $diagnosticSettings.Length -gt 0
    }

    # Checks if workload identity is enabled
    [bool] hasWorkloadIdentityEnabled() {
        return [string]::IsNullOrEmpty($this.ClusterObject.securityProfile.workloadIdentity) -eq $false -and $this.ClusterObject.securityProfile.workloadIdentity.enabled
    }

    # Checks if availability zones are enabled
    [bool] hasAvailabilityZonesEnabled() {
        foreach ($nodePool in $this.ClusterObject.agentPoolProfiles) {
            if ([string]::IsNullOrEmpty($nodePool.availabilityZones) -or $nodePool.availabilityZones.Length -le 1) {
                return $false
            }
        }
        return $true
    }

    # Checks if the cluster uses user nodepools
    [bool] hasUserNodePools() {
        foreach ($nodePool in $this.ClusterObject.agentPoolProfiles) {
            if ($nodePool.mode -eq "User") {
                return $true
            }
        }
        return $false
    }

    # Checks if the cluster has the uptime SLA enabled
    [bool] hasUptimeSLAEnabled() {
        return ![string]::IsNullOrEmpty($this.ClusterObject.sku) -and $this.ClusterObject.sku.tier -ne "Free"
    }

    # Check if the kubernetes version is supported
    [bool] isKubernetesVersionSupported() {
        $clusterVersion = $this.ClusterObject.kubernetesVersion
        $supportedVersionsRaw = az aks get-versions --location $this.ClusterObject.location -o json | ConvertFrom-Json
        foreach ($version in $supportedVersionsRaw.values) {
            if (-not $version.isPreview) {
                if ($version.patchVersions  | Select-Object -Property $clusterVersion) {
                    return $true
                }
            }
        }

        return $false
    }

    # Check if an autoupgrade profile has been set
    [string] hasAutoUpgradeProfile() {
        return $this.ClusterObject.autoUpgradeProfile -ne $null -and $this.ClusterObject.autoUpgradeProfile.upgradeChannel -ne $null
    }

    # Checks if defender is enabled
    [bool] hasMicrosoftDefender() {
        return $this.ClusterObject.securityProfile.defender -ne $null -and $this.ClusterObject.securityProfile.defender.securityMonitoring.enabled
    }

    # Checks if the nodepools OS disk types are ephemeral
    [string] isOSDiskTypeEphemeral() {
        foreach ($nodePool in $this.ClusterObject.agentPoolProfiles) {
            if ($nodePool.osDiskType -ne "Ephemeral") {
                return $false
            }
        }
        return $true
    }

    # Checks if http application routing add-on is enabled (should be disabled)
    [bool] hasHttpApplicationRoutingEnabled() {
        return $this.ClusterObject.addonProfiles.httpApplicationRouting.enabled
    } 

    # Checks if the cluster uses a standard load balancer
    [bool] hasStandardLoadBalancer() {
        return $this.ClusterObject.networkProfile.loadBalancerSku -eq "Standard"
    }


    [string] toString() {
        return ""
        # return "AKSCluster: $($this.ClusterName) in Resource Group: $($this.ResourceGroup) in Subscription: $($this.SubscriptionName) with $($this.CurrentNodepoolCount) node pools and $($this.CurrentTotalNodeCount) nodes. Is private: $($this.IsClusterPrivate())"
    }

    # Assess the cluster
    [AKSClusterResult] assess() {
        Write-Host "** General informaton" -ForegroundColor Cyan
        $this.Result.SubscriptionId = PrintAndReturn $this.SubscriptionId "Subscription ID"
        $this.Result.SubscriptionName = PrintAndReturn $this.SubscriptionName "Subscription Name"
        $this.Result.ResourceGroup = PrintAndReturn $this.ClusterObject.resourceGroup "Resource Group"
        $this.Result.Region = PrintAndReturn $this.ClusterObject.location "Region"
        $this.Result.ClusterName = PrintAndReturn $this.ClusterObject.name "Cluster Name"
        $this.Result.ProvisioningState = PrintAndReturn $this.ClusterObject.provisioningState "Provisioning State"
        $this.Result.ManagedResourceGroup = PrintAndReturn $this.ClusterObject.nodeResourceGroup "Node Resource Group"
        
        # Resiliency
        $this.Result.CurrentTotalNodeCount = PrintAndReturn $this.getTotalNodeCount() "Total Node Count"
        $this.Result.CurrentNodepoolCount = PrintAndReturn $this.getNodepoolCount() "Nodepool Count"
        $this.Result.NodePoolsWithoutAutoscaling = Wrap {$this.countNodepoolsWithoutAutoscaling()} "Nodepools without autoscaling" 0
        $this.Result.AvailabilityZones = Wrap {$this.hasAvailabilityZonesEnabled()} "Availability Zones enabled"
        $this.Result.SystemAndUserNodePool = Wrap {$this.hasUserNodePools()} "User Nodepools enabled"
        
        # Private Cluster
        Write-Host "** Private cluster" -ForegroundColor Cyan
        $this.Result.PrivateCluster = Wrap {$this.isClusterPrivate()} "Is Cluster Private"
        $this.Result.HasPrivateFQDN = Wrap {$this.hasPrivateFQDN()} "Has Private FQDN"
        $this.Result.LoadBalancerHasPublicIP = Wrap {$this.hasLoadBalancerWithPublicOutboundIp()} "Load balancer uses public IP" $false
        
        # Network best practices
        Write-Host "** Networking best practices" -ForegroundColor Cyan
        $this.Result.StandardLoadBalancer = Wrap {$this.hasStandardLoadBalancer()} "Standard Load Balancer"
        $this.Result.NetworkPolicies = Wrap {$this.hasNetworkPoliciesEnabled()} "Network Policies enabled" 
        $this.Result.CNIOverlay = Wrap {$this.isCNIOverlay()} "Azure CNI Overlay"
        
        # Performance
        $this.Result.OsDiskType = Wrap {$this.isOSDiskTypeEphemeral()} "OS Disk type is ephemeral"

        # Compliance
        Write-Host "** Compliance" -ForegroundColor Cyan
        $this.Result.Version = PrintAndReturn $this.ClusterObject.kubernetesVersion "Kubernetes Version"
        $this.Result.IsKubernetesVersionSupported = Wrap {$this.isKubernetesVersionSupported()} "Kubernetes version supported"
        $this.Result.AutoUpgradeProfile = Wrap {$this.hasAutoUpgradeProfile()} "Auto Upgrade Profile"
        $this.Result.UptimeSlaConfiguration = Wrap {$this.hasUptimeSLAEnabled()} "Up-time SLA enabled"
        $this.Result.AzurePolicy = Wrap {$this.hasAzurePoliciesEnabled()} "Azure Policies enabled"


        # Add-ons
        Write-Host "** Add-ons" -ForegroundColor Cyan
        $this.Result.ContainerInsights = Wrap {$this.isContainerInsightsEnabled()} "Container Insights enabled"
        $this.Result.DiagnosticSettings = Wrap {$this.hasDiagnosticSettings()} "Diagnostic Settings enabled"
        $this.Result.MicrosoftDefender = Wrap {$this.hasMicrosoftDefender()} "Defender is enabled"
        $this.Result.KMSConfigured = Wrap {$this.hasKeyVaultSecretProviderEnabled()} "Key Vault Secret Provider enabled"
        $this.Result.HttpApplicationRouting = Wrap {$this.hasHttpApplicationRoutingEnabled()} "HTTP Application Routing enabled" $false
        
        
        # Authentication and Authorization
        Write-Host "** Authentication and Authorization" -ForegroundColor Cyan
        $this.Result.RBAC = Wrap {$this.hasRBACEnabled()} "RBAC enabled"
        $this.Result.AzureADIntegration = Wrap {$this.hasAzureADIntegrationEnabled()} "Azure AD Integration enabled"
        $this.Result.DisableLocalAccounts = Wrap {$this.hasLocalAccountsDisabled()} "Local accounts disabled" 
        $this.Result.UserAssignedIdentity = Wrap {$this.hasManagedIdentity()} "Managed Identity"
        $this.Result.WorkloadIdentity = Wrap {$this.hasWorkloadIdentityEnabled()} "Workload Identity enabled"
        $this.Result.PodIdentityDeprecated = Wrap {$this.hasPodIdentities()} "Pod Identities enabled (switch to workload identities)" $false
        
        return $this.Result
    }

}

function Out($message) {
    Write-Host $message -NoNewline
}

# Function to wrap the execution of a function, print the result in sdtout and return the same result. Also performs a comparison with the expected value (true by default)
function Wrap($fn, $name, $expected = $true) {
    Out "$($name): "
    $result
    try {
        $result = & $fn
        Out "$($result)"
        if ($result -ne $expected) {
            Write-Host "☑️   Expected $($expected) but got $($result)"
        } else {
            Write-Host "✅"
        }
    } catch {
        $result = "Error"
        Write-Host "⛔ $($_.Exception.Message)"
    }
    return $result
}

function PrintAndReturn($result, $message) {
    Write-Host "$($message): $($result)"
    return $result
}
