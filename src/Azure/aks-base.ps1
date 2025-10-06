az login
az account set -s "b8e2cc57-9620-431e-9293-4318e720ba07"

$resourceGroupName = "rg-usw3-391575-s4-aks-wincont-optim-01"
$location = "westus3"
$aksClusterName = "aks-usw3-391575-s4-hal-wincont"
$nodeCount = 2
$sysNodesVmSize = "Standard_D8_v5" # 12,800 MaxIOPS
$kubernetesVersion = "1.32.6"

# Create the resource group
az group create --name $resourceGroupName --location $location

# Get and validate the Windows admin password
do {
  $windowsAdminPassword = Read-Host -Prompt "Enter Windows admin password (min 14 chars): " -AsSecureString | ConvertFrom-SecureString -AsPlainText
  if ($windowsAdminPassword.Length -lt 14) {
    Write-Host "Password must be at least 14 characters long." -ForegroundColor Red
  }
  elseif ($windowsAdminPassword.Length -gt 123) {
    Write-Host "Password must not exceed 123 characters." -ForegroundColor Red
  }
  # Add complexity requirements check
  elseif (-not ($windowsAdminPassword -match '^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{14,123}$')) {
    Write-Host "Password must contain at least: 1 lowercase letter, 1 uppercase letter, 1 number, and 1 special character." -ForegroundColor Red
  }
} while (
  $windowsAdminPassword.Length -lt 14 -or 
  $windowsAdminPassword.Length -gt 123 -or 
  -not ($windowsAdminPassword -match '^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{14,123}$')
)
Write-Host "Password validation successful!" -ForegroundColor Green

$windowsAdminPassword = 'WinC0ntainer!2025'


# Create the AKS cluster
az aks create -g $resourceGroupName `
  -n $aksClusterName `
  --location $location `
  --node-resource-group "$resourceGroupName-managed" `
  --node-count $nodeCount `
  --node-vm-size $sysNodesVmSize `
  --nodepool-name "sys" `
  --kubernetes-version $kubernetesVersion `
  --generate-ssh-keys `
  --zones 2 `
  --enable-ultra-ssd `
  --windows-admin-password $windowsAdminPassword `
  --windows-admin-username "azusr" `
  --generate-ssh-keys `
  --enable-managed-identity `
  --enable-aad `
  --enable-azure-rbac

# Options to test/consider:
#=> option to test: --enable-ultra-ssd
#--enable-ahub?
#--enable-keda


# Windows node pools in AKS currently require Generation 1 VM sizes => Standard_D4ds_v4, Standard_D8ds_v4, Standard_DS2_v2
# Getting Gen 1 VM sizes list from Azure CLI:
# az vm list-skus --location westus3 --output table --query "[?capabilities[?name=='HyperVGenerations' && contains(value, 'V1')] && resourceType=='virtualMachines'].name"


$winNodesVmSize = "Standard_D8_v5"  # Example Gen1 VM size

# Add windows node pools
$windowsVersions = @(
  @{ name = "win22"; sku = "Windows2022" },
  @{ name = "win19"; sku = "Windows2019" }
)

foreach ($winVer in $windowsVersions) {
  az aks nodepool add -g $resourceGroupName `
    -n $winVer.name `
    --os-type Windows `
    --os-sku $winVer.sku `
    --mode User `
    --node-count 1 `
    --zone 3 `
    --node-vm-size $winNodesVmSize `
    --kubernetes-version $kubernetesVersion `
    --cluster-name $aksClusterName
}

foreach ($winVer in $windowsVersions) {
  az aks nodepool add -g $resourceGroupName `
    -n "$($winVer.name)u" `
    --os-type Windows `
    --os-sku $winVer.sku `
    --mode User `
    --node-count 1 `
    --node-vm-size $winNodesVmSize `
    --kubernetes-version $kubernetesVersion `
    --cluster-name $aksClusterName `
    --enable-ultra-ssd
}


# Create the ACR registry
$acrName = "acrusw3391575s4halwincont"
$acrSku = "Standard"  # Options: Basic, Standard, Premium
az acr create -g $resourceGroupName `
  --name $acrName `
  --sku $acrSku `
  --location $location

# Attach the ACR to the AKS cluster
az aks update -g $resourceGroupName `
  -n $aksClusterName `
  --attach-acr $acrName


# Import the tested images in the ACR
$frameworkVersions = @("4.8", "3.5")
$windowsVersions = @("2019", "2022")

# Login to the ACR (Reminder: Docker engine must be running)
az acr login -n $acrName

# Import all images using a matrix import approach
foreach ($version in $frameworkVersions) {
  foreach ($winVer in $windowsVersions) {
    $sourceImage = "mcr.microsoft.com/dotnet/framework/runtime:$version-windowsservercore-ltsc$($winVer)"
    $targetImage = "run$($version.Replace('.',''))-svrcore-ltsc$($winVer)"

    Write-Host "Importing $sourceImage as $acrName/$targetImage..."
    az acr import -n $acrName `
      --source $sourceImage `
      --image $targetImage
  }
}

$windowsVersions = @(
  @{ name = "win22"; sku = "Windows2022" },
  @{ name = "win19"; sku = "Windows2019" }
)
# Scale to 0 Windows node pools
# Scale Windows node pools in parallel
$jobs = foreach ($winVer in $windowsVersions) {
  $nodepoolName = $winVer.name
  Write-Host "Starting scale job for nodepool $nodepoolName to 0 nodes..."
  Start-Job -ScriptBlock {
    param($resourceGroupName, $aksClusterName, $nodepoolName)
    az aks nodepool scale `
      --resource-group $resourceGroupName `
      --cluster-name $aksClusterName `
      --name $nodepoolName `
      --node-count 0
  } -ArgumentList $resourceGroupName, $aksClusterName, $nodepoolName
}
# Wait for all scaling operations to complete
Write-Host "Waiting for all nodepool scaling operations to complete..."
$jobs | Wait-Job | Receive-Job
Remove-Job -Job $jobs


# Scale to 1 Windows node pools in parallel
$jobs = foreach ($winVer in $windowsVersions) {
  $nodepoolName = $winVer.name
  Write-Host "Starting scale job for nodepool $nodepoolName to 1 node..."
  Start-Job -ScriptBlock {
    param($resourceGroupName, $aksClusterName, $nodepoolName)
    az aks nodepool scale `
      --resource-group $resourceGroupName `
      --cluster-name $aksClusterName `
      --name $nodepoolName `
      --node-count 1
  } -ArgumentList $resourceGroupName, $aksClusterName, $nodepoolName
}
# Wait for all scaling operations to complete
Write-Host "Waiting for all nodepool scaling operations to complete..."
$jobs | Wait-Job | Receive-Job
Remove-Job -Job $jobs

