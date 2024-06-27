Write-Host "******** Azure Kubernetes Cluster assessment" -ForegroundColor Cyan


$subscriptions = az account subscription list -o json --only-show-errors  | ConvertFrom-Json

foreach ($currentSubscription in $subscriptions) {
      
    Write-Host "***** Assessing the subscription $($currentSubscription.displayName) ($($currentSubscription.id)..." -ForegroundColor Cyan
    az account set -s $currentSubscription.SubscriptionId --only-show-errors 

    $jsonAksClusters = az aks list -o json --only-show-errors 
    $jsonAksClusters | Out-File -FilePath "$OutPath\aks_raw_$today.json" -Append
    $aksClusters = $jsonAksClusters | ConvertFrom-Json -AsHashTable
    
    foreach ($currentAKSCluster in $aksClusters) {
        Write-Host ""
        Write-Host "**** Assessing the AKS Cluster $($currentAKSCluster.name)..." -ForegroundColor Blue
        $aksCluster = [AKSClusterCheck]::new($currentSubscription.id, $currentSubscription.displayName, $currentAKSCluster)

        $aksCluster.assess().GetAllResults() | Export-Csv -Path "$OutPath\aks_assess_$today.csv" -NoTypeInformation -Append -Delimiter $csvDelimiter
        Write-Host ""
    }
}