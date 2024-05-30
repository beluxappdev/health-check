using module ./AKS/AKSClusterCheck.psm1

param (
    [Parameter(Mandatory = $false)][string]$OutPath = "",
    [Parameter(Mandatory = $false)][string]$csvDelimiter = ",",
    [Parameter(Mandatory = $false)][ValidateSet("user", "sp", "none")][string]$AuthType = "none",
    [Parameter(Mandatory = $false)][string]$ClientId = "",
    [Parameter(Mandatory = $false)][string]$ClientSecret = "",
    [Parameter(Mandatory = $false)][string]$TenantId = ""
)

# Check if the Azure CLI is installed
if (-not(Get-Command az)) {
    Write-Host "Azure CLI is not installed. Please install it from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Red
    exit
}

# Check if parameters are provided
if ($AuthType -eq "sp" -and ($ClientId.Trim() -eq '' -or $ClientSecret.Trim() -eq '' -or $TenantId.Trim() -eq '')) {
    Write-Host "ClientId, ClientSecret and TenantId are required when using Service Principal authentication" -ForegroundColor Red
    exit
}

# Authenticate using Service Principal
if ($AuthType -eq "sp") {
    az login --service-principal -u $ClientId -p $ClientSecret --tenant $TenantId
}
elseif ($AuthType -eq "user") {
    if ($TenantId.Trim() -ne '') {
        az login --tenant $TenantId
    }
    else {
        az login
    }
}
elseif ($AuthType -eq "none") {
    Write-Host "Re-using existing Azure CLI session" 
}
else {
    Write-Host "Invalid authentication type. Please use 'user', 'sp' or 'none'" -ForegroundColor Red
    exit
}

# Your code goes here
$today = [DateTime]::Now.ToString("yyyy-MM-dd_HH-mm-ss")


if ($OutPath.Trim() -eq '' -or -not(Test-Path -Path $OutPath)) {
    $OutPath = "$PSScriptRoot\out\AKS_Assessment_$today\"
}



Write-Host "Output Path: $OutPath" -ForegroundColor Blue

Start-Transcript -Path "$OutPath\log_$today.txt"

Write-Host "******** Welcome to the Microsoft Azure Kubernetes Cluster assessment" -ForegroundColor Cyan


$subscriptions = az account subscription list -o json --only-show-errors  | ConvertFrom-Json

foreach ($currentSubscription in $subscriptions) {
      
    Write-Host "***** Assessing the subscription $($currentSubscription.displayName) ($($currentSubscription.id)..." -ForegroundColor Cyan
    az account set -s $currentSubscription.SubscriptionId

    $jsonAksClusters = az aks list -o json 
    $jsonAksClusters | Out-File -FilePath "$OutPath\raw_$today.json" -Append
    $aksClusters = $jsonAksClusters | ConvertFrom-Json -AsHashTable
    
    foreach ($currentAKSCluster in $aksClusters) {
        Write-Host ""
        Write-Host "**** Assessing the AKS Cluster $($currentAKSCluster.name)..." -ForegroundColor Blue
        $aksCluster = [AKSClusterCheck]::new($currentSubscription.id, $currentSubscription.displayName, $currentAKSCluster)

        $aksCluster.assess().GetAllResults() | Export-Csv -Path "$OutPath\assess_$today.csv" -NoTypeInformation -Append -Delimiter $csvDelimiter
        Write-Host ""
    }
}

Stop-Transcript