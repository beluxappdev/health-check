using module ../ResourceCheck.psm1
using module ../CheckResults.psm1

class SQLServerCheck: ResourceCheck {
    
    [object]$ServerObject

    SQLServerCheck([string] $subscriptionId, [string] $subscriptionName, [object] $server): base($subscriptionId, $subscriptionName) {
        $this.ServerObject = $server
    }

    [string] getServerName() {
        return $this.ServerObject.name
    }

    [string] getServerResourceGroup() {
        return $this.ServerObject.resourceGroup
    }

    # Checks if Auditing on server level is enabled
    [bool] hasAuditingEnabled() {
        $ServerAuditing =  az sql server audit-policy show --name $this.ServerObject.name --resource-group $this.ServerObject.resourceGroup -o json | ConvertFrom-Json
        return $ServerAuditing.ServerObject.state -eq "Enabled"
    }

    # Checks if Azure AD integration is enabled
    [bool] hasAADIntegrationEnabled() {
        return -not $this.ServerObject.azureAdOnlyAuthentication
    }

    #Checks if Minimum TLS version is set to 1.2
    [bool] hasMinimumTLSVersion12() {
        return $this.ServerObject.minimalTlsVersion -eq "1.2"
    }

    #Checks if restrictions on Outbound Network Access are disabeled
    [bool] hasrestrictOutboundNetworkAccessDisabled() {
        return $this.ServerObject.restrictOutboundNetworkAccess -eq "Disabled"
    }

     #Check if Azure IP rules are enabled
    [bool] hasAzureIPRulesEnabled() {
        return $this.ServerObject.azureIpRules.Count -gt 0
    }

    #Check if Private Endpoint connections are enabled
    [bool] hasPrivateEndpointConnectionsEnabled() {
        return $this.ServerObject.privateEndpointConnections.Count -gt 0
    }

    #Checks if public network access is disabled
    [bool] hasPublicNetworkAccessDisabled() {
        return $this.ServerObject.publicNetworkAccess -eq "Disabled"
    }

    #Check if Firewall rules are enabled
    [bool] hasMax10FirewallRulesEnabled() {
        $firewallRules = az sql server firewall-rule list -g  $this.ServerObject.resourceGroup -s $this.ServerObject.name -o json | ConvertFrom-Json
        $totalRuleCount = 0
        foreach ($rule in $firewallRules){
            $totalRuleCount = $totalRuleCount + 1
        }
        return $totalRuleCount -lt 10
    }

    #Check if Firewall start IP and end IP difference is less than 10
    [bool] firewallHasMax10AuthorizedIPs() {
        $firewallRules = az sql server firewall-rule list -g  $this.ServerObject.resourceGroup -s $this.ServerObject.name -o json | ConvertFrom-Json  
        $totalIPCount = 0  
        foreach ($rule in $firewallRules) {  
            $startIP = $rule.startIpAddress.Split(".")[3]  
            $endIP = $rule.endIpAddress.Split(".")[3]  
            $totalIPCount = $totalIPCount + [math]::Abs([int]$endIP - [int]$startIP) + 1  
        }  
        return $totalIPCount -le 10  
    }  

    [string] toString() {
        return ""
    }

    [CheckResults] assess() {
        $rules = Get-Content SQL/sqlRules.json | ConvertFrom-Json

        $this.Results.Add("Name", $this.getServerName())
        $this.Results.Add("Resource_Group", $this.getServerResourceGroup())

        foreach ($ruleTuple in $rules.PSObject.Properties) {
            $this.Results.Add($ruleTuple.Name, $this.checkRule($ruleTuple.Name, $ruleTuple.Value))
        }

        return $this.Results
    }

}

# class SQLDBCheck: ResourceCheck {
    
#     [object]$DBObject

#     SQLDBCheck([string] $subscriptionId, [string] $subscriptionName, [object] $db): base($subscriptionId, $subscriptionName) {
#         $this.DBObject = $db
#     }

#     [string] getDBName() {
#         return $this.DBObject.name
#     }

#     [string] getDBResourceGroup() {
#         return $this.DBObject.resourceGroup
#     }

#     [string] toString() {
#         return ""
#     }

#     [CheckResults] assess() {
#         $rules = Get-Content SQL/sqlRules.json | ConvertFrom-Json

#         $this.Results.Add("Name", $this.getDBName())
#         $this.Results.Add("Resource_Group", $this.getDBResourceGroup())

#         foreach ($ruleTuple in $rules.PSObject.Properties) {
#             $this.Results.Add($ruleTuple.Name, $this.checkRule($ruleTuple.Name, $ruleTuple.Value))
#         }

#         return $this.Results
#     }

# }