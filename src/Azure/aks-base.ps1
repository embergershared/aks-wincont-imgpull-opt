az login
az account set -s "b8e2cc57-9620-431e-9293-4318e720ba07"

$resourceGroupName = "rg-usw3-391575-s4-aks-wincont-optim-01"
$location = "westus3"
$aksClusterName = "aks-usw3-391575-s4-hal-wincont"
$nodeCount = 3
$nodeVmSize = "Standard_D8_v5"
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


# Create the AKS cluster
az aks create -g $resourceGroupName `
  -n $aksClusterName `
  --location $location `
  --node-resource-group "$resourceGroupName-managed" `
  --node-count $nodeCount `
  --node-vm-size $nodeVmSize `
  --nodepool-name "sys" `
  --kubernetes-version $kubernetesVersion `
  --generate-ssh-keys `
  --windows-admin-password $windowsAdminPassword `
  --windows-admin-username "azureuser" `
  --enable-managed-identity `
  --enable-aad `
  --enable-azure-rbac

# Options to test/consider:
#=> option to test: --enable-ultra-ssd
#--enable-ahub?
#--enable-keda


# Windows node pools in AKS currently require Generation 1 VM sizes => Standard_D4ds_v4, Standard_D8ds_v4, Standard_DS2_v2
# Getting Gen 1 VM sizes list from Azure CLI:
# az vm list-skus --location eastus3 --output table --query "[?capabilities[?name=='HyperVGenerations' && contains(value, 'V1')] && resourceType=='virtualMachines'].name"

$winNodesVmSize = "Standard_D8_v5"  # Example Gen1 VM size
# Add a windows node pool
az aks nodepool add -g $resourceGroupName `
  -n "win" `
  --os-type Windows `
  --node-count 2 `
  --node-vm-size $winNodesVmSize `
  --kubernetes-version $kubernetesVersion `
  --cluster-name $aksClusterName


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


# pull the public base image from mcr to the ACR
az acr login -n $acrName
az acr import -n $acrName `
  --source mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2019 `
  --image run48-lsc2019
