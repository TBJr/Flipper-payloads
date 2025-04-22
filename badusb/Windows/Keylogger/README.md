# 🛡️ Keylogger (Flipper Payload)

A stealthy PowerShell-based keylogger for Windows 10/11. It logs keystrokes, sends logs to a Discord webhook on a set schedule, and can self-destruct using a killswitch.

## Features
- 📝 Logs keystrokes to a hidden `.log` file
- ⏰ Sends logs every hour or at a custom `$log` time
- 🧨 Optional `$ks` (killswitch) auto-deletes the logger
- 🕶️ Obfuscated PowerShell execution
- 🔗 Exfil via Discord webhook

## Usage
- Flipper injects PowerShell that sets `$env:DC_WEBHOOK`, `$env:LOG_TIME`, and `$env:KILLSWITCH`
- Script is downloaded and run from GitHub Pages

## Caution
Educational use only. Unauthorized keylogging may violate privacy laws.

## Credits
Inspired by I am Jakoby. Rebuilt and refactored by **TBJr**
