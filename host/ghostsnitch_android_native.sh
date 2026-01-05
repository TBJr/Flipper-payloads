#!/system/bin/sh

# GhostSnitch for Android (Native - No Termux Required)
# Author: TBJr
# Version: 3.0
# Description: Recon + Roast prank using Android native shell

# Use Android's built-in TTS via am broadcast
function speak {
  TEXT=$(echo "$1" | sed "s/'/\\\\'/g")
  am broadcast -a android.intent.action.TTS_SERVICE --es text "$TEXT" 2>/dev/null || \
  am start -a android.settings.TTS_SETTINGS 2>/dev/null
  # Fallback: use notify (if available)
  if command -v notify &>/dev/null; then
    notify -t "GhostSnitch" "$1" 2>/dev/null
  fi
  sleep 1
}

# Get device info using getprop (native Android command)
function get_device_info {
  BRAND=$(getprop ro.product.brand 2>/dev/null || echo "Unknown")
  MODEL=$(getprop ro.product.model 2>/dev/null || echo "Unknown")
  ANDROID_VER=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
  speak "You're using a $BRAND $MODEL running Android $ANDROID_VER. Brave, but foolish."
}

# Get RAM info from /proc/meminfo
function get_ram_info {
  if [ -r /proc/meminfo ]; then
    RAM_KB=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
    if [ -n "$RAM_KB" ]; then
      # Calculate GB (using integer division for sh compatibility)
      RAM_GB=$((RAM_KB / 1024 / 1024))
      speak "This device has approximately $RAM_GB gigabytes of RAM. That's cute."
    else
      speak "Couldn't read your RAM info. Probably not enough to matter anyway."
    fi
  else
    speak "Couldn't access memory info. Your device is being secretive."
  fi
}

# Get IP info (requires network)
function get_ip_info {
  IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || curl -s --max-time 5 icanhazip.com 2>/dev/null || echo "unknown")
  if [ "$IP" != "unknown" ] && [ -n "$IP" ]; then
    speak "Your public IP is $IP. And I know where you live now."
  else
    speak "Couldn't fetch your IP address. Probably hiding behind a VPN. Smart move."
  fi
}

# Get WiFi info using native Android commands
function get_wifi_info {
  # Try to get WiFi SSID using dumpsys (requires no special permissions)
  SSID=$(dumpsys wifi 2>/dev/null | grep -i "ssid" | head -1 | sed 's/.*SSID=\([^,]*\).*/\1/' | tr -d '"' || echo "")
  
  if [ -n "$SSID" ] && [ "$SSID" != "null" ]; then
    speak "Your WiFi network is $SSID. Weak sauce."
  else
    # Alternative: check if WiFi is enabled
    WIFI_STATE=$(dumpsys wifi 2>/dev/null | grep -i "Wi-Fi is" | head -1 || echo "")
    if echo "$WIFI_STATE" | grep -qi "enabled"; then
      speak "You're connected to WiFi, but I can't see the network name. Hiding, huh?"
    else
      speak "You're not connected to WiFi. Using mobile data like a peasant."
    fi
  fi
}

# Get contacts info (limited without special permissions)
function get_contacts_hint {
  # Try to get contact count via dumpsys (may not work without permissions)
  CONTACT_COUNT=$(dumpsys contacts 2>/dev/null | grep -c "contact" | head -1 || echo "0")
  if [ "$CONTACT_COUNT" -gt 0 ] 2>/dev/null; then
    speak "You have contacts in your phone. Should I prank call them too?"
  else
    speak "Your contacts are empty. Ghost mode, I respect it."
  fi
}

# Main execution
speak "Hello Android user. Let's begin."
sleep 1
get_device_info
sleep 1
get_ram_info
sleep 1
get_ip_info
sleep 1
get_wifi_info
sleep 1
get_contacts_hint
sleep 1
speak "GhostSnitch Android signing off. Sleep tight."

