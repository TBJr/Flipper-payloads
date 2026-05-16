# Flipper Payload Arsenal by TBJr

A collection of custom BadUSB payloads for Flipper Zero. Built for pranks, education, and ethical testing only.

---

## Payloads

### Windows

| Payload | Version | Description |
|---|---|---|
| `badusb/Windows/GhostSnitch` | 1.2 | Roast prank — recon, TTS, wallpaper, Discord report |
| `badusb/Windows/GhostSnitch_Stealth` | 1.4 | Same as above with auto-elevation to Administrator |
| `badusb/Windows/GhostSnitch_Stego` | 1.1 | Roast prank — steganographic wallpaper variant |
| `badusb/Windows/Keylogger` | 2.0 | AES-encrypted keystroke logger with optional Discord exfil |

### Unix / macOS

| Payload | Version | Description |
|---|---|---|
| `badusb/Unix/GhostSnitch_Unix` | 1.2 | Roast prank for macOS and Linux — TTS, WiFi, wallpaper |
| `badusb/Unix/Keylogger_Unix` | 2.0 | AES-encrypted keystroke logger — xinput (X11), Wayland, macOS |

### Android

| Payload | Version | Description |
|---|---|---|
| `badusb/Android/GhostSnitch_Android` | 3.2 | Web-based roast via Chrome — device info, IP, TTS |

### iOS

| Payload | Version | Description |
|---|---|---|
| `badusb/iOS/GhostSnitch_iOS` | 1.1 | Web-based roast via Safari — device info, IP, TTS |

---

## Setup Before Deploying

### Discord webhook (Windows GhostSnitch, Unix Keylogger)
The webhook URL is stored as `$webhookUrl = 'REPLACE_ME'` at the top of each script.  
Replace `REPLACE_ME` with your Discord webhook URL before hosting. Exfil is silently skipped when the placeholder is left in place.

### Hosting
All `host/` scripts are served from GitHub Pages at:
```
https://tbjr.github.io/Flipper-payloads/host/<filename>
```
Fork the repo and update the URL in each ducky script if you host your own copy.

---

## Platform Notes

### Web-based payloads (Android & iOS)
Both web payloads show a **"Tap to Continue"** button when the page loads.  
The target must tap it once — this is required by browser autoplay policy and cannot be bypassed from a web page. The TTS roast only fires after that tap.

### Windows keylogger
Delivery changed in v2.0 from a hardcoded Base64 command to `irm | iex`, matching the other Windows payloads. The keylogger now uses `GetAsyncKeyState` for real keystroke capture (the previous `IsKeyLocked` only detected Caps Lock).

### Unix keylogger
- **Linux X11**: works without root via `xinput test`
- **Linux Wayland**: requires root to read `/dev/input/event*`
- **macOS**: requires Accessibility permission + `pyobjc` (`pip3 install pyobjc`)

### WiFi password (Windows)
`netsh wlan show profile key=clear` requires Administrator. GhostSnitch_Stealth auto-elevates; the base GhostSnitch gracefully reports the limitation if not elevated.

---

## Disclaimer

For educational and ethical testing purposes only. Deploying these payloads without explicit permission from the device owner may violate local laws.

---

## Credits

Inspired by **AcidBurn** by [I am Jakoby](https://github.com/I-Am-Jakoby). Extended and rebuilt for multi-platform HID delivery by **TBJr**.
