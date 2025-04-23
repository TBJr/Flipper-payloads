Start-Sleep -Seconds 4

Write-Progress -Activity "Checking System Integrity" -Status "Validating" -PercentComplete 20
Start-Sleep -Milliseconds 800
Write-Progress -Activity "Checking System Integrity" -Status "Running Diagnostics" -PercentComplete 50
Start-Sleep -Milliseconds 700
Write-Progress -Activity "Checking System Integrity" -Status "Finalizing" -PercentComplete 95
Start-Sleep -Milliseconds 500

$tts = ('S'+'A'+'P'+'I'+'.'+'S'+'p'+'V'+'o'+'i'+'c'+'e')
$s = New-Object -ComObject $tts
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

$s.Speak("Hey $fullName, I'm your friendly system auditor.")
$s.Speak("Running basic scans...")

$RAM = (Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).Sum / 1GB
$s.Speak("$RAM gigabytes of RAM detected... impressive waste of electricity.")

Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap 600,400
$graphics = [System.Drawing.Graphics]::FromImage($bmp)
$graphics.Clear([System.Drawing.Color]::Black)
$font = New-Object System.Drawing.Font "Courier New", 16
$brush = [System.Drawing.Brushes]::Red
$msg = "GhostSnitch was here..."
$graphics.DrawString($msg, $font, $brush, 10, 10)
$outPath = "$env:TEMP\clippy_wall.jpg"
$bmp.Save($outPath)
$graphics.Dispose()

Add-Type -TypeDefinition @"
    using System.Runtime.InteropServices;
    public class Wall {
        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
[Wall]::SystemParametersInfo(20, 0, $outPath, 3)

$s.Speak("Wallpaper updated. Clippy would be proud. Logging off.")