<#
.SYNOPSIS
Lists all images in an Azure Container Registry with their sizes.

.PARAMETER RegistryName
The name of the Azure Container Registry (without .azurecr.io suffix).

.PARAMETER Repository
Optional: filter to a specific repository. If omitted, lists all repositories.

.PARAMETER ShowLayers
Optional: include detailed layer information for each manifest.

.EXAMPLE
pwsh .\scripts\get-acr-image-sizes.ps1 -RegistryName acrusw3391575s4halwincont

.EXAMPLE
pwsh .\scripts\get-acr-image-sizes.ps1 -RegistryName acrusw3391575s4halwincont -Repository hal-dwp/run48-winiso-ltsc2019

.EXAMPLE
pwsh .\scripts\get-acr-image-sizes.ps1 -RegistryName myacr -ShowLayers
#>

param(
  [Parameter(Mandatory = $true)]
  [string]$RegistryName,
  
  [string]$Repository,
  
  [switch]$ShowLayers
)

$ErrorActionPreference = "Stop"

function Format-Bytes($bytes) {
  if ($bytes -ge 1GB) { "{0:N2} GiB" -f ($bytes / 1GB) }
  elseif ($bytes -ge 1MB) { "{0:N2} MiB" -f ($bytes / 1MB) }
  elseif ($bytes -ge 1KB) { "{0:N2} KiB" -f ($bytes / 1KB) }
  else { "$bytes B" }
}

# Verify az cli is available
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
  Write-Error "Azure CLI (az) not found. Please install from https://aka.ms/azure-cli"
  exit 1
}

# Verify logged in
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
  Write-Error "Not logged in to Azure. Run 'az login' first."
  exit 1
}

Write-Host "Connected to Azure subscription: $($account.name)" -ForegroundColor Green
Write-Host "Querying ACR: $RegistryName.azurecr.io`n" -ForegroundColor Cyan

# Get repositories
$repositories = @()
if ($Repository) {
  $repositories = @($Repository)
  Write-Host "Filtering to repository: $Repository`n"
}
else {
  Write-Host "Fetching repository list..."
  $repoList = az acr repository list --name $RegistryName --output json | ConvertFrom-Json
  $repositories = $repoList
  Write-Host "Found $($repositories.Count) repositories`n"
}

$allImages = @()

foreach ($repo in $repositories) {
  Write-Host "Processing repository: $repo" -ForegroundColor Yellow
  
  # Get all tags/manifests for this repository using the new command
  $manifests = az acr manifest list-metadata --registry $RegistryName --name $repo --output json | ConvertFrom-Json
  
  foreach ($manifest in $manifests) {
    $digest = $manifest.digest
    $tags = if ($manifest.tags) { $manifest.tags -join ", " } else { "<untagged>" }
    $timestamp = $manifest.timestamp
    
    # Get manifest details to calculate size
    $manifestDetail = az acr manifest show --registry $RegistryName --name "${repo}@${digest}" --output json 2>$null | ConvertFrom-Json
    
    if (-not $manifestDetail) {
      Write-Warning "Could not retrieve manifest details for $repo@$digest"
      continue
    }
    
    # Calculate total size from layers
    $totalSize = 0
    $layerCount = 0
    
    if ($manifestDetail.config) {
      $totalSize += [long]$manifestDetail.config.size
    }
    
    if ($manifestDetail.layers) {
      foreach ($layer in $manifestDetail.layers) {
        $totalSize += [long]$layer.size
        $layerCount++
      }
    }
    
    $imageInfo = [pscustomobject]@{
      Repository   = $repo
      Tags         = $tags
      Digest       = $digest.Substring(0, 19)  # sha256:xxxxx... truncated
      SizeBytes    = $totalSize
      SizeHuman    = Format-Bytes $totalSize
      LayerCount   = $layerCount
      LastModified = $timestamp
      Architecture = $manifestDetail.architecture
      OS           = $manifestDetail.os
    }
    
    $allImages += $imageInfo
    
    if ($ShowLayers -and $manifestDetail.layers) {
      Write-Host "  Layers for $($repo):$($tags):" -ForegroundColor DarkGray
      $layerNum = 1
      foreach ($layer in $manifestDetail.layers) {
        Write-Host "    Layer $layerNum : $(Format-Bytes $layer.size) ($($layer.mediaType))" -ForegroundColor DarkGray
        $layerNum++
      }
    }
  }
}

# Summary output
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "SUMMARY: $($allImages.Count) image manifests found" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$allImages | Sort-Object Repository, Tags | Format-Table -AutoSize -Property Repository, Tags, SizeHuman, LayerCount, Architecture, OS, LastModified

# Total storage calculation
$totalStorage = ($allImages | Measure-Object -Property SizeBytes -Sum).Sum
Write-Host "`nTotal compressed size (all manifests): $(Format-Bytes $totalStorage)" -ForegroundColor Green

# Export to CSV option
$csvPath = ".\acr-images-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
$allImages | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
Write-Host "Detailed report exported to: $csvPath" -ForegroundColor Green
