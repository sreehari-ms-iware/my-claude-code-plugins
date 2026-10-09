# Installs the marketplaces and plugins listed in plugins.json on this machine.
# Install Claude Code and log in first. Pass -DryRun to print the commands without running them.
param([switch]$DryRun)

$config = Get-Content (Join-Path $PSScriptRoot "plugins.json") -Raw | ConvertFrom-Json
if (-not $DryRun -and -not (Get-Command claude -ErrorAction SilentlyContinue)) {
  Write-Host "The 'claude' command was not found. Install Claude Code first."
  exit 1
}

$failed = @()
function Invoke-Claude([string[]]$arguments) {
  Write-Host "claude $($arguments -join ' ')"
  if ($DryRun) { return $true }
  & claude @arguments
  return ($LASTEXITCODE -eq 0)
}

# A marketplace that is already registered reports an error here; that is harmless.
foreach ($marketplace in $config.marketplaces) {
  Invoke-Claude @("plugin", "marketplace", "add", $marketplace.source) | Out-Null
}

foreach ($plugin in $config.plugins) {
  if (-not (Invoke-Claude @("plugin", "install", $plugin.id, "--scope", "user"))) {
    $failed += $plugin.id
    continue
  }
  if (-not $plugin.enabled) {
    Invoke-Claude @("plugin", "disable", $plugin.id, "--scope", "user") | Out-Null
  }
}

Write-Host ""
if ($failed.Count -gt 0) {
  Write-Host "Could not install: $($failed -join ', ')"
  Write-Host "Install those from the /plugin menu inside Claude Code."
  exit 1
}
Write-Host "Done. Restart Claude Code or run /reload-plugins."
