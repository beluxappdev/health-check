param (
    [Parameter(Mandatory = $false)][string]$Path,
    [Parameter(Mandatory = $false)][string]$csvDelimiter = ","
)

# Import AKSCluster.ps1
. ./AKSCluster.ps1

# Your code goes here
$today = [DateTime]::Now.ToString("yyyy-MM-dd_HH-mm-ss")


if ($Path.Trim() -eq '' -or -not(Test-Path -Path $Path)) {
    $Path = "$PSScriptRoot\out\AKS_Assessment_$today\"
}
Write-Host "Output Path: $Path" -ForegroundColor Green

Start-Transcript -Path "$Path\log_$today.txt"

Write-Host "******** Welcome to the Microsoft Azure Kubernetes Cluster assessment" -ForegroundColor Green


$subscriptions = az account subscription list -o json  | ConvertFrom-Json

foreach ($currentSubscription in $subscriptions) {
      
    Write-Host "***** Assessing the subscription $($currentSubscription.displayName) ($($currentSubscription.id)..." -ForegroundColor Green
    az account set -s $currentSubscription.SubscriptionId

    $aksClusters = az aks list -o json | ConvertFrom-Json
    foreach ($currentAKSCluster in $aksClusters) {
        Write-Host ""
        Write-Host "**** Assessing the AKS Cluster $($currentAKSCluster.Name)..." -ForegroundColor Blue
        $aksCluster = [AKSCluster]::new($currentAKSCluster, $currentSubscription.id, $currentSubscription.displayName)

        $aksCluster.assess() | Export-Csv -Path "$Path\assess_$today.csv" -NoTypeInformation -Append -Delimiter $csvDelimiter
    }
}

Stop-Transcript