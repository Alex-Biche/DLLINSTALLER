# DLLINSTALLER

One-command installer for three commonly-missing Windows DLLs:

| DLL | Source |
| --- | --- |
| `VCRUNTIME140.dll` | Microsoft Visual C++ 2015-2022 Redistributable |
| `MSVCP140.dll`     | Microsoft Visual C++ 2015-2022 Redistributable |
| `d3dx9_43.dll`     | DirectX End-User Runtime (legacy DirectX 9) |

The script downloads the **official Microsoft installers** and runs them silently. It does *not* download standalone DLL files from third-party sites, which is a common malware vector.

## Quick start

Open **Windows Terminal (Admin)** or **PowerShell as Administrator**, then paste:

```powershell
irm https://raw.githubusercontent.com/Alex-Biche/DLLINSTALLER/main/Install-Dlls.ps1 | iex
```

That's it. The script will:

1. Download the VC++ Redistributable (x64 and x86) from `aka.ms`
2. Download the DirectX End-User Runtime web installer from `download.microsoft.com`
3. Install all three silently
4. Verify that each DLL is present in `System32` / `SysWOW64`

### Open an admin terminal on Windows 11

Right-click the Start button → **Terminal (Admin)** (or **Windows PowerShell (Admin)**).

### Auto-elevating one-liner

If you're stuck in a non-admin shell, this version relaunches itself elevated:

```powershell
Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-Command','irm https://raw.githubusercontent.com/Alex-Biche/DLLINSTALLER/main/Install-Dlls.ps1 | iex'
```

## Running it locally

If you'd rather clone the repo and run it from disk:

```powershell
git clone https://github.com/Alex-Biche/DLLINSTALLER.git
cd DLLINSTALLER
# Double-click Install-Dlls.cmd, or:
powershell -ExecutionPolicy Bypass -File .\Install-Dlls.ps1
```

`Install-Dlls.cmd` is a launcher that self-elevates and bypasses the execution policy for that one run.

### Optional switches

When running the `.ps1` directly (not via `irm | iex`), you can skip pieces you don't need:

```powershell
.\Install-Dlls.ps1 -SkipVCRedist    # skip Visual C++ Redistributable
.\Install-Dlls.ps1 -SkipDirectX     # skip DirectX runtime
```

## Exit codes

| Code | Meaning |
| --- | --- |
| `0` | All DLLs installed and verified |
| `1` | One or more DLLs not detected after install (a reboot may resolve it) |

The script treats installer exit codes `1638` (a newer version is already installed) and `3010` (reboot required) as success.

## Requirements

- Windows 11 (also works on Windows 10)
- Administrator privileges
- Internet connection (installers are downloaded from Microsoft)

## Safety note

Never run remote scripts from a source you don't control. Read [Install-Dlls.ps1](Install-Dlls.ps1) before running it — it's about 100 lines and only talks to `aka.ms` and `download.microsoft.com`.
