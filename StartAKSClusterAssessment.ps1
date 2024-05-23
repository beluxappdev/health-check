param (
    [Parameter(Mandatory = $false)][string]$OutPath = "",
    [Parameter(Mandatory = $false)][string]$csvDelimiter = ",",
    [Parameter(Mandatory = $false)][ValidateSet("user", "sp")][string]$AuthType = "user",
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
else {
    Write-Host "Invalid authentication type. Please use 'user' or 'sp'" -ForegroundColor Red
    exit
}

# Import AKSCluster.ps1
. ./AKSCluster.ps1

# Your code goes here
$today = [DateTime]::Now.ToString("yyyy-MM-dd_HH-mm-ss")


if ($OutPath.Trim() -eq '' -or -not(Test-Path -Path $OutPath)) {
    $OutPath = "$PSScriptRoot\out\AKS_Assessment_$today\"
}



Write-Host "Output Path: $OutPath" -ForegroundColor Green

Start-Transcript -Path "$OutPath\log_$today.txt"

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

        $aksCluster.assess() | Export-Csv -Path "$OutPath\assess_$today.csv" -NoTypeInformation -Append -Delimiter $csvDelimiter
    }
}

Stop-Transcript