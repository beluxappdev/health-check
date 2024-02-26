class AKSCluster {
    [object]$ClusterObject
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
    [string]$PrivateClusterPublicFqdn
    [string]$LoadBalancerWithoutPublicIp
    [string]$NodePoolSubnetWithNSG
    [string]$NetworkPolicyAzureCalico
    [string]$NetworkPluginMode
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
    [int]$CurrentTotalNodeCount
    [string]$OsDiskType
    [string]$ErrorMessage

    AKSCluster([object] $cluster, [string] $subscriptionId, [string] $subscriptionName) {
        $this.SubscriptionId = $subscriptionId
        $this.SubscriptionName = $subscriptionName
        $this.ClusterObject = $cluster
        $this.ResourceGroup = $cluster.resourceGroup
        $this.ClusterName = $cluster.Name
        $this.ProvisioningState = $cluster.provisioningState
        $this.Region = $cluster.location
        $this.Version = $cluster.kubernetesVersion
        $this.ManagedResourceGroup = $this.GetNodeResourceGroup()
        $this.CurrentNodepoolCount = $this.GetNodepoolCount()
        $this.CurrentTotalNodeCount = $this.GetTotalNodeCount()
    }

    [string] GetNodeResourceGroup() {
        return $this.ClusterObject.nodeResourceGroup
    }

    [int] GetNodepoolCount() {
        return $this.ClusterObject.agentPoolProfiles.Length
    }

    [int] GetTotalNodeCount() {
        $totalNodeCount = 0
        foreach ($nodePool in $this.ClusterObject.agentPoolProfiles) {
            $totalNodeCount += $nodePool.count
        }
        return $totalNodeCount
    }

    # Checks if the cluster is private
    [bool] IsClusterPrivate() {
        return ![string]::IsNullOrEmpty($this.ClusterObject.apiServerAccessProfile.enablePrivateCluster)
    }

    # Checks if the cluster has a private FQDN
    [bool] HasPrivateFQDN() {
        return ![string]::IsNullOrEmpty($this.ClusterObject.privateFqdn)
    }

    # Checks if the cluster has a public outbound IP
    [bool] LoadBalancerHasPublicOutboundIp() {
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

    # Checks if the cluster has a network security group attached to the node pool subnet
    [bool] NodePoolSubnetHasNSG() {
        $agentPoolProfiles = $this.ClusterObject.agentPoolProfiles
        Write-Host $agentPoolProfiles
        foreach ($nodePool in $agentPoolProfiles) {
            $subnetId = $nodePool.vnetSubnetId
            Write-Host $subnetId
            $subnet = az network vnet subnet show --ids $subnetId -o json | ConvertFrom-Json
            if (!$subnet.networkSecurityGroup) {
                return $false 
            }
        }
        return $true
    }


    [string] toString() {
        return "Has NSG: $($this.NodePoolSubnetHasNSG())"
        # return "AKSCluster: $($this.ClusterName) in Resource Group: $($this.ResourceGroup) in Subscription: $($this.SubscriptionName) with $($this.CurrentNodepoolCount) node pools and $($this.CurrentTotalNodeCount) nodes. Is private: $($this.IsClusterPrivate())"
    }
}

# Example clusterObject:
# {
# "aadProfile": {
#     "adminGroupObjectIDs": null,
#     "adminUsers": null,
#     "clientAppId": null,
#     "enableAzureRbac": true,
#     "managed": true,
#     "serverAppId": null,
#     "serverAppSecret": null,
#     "tenantId": "7395ebec-8fd4-4339-ad23-2ebcadb5397f"
#   },
#   "addonProfiles": null,
#   "agentPoolProfiles": [
#     {
#       "artifactStreamingProfile": null,
#       "availabilityZones": null,
#       "capacityReservationGroupId": null,
#       "count": 2,
#       "creationData": null,
#       "currentOrchestratorVersion": "1.27.7",
#       "enableAutoScaling": null,
#       "enableCustomCaTrust": null,
#       "enableEncryptionAtHost": null,
#       "enableFips": false,
#       "enableNodePublicIp": null,
#       "enableUltraSsd": null,
#       "gpuInstanceProfile": null,
#       "gpuProfile": null,
#       "hostGroupId": null,
#       "kubeletConfig": null,
#       "kubeletDiskType": "OS",
#       "linuxOsConfig": null,
#       "maxCount": null,
#       "maxPods": 110,
#       "messageOfTheDay": null,
#       "minCount": null,
#       "mode": "System",
#       "name": "agentpool",
#       "networkProfile": null,
#       "nodeImageVersion": "AKSUbuntu-2204gen2containerd-202401.17.1",
#       "nodeInitializationTaints": null,
#       "nodeLabels": null,
#       "nodePublicIpPrefixId": null,
#       "nodeTaints": null,
#       "orchestratorVersion": "1.27.7",
#       "osDiskSizeGb": 128,
#       "osDiskType": "Managed",
#       "osSku": "Ubuntu",
#       "osType": "Linux",
#       "podSubnetId": null,
#       "powerState": {
#         "code": "Running"
#       },
#       "provisioningState": "Succeeded",
#       "proximityPlacementGroupId": null,
#       "scaleDownMode": null,
#       "scaleSetEvictionPolicy": null,
#       "scaleSetPriority": null,
#       "securityProfile": {
#         "sshAccess": "LocalUser"
#       },
#       "spotMaxPrice": null,
#       "tags": null,
#       "type": "VirtualMachineScaleSets",
#       "upgradeSettings": null,
#       "virtualMachineNodesStatus": null,
#       "virtualMachinesProfile": null,
#       "vmSize": "Standard_D2s_v3",
#       "windowsProfile": null,
#       "workloadRuntime": null
#     }
#   ],
#   "aiToolchainOperatorProfile": null,
#   "apiServerAccessProfile": null,
#   "autoScalerProfile": null,
#   "autoUpgradeProfile": {
#     "nodeOsUpgradeChannel": "NodeImage",
#     "upgradeChannel": null
#   },
#   "azureMonitorProfile": null,
#   "azurePortalFqdn": "a-test-wf-aks-plzkc320.portal.hcp.westeurope.azmk8s.io",
#   "creationData": null,
#   "currentKubernetesVersion": "1.27.7",
#   "disableLocalAccounts": true,
#   "diskEncryptionSetId": null,
#   "dnsPrefix": "a-test-wf-aks",
#   "enableNamespaceResources": null,
#   "enablePodSecurityPolicy": null,
#   "enableRbac": true,
#   "extendedLocation": null,
#   "fqdn": "a-test-wf-aks-plzkc320.hcp.westeurope.azmk8s.io",
#   "fqdnSubdomain": null,
#   "guardrailsProfile": null,
#   "httpProxyConfig": null,
#   "id": "/subscriptions/08222835-a361-459d-b1de-126ef6755813/resourcegroups/a-test-wf-rg/providers/Microsoft.ContainerService/managedClusters/a-test-wf-aks",
#   "identity": {
#     "delegatedResources": null,
#     "principalId": "f55dfb91-64f8-402a-ac7c-d77f4b5b465a",
#     "tenantId": "7395ebec-8fd4-4339-ad23-2ebcadb5397f",
#     "type": "SystemAssigned",
#     "userAssignedIdentities": null
#   },
#   "identityProfile": {
#     "kubeletidentity": {
#       "clientId": "6816d614-4a97-4a8e-9a90-6df43273b38d",
#       "objectId": "46704b2b-44a4-48d3-9970-45ae22dd4bb4",
#       "resourceId": "/subscriptions/08222835-a361-459d-b1de-126ef6755813/resourcegroups/a-test-wf-aks-node-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/a-test-wf-aks-agentpool"
#     }
#   },
#   "ingressProfile": null,
#   "kubernetesVersion": "1.27.7",
#   "linuxProfile": null,
#   "location": "westeurope",
#   "maxAgentPools": 100,
#   "metricsProfile": {
#     "costAnalysis": {
#       "enabled": false
#     }
#   },
#   "name": "a-test-wf-aks",
#   "networkProfile": {
#     "dnsServiceIp": "10.0.0.10",
#     "ipFamilies": [
#       "IPv4"
#     ],
#     "kubeProxyConfig": null,
#     "loadBalancerProfile": {
#       "allocatedOutboundPorts": null,
#       "backendPoolType": "nodeIPConfiguration",
#       "effectiveOutboundIPs": [
#         {
#           "id": "/subscriptions/08222835-a361-459d-b1de-126ef6755813/resourceGroups/a-test-wf-aks-node-rg/providers/Microsoft.Network/publicIPAddresses/4c744e91-e423-4430-ad84-853bab6e4abf",
#           "resourceGroup": "a-test-wf-aks-node-rg"
#         }
#       ],
#       "enableMultipleStandardLoadBalancers": null,
#       "idleTimeoutInMinutes": null,
#       "managedOutboundIPs": {
#         "count": 1,
#         "countIpv6": null
#       },
#       "outboundIPs": null,
#       "outboundIpPrefixes": null
#     },
#     "loadBalancerSku": "Standard",
#     "monitoring": null,
#     "natGatewayProfile": null,
#     "networkDataplane": null,
#     "networkMode": null,
#     "networkPlugin": "kubenet",
#     "networkPluginMode": null,
#     "networkPolicy": "none",
#     "outboundType": "loadBalancer",
#     "podCidr": "10.244.0.0/16",
#     "podCidrs": [
#       "10.244.0.0/16"
#     ],
#     "serviceCidr": "10.0.0.0/16",
#     "serviceCidrs": [
#       "10.0.0.0/16"
#     ]
#   },
#   "nodeProvisioningProfile": {
#     "mode": "Manual"
#   },
#   "nodeResourceGroup": "a-test-wf-aks-node-rg",
#   "nodeResourceGroupProfile": null,
#   "oidcIssuerProfile": {
#     "enabled": false,
#     "issuerUrl": null
#   },
#   "podIdentityProfile": null,
#   "powerState": {
#     "code": "Running"
#   },
#   "privateFqdn": null,
#   "privateLinkResources": null,
#   "provisioningState": "Succeeded",
#   "publicNetworkAccess": null,
#   "resourceGroup": "a-test-wf-rg",
#   "resourceUid": "65ccb01c3f4cda0001fcbcb2",
#   "securityProfile": {
#     "azureKeyVaultKms": null,
#     "customCaTrustCertificates": null,
#     "defender": null,
#     "imageCleaner": null,
#     "imageIntegrity": null,
#     "nodeRestriction": null,
#     "workloadIdentity": null
#   },
#   "serviceMeshProfile": null,
#   "servicePrincipalProfile": {
#     "clientId": "msi"
#   },
#   "sku": {
#     "name": "Base",
#     "tier": "Free"
#   },
#   "storageProfile": {
#     "blobCsiDriver": null,
#     "diskCsiDriver": {
#       "enabled": true,
#       "version": "v1"
#     },
#     "fileCsiDriver": {
#       "enabled": true
#     },
#     "snapshotController": {
#       "enabled": true
#     }
#   },
#   "supportPlan": "KubernetesOfficial",
#   "systemData": null,
#   "type": "Microsoft.ContainerService/ManagedClusters",
#   "upgradeSettings": null,
#   "windowsProfile": null,
#   "workloadAutoScalerProfile": {
#     "keda": null,
#     "verticalPodAutoscaler": null
#   }
# }
