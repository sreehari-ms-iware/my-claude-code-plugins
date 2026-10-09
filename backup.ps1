# Writes plugins.json: the marketplaces and plugins set up in Claude Code on this machine.
# Only public identifiers are recorded (marketplace repositories and plugin names).
# Run it again after adding, removing, enabling or disabling a plugin, then commit and push.
$ErrorActionPreference = "Stop"
$claude = Join-Path $env:USERPROFILE ".claude"

function Read-Json($path) {
  if (-not (Test-Path $path)) { return $null }
  return Get-Content $path -Raw | ConvertFrom-Json
}

$settings = Read-Json (Join-Path $claude "settings.json")
$known = Read-Json (Join-Path $claude "plugins\known_marketplaces.json")
$installed = Read-Json (Join-Path $claude "plugins\installed_plugins.json")

# Marketplaces with a remote source. Local-path marketplaces are skipped: the path is machine-specific.
$marketplaces = @()
if ($known) {
  foreach ($entry in $known.PSObject.Properties) {
    $source = $entry.Value.source
    $location = $null
    if ($source.source -eq "github") { $location = $source.repo }
    elseif ($source.source -eq "git" -or $source.source -eq "url") { $location = $source.url }
    if ($location) { $marketplaces += [ordered]@{ name = $entry.Name; source = $location } }
  }
}

# Every plugin that is installed or has an enabled/disabled flag.
# "@builtin" plugins ship with Claude Code and "@synced" ones come from the claude.ai account.
$ids = @()
if ($installed -and $installed.plugins) { $ids += $installed.plugins.PSObject.Properties.Name }
$enabledFlags = @{}
if ($settings -and $settings.enabledPlugins) {
  foreach ($flag in $settings.enabledPlugins.PSObject.Properties) {
    $ids += $flag.Name
    $enabledFlags[$flag.Name] = ($flag.Value -eq $true)
  }
}
$plugins = @()
foreach ($id in ($ids | Sort-Object -Unique)) {
  if ($id -like "*@builtin" -or $id -like "*@synced") { continue }
  $plugins += [ordered]@{ id = $id; enabled = [bool]$enabledFlags[$id] }
}

$result = [ordered]@{
  marketplaces = @($marketplaces | Sort-Object { $_.name })
  plugins      = $plugins
}
$target = Join-Path $PSScriptRoot "plugins.json"
[IO.File]::WriteAllText($target, ($result | ConvertTo-Json -Depth 5) + "`n")
Write-Host "Wrote $($marketplaces.Count) marketplaces and $($plugins.Count) plugins to $target"
