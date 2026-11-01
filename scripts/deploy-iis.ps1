param(
  [Parameter(Mandatory)] [string]$Source,
  [Parameter(Mandatory)] [string]$SiteName,
  [Parameter(Mandatory)] [string]$Target
)

$ErrorActionPreference = 'Stop'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = "C:\deployments\backup-$stamp"
New-Item -ItemType Directory -Force -Path $backup | Out-Null

Import-Module WebAdministration
try {
  if (Test-Path $Target) {
    Copy-Item "$Target\*" $backup -Recurse -Force
  }
  New-Item "$Target\app_offline.htm" -ItemType File -Force | Out-Null
  Stop-Website -Name $SiteName
  robocopy $Source $Target /MIR /R:2 /W:2
  if ($LASTEXITCODE -ge 8) { throw "Robocopy failed: $LASTEXITCODE" }
  Remove-Item "$Target\app_offline.htm" -Force -ErrorAction SilentlyContinue
  Start-Website -Name $SiteName
  $response = Invoke-WebRequest "http://localhost/health/ready" -UseBasicParsing -TimeoutSec 15
  if ($response.StatusCode -ne 200) { throw "Healthcheck failed" }
}
catch {
  Stop-Website -Name $SiteName -ErrorAction SilentlyContinue
  robocopy $backup $Target /MIR /R:2 /W:2 | Out-Null
  Remove-Item "$Target\app_offline.htm" -Force -ErrorAction SilentlyContinue
  Start-Website -Name $SiteName
  throw
}
