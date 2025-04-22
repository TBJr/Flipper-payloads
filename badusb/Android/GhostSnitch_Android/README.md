# 🤖 GhostSnitch Android

GhostSnitch adapted for Android using Termux. Executes roast-style recon using device info, TTS, and optional contact scans.

## 🧠 Features
- Collects device brand, model, and Android version
- Reads public IP, RAM info, WiFi SSID (via `termux-wifi-connectioninfo`)
- Optionally pulls a contact name to roast
- Speaks roast using `termux-tts-speak`
- Works on any Android device with Termux + termux-api

## 🚀 How to Use
1. Ensure Termux and `termux-api` are installed on the device
2. Copy the `ghostsnitch_android.sh` to GitHub Pages or local server
3. Flipper runs the Ducky Script to open the hosted URL and execute it via Termux

## 🙏 Credits
Based on the original GhostSnitch prank for Windows. Reimagined for Android by **TBJr**
