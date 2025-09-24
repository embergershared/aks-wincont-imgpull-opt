az login
az account set -s "b8e2cc57-9620-431e-9293-4318e720ba07"

# use azure cli to create a base AKS cluster
# param (
$resourceGroupName = "rg-ussc-391575-s4-aks-wincont-optim-01"
$location = "southcentralus"
$aksClusterName = "aks-use2-391575-s4-hal-wincont"
$nodeCount = 3
$nodeVmSize = "Standard_D8ds_v6"
$kubernetesVersion = "1.32.6"
# )

# Create the resource group
# az group create --name $resourceGroupName --location $location

# Create the AKS cluster
az aks create -g $resourceGroupName `
  -n $aksClusterName `
  --node-resource-group "$resourceGroupName-managed" `
  --node-count $nodeCount `
  --node-vm-size $nodeVmSize `
  --kubernetes-version $kubernetesVersion `
  --generate-ssh-keys `
  --enable-aad `
  --enable-azure-rbac

# Options to test/consider:
#=> option to test: --enable-ultra-ssd
#--enable-ahub?
#--enable-keda


# Note: Adjust the kubernetesVersion parameter as needed based on available versions in your region

# Add a windows node pool
az aks nodepool add -g $resourceGroupName -n "winpool" --os-type Windows --node-count 2 --node-vm-size $nodeVmSize --kubernetes-version $kubernetesVersion --cluster-name $aksClusterName