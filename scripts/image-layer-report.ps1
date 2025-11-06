<#
.SYNOPSIS
Generates layer size report (and optional diff) for one or two Windows container images.

.PARAMETER Image
Primary image reference (e.g. acr.azurecr.io/app:latest)

.PARAMETER Baseline
Optional baseline image reference for diff (e.g. acr.azurecr.io/app:previous)

.PARAMETER OutputDir
Directory to write reports (default: ./reports)

.EXAMPLE
pwsh ./scripts/image-layer-report.ps1 -Image acr.azurecr.io/hal-dwp/run48-winiso-ltsc2019:latest

.EXAMPLE
pwsh ./scripts/image-layer-report.ps1 -Image acr.azurecr.io/app:new -Baseline acr.azurecr.io/app:old -OutputDir artifacts
#>

param(
  [Parameter(Mandatory = $true)]
  [string]$Image,
  [string]$Baseline,
  [string]$OutputDir = "./reports"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $OutputDir)) {
  New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

function Get-ImageHistory($img) {
  Write-Host "Inspecting image history for $img ..."
  # Ensure image present locally
  docker pull $img | Out-Null

  $historyLines = docker history --no-trunc --format "{{.ID}}|{{.Size}}|{{.CreatedBy}}" $img
  $layers = @()
  $order = 0
  foreach ($line in $historyLines) {
    $parts = $line -split '\|', 3
    if ($parts.Count -lt 3) { continue }
    $id = $parts[0]
    $sizeStr = $parts[1]
    $cmd = $parts[2]
    # Convert size (e.g. 1.23GB, 23.4MB, 0B) to bytes
    $sizeBytes = 0
    if ($sizeStr -match '([0-9\.]+)(KB|MB|GB|B)') {
      $val = [double]$matches[1]
      switch ($matches[2]) {
        "B" { $sizeBytes = [math]::Round($val) }
        "KB" { $sizeBytes = [math]::Round($val * 1KB) }
        "MB" { $sizeBytes = [math]::Round($val * 1MB) }
        "GB" { $sizeBytes = [math]::Round($val * 1GB) }
      }
    }
    $layers += [pscustomobject]@{
      Order     = $order
      LayerID   = $id
      SizeBytes = $sizeBytes
      SizeHuman = $sizeStr
      CreatedBy = ($cmd -replace '\s+', ' ').Trim()
    }
    $order++
  }
  return $layers
}

function Format-Bytes($bytes) {
  if ($bytes -ge 1GB) { "{0:N2} GiB" -f ($bytes / 1GB) }
  elseif ($bytes -ge 1MB) { "{0:N2} MiB" -f ($bytes / 1MB) }
  elseif ($bytes -ge 1KB) { "{0:N2} KiB" -f ($bytes / 1KB) }
  else { "$bytes B" }
}

$layersNew = Get-ImageHistory -img $Image
$totalNew = ($layersNew | Measure-Object -Property SizeBytes -Sum).Sum

$reportMd = "# Image Layer Report`n`n"
$reportMd += "Generated: $(Get-Date -Format o)`n`n"
$reportMd += "## Image: ``$Image```n"
$reportMd += "Total (history sum): $(Format-Bytes $totalNew)`n`n"
$reportMd += "| Order | Size | Layer ID | Created By |`n|-------|------|---------|-----------|`n"
foreach ($l in $layersNew) {
  $cmdSnippet = $l.CreatedBy.Substring(0, [Math]::Min(60, $l.CreatedBy.Length))
  $reportMd += "| $($l.Order) | $($l.SizeHuman) | $($l.LayerID.Substring(0,12)) | $cmdSnippet |`n"
}

if ($Baseline) {
  $layersBase = Get-ImageHistory -img $Baseline
  $totalBase = ($layersBase | Measure-Object -Property SizeBytes -Sum).Sum
  $reportMd += "`n## Baseline: ``$Baseline```n"
  $reportMd += "Total (history sum): $(Format-Bytes $totalBase)`n"
  $delta = $totalNew - $totalBase
  $deltaLabel = if ($delta -ge 0) { "+$(Format-Bytes $delta)" } else { "$(Format-Bytes $delta)" }
  $reportMd += "**Delta vs baseline:** $deltaLabel`n`n"

  # Basic diff by CreatedBy signature
  $reportMd += "### Added / Modified Steps (approximation)`n"
  $reportMd += "| Step (CreatedBy snippet) | New Size | Baseline Size | Delta |`n|-------------------------|----------|---------------|-------|`n"

  $allSigs = (@($layersBase.CreatedBy) + @($layersNew.CreatedBy)) | Select-Object -Unique
  foreach ($sig in $allSigs) {
    $b = $layersBase | Where-Object { $_.CreatedBy -eq $sig } | Select-Object -First 1
    $n = $layersNew | Where-Object { $_.CreatedBy -eq $sig } | Select-Object -First 1
    $bSize = if ($b) { $b.SizeBytes } else { 0 }
    $nSize = if ($n) { $n.SizeBytes } else { 0 }
    if ($bSize -eq 0 -and $nSize -eq 0) { continue }
    $deltaBytes = $nSize - $bSize
    $sigSnippet = $sig.Substring(0, [Math]::Min(40, $sig.Length))
    $reportMd += "| $sigSnippet | $(Format-Bytes $nSize) | $(Format-Bytes $bSize) | $(if ($deltaBytes -ge 0) { "+$(Format-Bytes $deltaBytes)" } else { "$(Format-Bytes $deltaBytes)" }) |`n"
  }
}

$outFile = Join-Path $OutputDir "image-layer-report.md"
$reportMd | Set-Content -Path $outFile -Encoding UTF8
Write-Host "Report written to $outFile"
