#!/data/data/com.termux/files/usr/bin/bash

# GhostSnitch for Android (via Termux)
# Author: TBJr
# Version: 1.0
# Description: Recon + Roast prank via Termux

function speak {
  termux-tts-speak "$1"
}

function get_device_info {
  BRAND=$(getprop ro.product.brand)
  MODEL=$(getprop ro.product.model)
  ANDROID_VER=$(getprop ro.build.version.release)
  speak "You’re using a $BRAND $MODEL running Android $ANDROID_VER. Brave, but foolish."
}

function get_ram_info {
  RAM=$(grep MemTotal /proc/meminfo | awk '{print $2/1024/1024 " GB"}')
  speak "This device has approximately $RAM of RAM. That's cute."
}

function get_ip_info {
  IP=$(curl -s ifconfig.me)
  speak "Your public IP is $IP. And I know where you live now."
}

function get_wifi_info {
  if command -v termux-wifi-connectioninfo &>/dev/null; then
    SSID=$(termux-wifi-connectioninfo | grep ssid | cut -d':' -f2 | tr -d '", ')
    speak "Your WiFi network is $SSID. Weak sauce."
  else
    speak "Couldn't find your WiFi info. Hiding, huh?"
  fi
}

function get_contacts_hint {
  CONTACT=$(termux-contact-list | grep -m1 name | cut -d':' -f2 | tr -d '", ')
  if [[ -n "$CONTACT" ]]; then
    speak "You have someone named $CONTACT in your contacts. Should I prank call them too?"
  else
    speak "Your contacts are empty. Ghost mode, I respect it."
  fi
}

speak "Hello Android user. Let's begin."
get_device_info
get_ram_info
get_ip_info
get_wifi_info
get_contacts_hint
speak "GhostSnitch Android signing off. Sleep tight."
