#!/data/data/com.termux/files/usr/bin/bash

# GhostSnitch for Android (via Termux)
# Author: TBJr
# Version: 2.0
# Description: Recon + Roast prank via Termux

function speak {
  if command -v termux-tts-speak &>/dev/null; then
    termux-tts-speak "$1" 2>/dev/null
    sleep 1
  else
    echo "$1"
  fi
}

function get_device_info {
  BRAND=$(getprop ro.product.brand 2>/dev/null || echo "Unknown")
  MODEL=$(getprop ro.product.model 2>/dev/null || echo "Unknown")
  ANDROID_VER=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
  speak "You're using a $BRAND $MODEL running Android $ANDROID_VER. Brave, but foolish."
}

function get_ram_info {
  if [[ -r /proc/meminfo ]]; then
    RAM_KB=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
    if [[ -n "$RAM_KB" ]]; then
      RAM_GB=$(echo "scale=1; $RAM_KB/1024/1024" | bc 2>/dev/null || echo "$(($RAM_KB/1024/1024))")
      speak "This device has approximately $RAM_GB gigabytes of RAM. That's cute."
    else
      speak "Couldn't read your RAM info. Probably not enough to matter anyway."
    fi
  else
    speak "Couldn't access memory info. Your device is being secretive."
  fi
}

function get_ip_info {
  IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || curl -s --max-time 5 icanhazip.com 2>/dev/null || echo "unknown")
  if [[ "$IP" != "unknown" && -n "$IP" ]]; then
    speak "Your public IP is $IP. And I know where you live now."
  else
    speak "Couldn't fetch your IP address. Probably hiding behind a VPN. Smart move."
  fi
}

function get_wifi_info {
  if command -v termux-wifi-connectioninfo &>/dev/null; then
    WIFI_INFO=$(termux-wifi-connectioninfo 2>/dev/null)
    if [[ -n "$WIFI_INFO" ]]; then
      SSID=$(echo "$WIFI_INFO" | grep -o '"ssid"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4 | head -1)
      if [[ -n "$SSID" && "$SSID" != "null" ]]; then
        speak "Your WiFi network is $SSID. Weak sauce."
      else
        speak "You're not connected to WiFi. Using mobile data like a peasant."
      fi
    else
      speak "Couldn't find your WiFi info. Hiding, huh?"
    fi
  else
    speak "Termux API not available. Can't spy on your WiFi network."
  fi
}

function get_contacts_hint {
  if command -v termux-contact-list &>/dev/null; then
    CONTACTS=$(termux-contact-list 2>/dev/null | head -20)
    if [[ -n "$CONTACTS" ]]; then
      CONTACT=$(echo "$CONTACTS" | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4 | head -1)
      if [[ -n "$CONTACT" && "$CONTACT" != "null" ]]; then
        speak "You have someone named $CONTACT in your contacts. Should I prank call them too?"
      else
        speak "Your contacts are empty. Ghost mode, I respect it."
      fi
    else
      speak "Couldn't access your contacts. Privacy settings are actually working for once."
    fi
  else
    speak "Termux API not available. Can't peek at your contacts."
  fi
}

# Main execution
speak "Hello Android user. Let's begin."
sleep 0.5
get_device_info
sleep 0.5
get_ram_info
sleep 0.5
get_ip_info
sleep 0.5
get_wifi_info
sleep 0.5
get_contacts_hint
sleep 0.5
speak "GhostSnitch Android signing off. Sleep tight."
