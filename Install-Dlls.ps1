<#
.SYNOPSIS
    Installs VCRUNTIME140.dll, MSVCP140.dll, and d3dx9_43.dll on Windows 11
    by downloading and running the official Microsoft redistributable installers.

.DESCRIPTION
    VCRUNTIME140.dll and MSVCP140.dll ship with the Microsoft Visual C++
    2015-2022 Redistributable. d3dx9_43.dll ships with the DirectX End-User
    Runtime. This script downloads both from Microsoft and installs them
    silently. Run from an elevated PowerShell prompt.

.NOTES
    Do NOT download these DLLs as standalone files from third-party "dll
    download" sites — they are a common malware vector. Always install via
    the official Microsoft redistributables, which is what this script does.
#>

[CmdletBinding()]
param(
    [switch]$SkipVCRedist,
    [switch]$SkipDirectX,
    [string]$WorkDir = (Join-Path $env:TEMP 'DllInstaller')
)

$ErrorActionPreference = 'Stop'

function Assert-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($id)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'This script must be run as Administrator. Right-click PowerShell and choose "Run as administrator".'
    }
}

function Save-File {
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$OutPath
    )
    Write-Host "Downloading $Url"
    # Force TLS 1.2 on older PowerShell hosts
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $Url -OutFile $OutPath -UseBasicParsing
    if (-not (Test-Path $OutPath)) {
        throw "Download failed: $Url"
    }
}

function Invoke-Installer {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string[]]$Arguments,
        [Parameter(Mandatory)][string]$Label,
        [int[]]$SuccessCodes = @(0, 1638, 3010)  # 1638 = newer already installed, 3010 = reboot required
    )
    Write-Host "Installing $Label..."
    $proc = Start-Process -FilePath $Path -ArgumentList $Arguments -Wait -PassThru -NoNewWindow
    if ($SuccessCodes -notcontains $proc.ExitCode) {
        throw "$Label installer exited with code $($proc.ExitCode)"
    }
    if ($proc.ExitCode -eq 1638) {
        Write-Host "  ${Label}: a newer version is already installed (OK)."
    } elseif ($proc.ExitCode -eq 3010) {
        Write-Host "  ${Label}: installed, reboot required."
    } else {
        Write-Host "  ${Label}: installed."
    }
}

function Test-Dll {
    param([string]$Name)
    $sys32 = Join-Path $env:WINDIR 'System32'
    $sysWow = Join-Path $env:WINDIR 'SysWOW64'
    $found = @()
    if (Test-Path (Join-Path $sys32 $Name))  { $found += (Join-Path $sys32 $Name) }
    if (Test-Path (Join-Path $sysWow $Name)) { $found += (Join-Path $sysWow $Name) }
    if ($found.Count -gt 0) {
        Write-Host "  Found $Name at: $($found -join ', ')"
        return $true
    }
    Write-Warning "  $Name not found in System32 or SysWOW64."
    return $false
}

Assert-Admin

if (-not (Test-Path $WorkDir)) {
    New-Item -ItemType Directory -Path $WorkDir | Out-Null
}
Write-Host "Working directory: $WorkDir"

# --- Visual C++ 2015-2022 Redistributable (VCRUNTIME140.dll, MSVCP140.dll) ---
if (-not $SkipVCRedist) {
    $vcX64Url = 'https://aka.ms/vs/17/release/vc_redist.x64.exe'
    $vcX86Url = 'https://aka.ms/vs/17/release/vc_redist.x86.exe'
    $vcX64    = Join-Path $WorkDir 'vc_redist.x64.exe'
    $vcX86    = Join-Path $WorkDir 'vc_redist.x86.exe'

    Save-File -Url $vcX64Url -OutPath $vcX64
    Save-File -Url $vcX86Url -OutPath $vcX86

    Invoke-Installer -Path $vcX64 -Arguments @('/install','/quiet','/norestart') -Label 'VC++ Redistributable (x64)'
    Invoke-Installer -Path $vcX86 -Arguments @('/install','/quiet','/norestart') -Label 'VC++ Redistributable (x86)'
}

# --- DirectX End-User Runtime (d3dx9_43.dll) ---
# d3dx9_*.dll comes from the legacy DirectX 9 runtime, which Windows 11 does
# not include by default. The DirectX web installer fetches and installs it.
if (-not $SkipDirectX) {
    $dxUrl = 'https://download.microsoft.com/download/1/7/1/1718CCC4-6315-4D8E-9543-8E28A4E18C4C/dxwebsetup.exe'
    $dxExe = Join-Path $WorkDir 'dxwebsetup.exe'

    Save-File -Url $dxUrl -OutPath $dxExe
    Invoke-Installer -Path $dxExe -Arguments @('/Q') -Label 'DirectX End-User Runtime' -SuccessCodes @(0, 3010)
}

Write-Host ''
Write-Host 'Verifying installed DLLs...'
$results = @{
    'VCRUNTIME140.dll' = Test-Dll 'VCRUNTIME140.dll'
    'MSVCP140.dll'     = Test-Dll 'MSVCP140.dll'
    'd3dx9_43.dll'     = Test-Dll 'd3dx9_43.dll'
}

Write-Host ''
if ($results.Values -contains $false) {
    Write-Warning 'One or more DLLs were not detected. A reboot may be required, or re-run the script.'
    exit 1
} else {
    Write-Host 'All three DLLs are present. Done.'
    exit 0
}
