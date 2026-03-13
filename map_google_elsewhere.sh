#!/bin/bash

# This script modifies the local /etc/hosts file to redirect requests for google.com
# to a user-specified IP address. 
# 
# Note: Modifying /etc/hosts overrides the standard DNS resolution for the specified domains locally.
# This should only be used for system administration, local development, or educational purposes 
# on systems you own or have explicit permission to modify.

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (e.g., using sudo) to modify /etc/hosts."
  exit 1
fi

echo "Google to Custom IP Mapper"
echo "--------------------------"
echo "Select the site you want to map google.com to:"
echo "1) Amazon (amazon.com)"
echo "2) eBay (ebay.com)"
echo "3) Best Buy (bestbuy.com)"
echo "4) Apple (apple.com)"
echo "5) Custom IP address"
read -p "Enter your choice (1-5): " CHOICE

case $CHOICE in
  1) TARGET_DOMAIN="amazon.com" ;;
  2) TARGET_DOMAIN="ebay.com" ;;
  3) TARGET_DOMAIN="bestbuy.com" ;;
  4) TARGET_DOMAIN="apple.com" ;;
  5)
    read -p "Enter custom IP address: " TARGET_IP
    ;;
  *)
    echo "Error: Invalid choice."
    exit 1
    ;;
esac

if [ -n "$TARGET_DOMAIN" ]; then
  echo "Resolving IP for $TARGET_DOMAIN..."
  # Use dig to get the first IPv4 address
  TARGET_IP=$(dig +short "$TARGET_DOMAIN" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -n 1)
  if [ -z "$TARGET_IP" ]; then
    echo "Error: Could not resolve IP for $TARGET_DOMAIN."
    exit 1
  fi
  echo "Resolved $TARGET_DOMAIN to $TARGET_IP"
fi

if [ -z "$TARGET_IP" ]; then
  echo "Error: IP address cannot be empty."
  exit 1
fi

# Create a backup of the original hosts file before making changes
BACKUP_FILE="/etc/hosts.bak_$(date +%s)"
cp /etc/hosts "$BACKUP_FILE"
echo "Created backup of /etc/hosts at $BACKUP_FILE"

# Remove existing lines containing google.com to prevent duplicates
# Note: macOS requires the extension argument for -i, so we use -i.tmp
sed -i.tmp '/[[:space:]]google\.com/d' /etc/hosts
sed -i.tmp '/[[:space:]]www\.google\.com/d' /etc/hosts
rm -f /etc/hosts.tmp

# Append the new target mappings
echo "$TARGET_IP google.com" >> /etc/hosts
echo "$TARGET_IP www.google.com" >> /etc/hosts

echo ""
echo "Successfully mapped google.com and www.google.com to $TARGET_IP."
echo "To revert these changes later, you can restore from the backup or manually remove the lines from /etc/hosts."
echo ""
echo "Note: You may need to flush your DNS cache to see the changes take effect immediately."
echo "On macOS, you can do this by running:"
echo "  sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
