# Import AKSCluster.ps1
. ./AKSCluster.ps1

# Your code goes here

$subscriptions = az account subscription list -o json | ConvertFrom-Json

foreach ($currentSubscription in $subscriptions) {
      
    Write-Host "***** Assessing the subscription $($currentSubscription.displayName) ($($currentSubscription.id)..." -ForegroundColor Green
    az account set -s $currentSubscription.SubscriptionId

    $aksClusters = az aks list -o json | ConvertFrom-Json
    foreach ($currentAKSCluster in $aksClusters) {
        Write-Host "**** Assessing the AKS Cluster $($currentAKSCluster.Name)..." -ForegroundColor Blue
        $aksCluster = [AKSCluster]::new($currentAKSCluster, $currentSubscription.id, $currentSubscription.displayName)

        Write-Host $aksCluster.toString()
    }
}