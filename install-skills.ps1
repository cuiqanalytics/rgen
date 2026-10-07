<#
.SYNOPSIS
  Install the rgen Claude Code skill (Windows / PowerShell).

.DESCRIPTION
  Copies skills\rgen into your Claude skills directory
  ($env:CLAUDE_CONFIG_DIR\skills, or %USERPROFILE%\.claude\skills by default).
  Any existing copy is backed up to <name>.bak-<timestamp> before it is replaced.

.EXAMPLE
  .\install-skills.ps1                 # install into the default location
  .\install-skills.ps1 C:\path\skills  # install into a specific directory
  .\install-skills.ps1 -Uninstall      # remove the installed rgen skill
#>
param(
	[string]$Dest,
	[switch]$Uninstall
)
$ErrorActionPreference = 'Stop'

$here   = Split-Path -Parent $MyInvocation.MyCommand.Path
$src    = Join-Path $here 'skills'
$skills = @('rgen')

if (-not $Dest) {
	$config = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $env:USERPROFILE '.claude' }
	$Dest = Join-Path $config 'skills'
}

if ($Uninstall) {
	foreach ($s in $skills) {
		$p = Join-Path $Dest $s
		if (Test-Path $p) { Remove-Item -Recurse -Force $p; "removed $p" }
		else { "not installed: $p" }
	}
	return
}

foreach ($s in $skills) {
	if (-not (Test-Path (Join-Path $src $s))) {
		throw "skills\ not found next to this script ($src)"
	}
}

New-Item -ItemType Directory -Force -Path $Dest | Out-Null
$stamp = Get-Date -Format 'yyyyMMddHHmmss'

foreach ($s in $skills) {
	$target = Join-Path $Dest $s
	if (Test-Path $target) {
		Move-Item $target "$target.bak-$stamp"
		"backed up existing $s -> $s.bak-$stamp"
	}
	Copy-Item -Recurse (Join-Path $src $s) $target
	"installed $s -> $target"
}

""
"Done. Restart Claude Code (or run /doctor) so it picks up the new skills."
