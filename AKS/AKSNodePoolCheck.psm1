using module ../ResourceCheck.psm1
using module ../CheckResults.psm1


class AKSNodePoolCheck: ResourceCheck {
    
    [object]$NodePoolObject
    [string]$ClusterName


    AKSNodePoolCheck([string] $subscriptionId, [string] $subscriptionName, [string] $clusterName, [object] $nodePool): base($subscriptionId, $subscriptionName) {
        $this.NodePoolObject = $nodePool
        $this.ClusterName = $clusterName
    }

    [string] getClusterName() {
        return $this.ClusterName
    }

    [string] getNodePoolName() {
        return $this.NodePoolObject.name
    }

    [string] getNodeCount() {
        return $this.NodePoolObject.count
    }

    [bool] hasAutoscalingEnabled() {
        return $this.NodePoolObject.enableAutoScaling
    }

    [bool] hasAvailabilityZonesEnabled() {
        if ([string]::IsNullOrEmpty($this.NodePoolObject.availabilityZones)) {
            return $false
        }
        return $this.NodePoolObject.availabilityZones.Length -gt 1    
    }

    [bool] hasMin3Nodes() {
        return $this.NodePoolObject.minCount -ge 3
    }


    [CheckResults] assess() {
        $rules = Get-Content AKS/aksNodePoolRules.json | ConvertFrom-Json

        $this.Results.Add("Cluster Name", $this.getClusterName())
        $this.Results.Add("Node Pool Name", $this.getNodePoolName())
        $this.Results.Add("Node Count", $this.getNodeCount())

        foreach ($ruleTuple in $rules.PSObject.Properties) {
            $this.Results.Add($ruleTuple.Name, $this.checkRule($ruleTuple.Name, $ruleTuple.Value))
        }

        return $this.Results
    }

}
