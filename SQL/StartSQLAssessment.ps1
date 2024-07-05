Write-Host "******** Welcome to the Microsoft Azure SQL Assessment ********" -ForegroundColor Cyan


$subscriptions = az account subscription list -o json --only-show-errors  | ConvertFrom-Json

foreach ($currentSubscription in $subscriptions) {
      
    Write-Host "***** Assessing the subscription $($currentSubscription.displayName) ($($currentSubscription.id)..." -ForegroundColor Cyan
    az account set -s $currentSubscription.SubscriptionId --only-show-errors 

    $jsonSQLservers = az sql server list -o json --only-show-errors 
    $jsonSQLservers | Out-File -FilePath "$OutPath\sql_server_raw_$today.json" -Append  
    $fullservers = $jsonSQLservers | ConvertFrom-Json -AsHashTable
    
    foreach ($currentserver in $fullservers) {
        Write-Host ""
        Write-Host "**** Assessing the SQL Server $($currentserver.name)..." -ForegroundColor Blue
        $SQLServer = [SQLServerCheck]::new($currentSubscription.id, $currentSubscription.displayName, $currentserver)

        $SQLServer.assess().GetAllResults() | Export-Csv -Path "$OutPath\sql_server_assess_$today.csv" -NoTypeInformation -Append -Delimiter $csvDelimiter
        # $jsonSQLDBs = az sql db list --server $currentserver.name -o json --only-show-errors
        # $jsonSQLDBs | Out-File -FilePath "$OutPath\raw_$today.json" -Append
        # $dbs = $jsonSQLDBs | ConvertFrom-Json -AsHashTable
        #  foreach ($currentdb in $dbs) {
        #      Write-Host ""
        #      Write-Host "**** Assessing the SQL Database $($currentdb.name) in $($currentserver.name)... " -ForegroundColor Blue
        #      $SQLDB = [SQLDBCheck]::new($currentSubscription.id, $currentSubscription.displayName, $currentdb)
        # $SQLDB.assess().GetALLResults() | Export-Csv - Path "$OutPath\sql_db_assess_$today.csv" -NoTypeInformation -Append -Delimiter $csvDelimiter
        # Write-Host ""
        # }
    }
}