# GhostSnitch Android

**Version:** 3.2  
**Author:** I am TBJr  
**Platform:** Android (Chrome browser required)  
**Delivery:** Flipper Zero HID

---

## What it does

Opens Chrome on the target device, navigates to a hosted HTML page, and delivers a roast using device info gathered from browser APIs. An optional Termux path provides enhanced features (WiFi SSID, contacts) when the app is installed.

---

## Files

| File | Purpose |
|---|---|
| `GhostSnitch_Android.txt` | Flipper Zero ducky script |
| `host/ghostsnitch_android.html` | Web-based payload (primary — works on all devices) |
| `host/ghostsnitch_android.sh` | Termux shell script (optional — enhanced features) |
| `host/ghostsnitch_android_native.sh` | Native Android shell script (adb/advanced use) |

---

## Web payload (primary)

The HTML page gathers data via browser APIs and speaks a roast via the Web Speech API.

**Important — tap required:** The page shows a **"Tap to Continue"** button when it loads. The target must tap it once. This is required by Chrome's autoplay policy — `speechSynthesis.speak()` is silently blocked without a prior user gesture and there is no way to bypass it from a web page.

**APIs used:**

| API | iOS Safari | Chrome Android | Notes |
|---|---|---|---|
| User-Agent parsing | ✓ | ✓ | Android version + device model |
| `deviceMemory` | — | ✓ | Returns coarse bucket (0.25–8 GB) |
| `navigator.connection` | — | ✓ | Effective type + downlink |
| `fetch` (IP lookup) | ✓ | ✓ | `api.ipify.org` with `api4.my-ip.io` fallback |
| `geolocation` | ✓ | ✓ | Requires user permission dialog |
| Web Speech API | ✓* | ✓* | *Requires user gesture — handled by tap gate |

---

## Ducky script flow

```
1. GUI          → home screen (Meta key — works on most Android launchers)
2. STRING chrome → launcher search
3. ENTER         → open Chrome
4. CTRL+L        → focus Chrome address bar  ← required; without this the URL goes into the page body
5. STRING <url>
6. ENTER
```

The Termux fallback is commented out by default. Uncomment the block at the bottom of `GhostSnitch_Android.txt` only if Termux is installed on the target.

---

## Termux path (optional)

Requires: **Termux** app + **Termux:API** companion app + `termux-api` package.

```bash
pkg install termux-api
```

Additional features over the web path:
- Real RAM from `/proc/meminfo` (accurate, not a coarse bucket)
- WiFi SSID via `termux-wifi-connectioninfo`
- First contact name via `termux-contact-list` (prompts for Contacts permission)

---

## Known limitations

- **Launcher search varies by device** — Pixel, Samsung One UI, MIUI, and others handle home-screen search differently. The ducky script may need timing adjustments on non-stock launchers.
- **`deviceMemory`** intentionally returns coarse values (browser privacy feature).
- **Geolocation** always shows a permission dialog; the target must tap "Allow".
- **Network Information API** not available in Safari or Firefox — Chrome Android only.
- Termux is not pre-installed on any Android device; the fallback path is for devices where it has already been set up.

---

## Credits

Based on the original GhostSnitch for Windows. Reimagined for Android by **TBJr**.
