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

    # Checks if Azure AD integration is enabled
    # [bool] hasAADIntegrationEnabled() { return [string]::IsNullOrEmpty($this.ServerObject.azureAdOnlyAuthentication) -eq $false}
    [bool] hasAADIntegrationEnabled() {
        return -not $this.ServerObject.azureAdOnlyAuthentication
    }
    
    #Checks if auditing is enabled
    [bool] hasAuditingEnabled() {
        return [string]::IsNullOrEmpty($this.ServerObject.auditPolicy) -eq $false
    }

    #Checks if Minimum TLS version is set to 1.2
    [bool] hasMinimumTLSVersion12() {
        return $this.ServerObject.minimalTlsVersion -eq "1.2"
    }

    #Checks if public network access is disabled
    [bool] hasPublicNetworkAccessDisabled() {
        return $this.ServerObject.publicNetworkAccess -eq "Disabled"
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

    #Check if Firewall rules are enabled
    [bool] hasFirewallRulesEnabled() {
        return $this.ServerObject.firewallRules.Count -gt 0 -and $this.ServerObject.firewallRules.Count -lt 10
    }

    #Check if Firewall start IP and end IP difference is less than 10
    [bool] hasFirewallIPDifferenceLessThan10() {
        foreach ($rule in $this.ServerObject.firewallRules) {
            $startIP = $rule.startIpAddress.Split(".")[3]
            $endIP = $rule.endIpAddress.Split(".")[3]
            if ([math]::Abs([int]$startIP - [int]$endIP) -gt 10) {
                return $false
            }
        }
        return $true
    }
    # [bool] hasFirewallIPDifferenceLessThan10() {
    #     $this.ServerObject.firewallRules | ForEach-Object {
    #         $startIP = $_.startIpAddress.Split(".")[3]
    #         $endIP = $_.endIpAddress.Split(".")[3]
    #         if ([math]::Abs($startIP - $endIP) -gt 10) {
    #             return $false
    #         }
    #     }
    #     return $true
    # }


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