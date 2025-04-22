# 🧪 Keylogger Unix

AES-encrypted keylogger for macOS and Linux using bash. Works silently, encrypts logs, and uploads to Discord.

## 🔥 Features
- Logs keystrokes via `script` (or logkeys)
- AES-encrypted output with OpenSSL
- Uploads logs via Discord Webhook
- Crontab persistence (`@reboot`)
- Hidden log files in `~/.local/share/`
- Optional Killswitch using epoch time

## 📦 Requirements
- Bash + `openssl`, `curl`
- Works on macOS and most Linux distributions

## 🚀 Usage
- Upload `keylogger_unix.sh` to GitHub Pages
- Flipper injects one-liner to download + run

## 📌 Educational Use Only
Designed for red team / ethical testing. Unauthorized use is illegal.
