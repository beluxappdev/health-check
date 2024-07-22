using module ../ResourceCheck.psm1
using module ../CheckResults.psm1

class SQLDBCheck: ResourceCheck {
    
    [object]$DBObject
    [object]$ServerObject

    SQLDBCheck([string] $subscriptionId, [string] $subscriptionName, [object] $db, [object]$server): base($subscriptionId, $subscriptionName) {
        $this.DBObject = $db
        $this.ServerObject = $server
    }

    [string] getServerName() {
        return $this.ServerObject.name
    }

    [string] getDBName() {
        return $this.DBObject.name
    }

    [string] getDBResourceGroup() {
        return $this.DBObject.resourceGroup
    }

    [string] getDBLocation() {
        return $this.DBObject.location
    }

    [string] getDBServerName() {
        #DBObject needs to access its server's name
        return $this.getServerName()
    }

    # Checks if Auditing on server level is enabled
    [bool] hasAuditingDBEnabled() {
        $DBAuditing =  az sql db audit-policy show --name $this.getDBName --resource-group $this.getDBResourceGroup() --server $this.getServerName() --query 'state' -o json | ConvertFrom-Json 
        return $DBAuditing -eq "Enabled"
    }

    # Checks if autoPauseDelay is enabled
    [bool] hasAutopauseDelayEnabled() {
        $DBSku = az sql db show --name $this.getDBName() --resource-group $this.getDBResourceGroup() --server $this.getDBServerName() --query 'sku' --output json | ConvertFrom-Json
        if ($DBSku.tier -eq 'GeneralPurpose' -and $DBSku.family -eq 'Gen5') {
            $DBProperties = az sql db show --name $this.getDBName() --resource-group $this.getDBResourceGroup() --server $this.getDBServerName() --query 'autoPauseDelay' --output json | ConvertFrom-Json
            return $DBProperties -ne $null
        } else {
            return $false
        }
    }

    # Checks if Back Ups are enabled
    [bool] hasBackUpsEnabled() {
        $DBbackupJson = az sql db ltr-backup list --location $this.getDBLocation() --resource-group $this.getDBResourceGroup() --server $this.getDBServerName() | ConvertFrom-Json
        return $DBbackupJson.count -gt 0
    }

    # Checks if SQL TDE is enabled
    [bool] hasTDEenabled(){
        $DBTDE = az sql db tde show --database $this.getDBName() --server $this.getDBServerName() --resource-group $this.getDBResourceGroup() --query 'state'  -o json | ConvertFrom-Json
        return $DBTDE -eq "Enabled"
    }

    #Checks if there are replica's configured
    [bool] hasReplicasConfigured(){
        $DBReplica = az sql db replica list-links --name $this.getDBName --server $this.getDBServerName --resource-group $this.getDBResourceGroup 
        return $DBReplica -ne $null
    }

    #Checks database size REWORK THIS CHECK 
    [bool] isDatabaseSizeWithinLimit(){
        $databaseSizeInMB = az sql db show --name $this.getDBName --server $this.getDBServerName --resource-group $this.getDBResourceGroup --query maxSizeBytes --output tsv | ForEach-Object { [int]$_ / 1MB }
        $limitInMB = 5000 #check currently set max set limit, more than 90% the check should fail
        return $databaseSizeInMB -le $limitInMB
    }

    [string] toString() {
        return ""
    }

    [CheckResults] assess() {
        $rules = Get-Content SQL/sqlDBRules.json | ConvertFrom-Json

        $this.Results.Add("Name", $this.getDBName())
        $this.Results.Add("Resource_Group", $this.getDBResourceGroup())

        foreach ($ruleTuple in $rules.PSObject.Properties) {
            $this.Results.Add($ruleTuple.Name, $this.checkRule($ruleTuple.Name, $ruleTuple.Value))
        }

        return $this.Results
    }

}