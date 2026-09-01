<#
.SYNOPSIS
  Install (or uninstall) the Harrier Runner tray viewer on Windows.

.DESCRIPTION
  Downloads the signed harrier-runner-tray Windows binary from the public releases repo, verifies its SHA-256
  against the published SHA256SUMS, installs it to a stable per-user location, creates a Start Menu shortcut
  (#540), registers it to launch at login (the exe's own `tray --install-autostart`), and launches it.

  Everything is per-user — no admin rights needed. The tray is a read-only viewer over
  %USERPROFILE%\.harrier\runner\status.json; it does not touch the runner service.

.PARAMETER Version
  Release tag to install (e.g. v0.2.9), or "latest" (default).

.PARAMETER Uninstall
  Remove the tray: stop it, delete the binary, remove the Start Menu shortcut, and unregister autostart.

.PARAMETER NoAutostart
  Install without registering login autostart.

.PARAMETER NoLaunch
  Install without launching the tray immediately.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\install-harrier-tray.ps1

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\install-harrier-tray.ps1 -Uninstall
#>
[CmdletBinding()]
param(
  [string]$Version = "latest",
  [string]$Repo    = "Eramiah/harrier-runner",
  [switch]$Uninstall,
  [switch]$NoAutostart,
  [switch]$NoLaunch
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$Asset      = "harrier-runner-tray-windows-amd64.exe"
$InstallDir = Join-Path $env:LOCALAPPDATA "Programs\harrier-runner"
$ExePath    = Join-Path $InstallDir "harrier-runner-tray.exe"
$Shortcut   = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Harrier Runner Tray.lnk"

function Stop-Tray {
  Get-Process harrier-runner-tray -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

if ($Uninstall) {
  Write-Host "Uninstalling Harrier Runner tray..."
  Stop-Tray
  if (Test-Path $ExePath) {
    # Best-effort: unregister the login item via the exe before deleting it.
    try { & $ExePath tray --uninstall-autostart | Out-Null } catch { }
    Remove-Item -Force $ExePath -ErrorAction SilentlyContinue
  }
  if (Test-Path $Shortcut) { Remove-Item -Force $Shortcut }
  Write-Host "Done. (Your runner service and settings are untouched.)"
  return
}

# --- resolve the download base URL ---
$Base = if ($Version -eq "latest") {
  "https://github.com/$Repo/releases/latest/download"
} else {
  "https://github.com/$Repo/releases/download/$Version"
}

# --- download the binary + checksums to a temp dir ---
$Tmp = Join-Path $env:TEMP ("harrier-tray-" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $Tmp | Out-Null
$ExeTmp  = Join-Path $Tmp $Asset
$SumsTmp = Join-Path $Tmp "SHA256SUMS"
Write-Host "Downloading $Asset ($Version)..."
& curl.exe -fsSL -o $ExeTmp  "$Base/$Asset"
if ($LASTEXITCODE -ne 0) { throw "download failed: $Base/$Asset" }
& curl.exe -fsSL -o $SumsTmp "$Base/SHA256SUMS"
if ($LASTEXITCODE -ne 0) { throw "download failed: $Base/SHA256SUMS" }

# --- verify SHA-256 against the published SHA256SUMS ---
$line = Select-String -Path $SumsTmp -Pattern ([regex]::Escape($Asset)) | Select-Object -First 1
if (-not $line) { throw "no SHA256SUMS entry for $Asset" }
$want = ($line.Line.Trim() -split '\s+')[0].ToLower()
if ([string]::IsNullOrWhiteSpace($want)) { throw "could not parse checksum from SHA256SUMS line: $($line.Line)" }
$got  = (Get-FileHash $ExeTmp -Algorithm SHA256).Hash.ToLower()
if ($want -ne $got) { throw "checksum mismatch for ${Asset}: expected $want, got $got" }
Write-Host "Checksum OK: $got"

# --- stop any running tray, then install to the stable location ---
Stop-Tray
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Move-Item -Force $ExeTmp $ExePath
Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue
Write-Host "Installed: $ExePath"

# --- Start Menu shortcut (#540) so it can be relaunched on demand ---
$ws  = New-Object -ComObject WScript.Shell
$lnk = $ws.CreateShortcut($Shortcut)
$lnk.TargetPath       = $ExePath
$lnk.Arguments        = "tray"
$lnk.Description       = "Harrier Runner tray viewer"
$lnk.WorkingDirectory = $InstallDir
$lnk.Save()
Write-Host "Start Menu shortcut: $Shortcut"

# --- register login autostart (reuses the exe's own installer) ---
if (-not $NoAutostart) {
  & $ExePath tray --install-autostart
}

# --- launch now (detached; GUI-subsystem exe, so no console window) ---
if (-not $NoLaunch) {
  Start-Process $ExePath -ArgumentList "tray"
  Write-Host "Tray launched. Look for the Harrier eagle in the notification area (click the ^ overflow if hidden)."
}
