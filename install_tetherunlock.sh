#!/bin/bash
# TetherUnlock Quick Installer
# Run this ON YOUR IPAD via Filza Terminal after copying .deb file
# 
# Usage:
# 1. Copy .deb to iPad (e.g., /var/mobile/Documents/)
# 2. Open Filza → tap folder icon → Terminal
# 3. Run: bash /var/mobile/Documents/install_tetherunlock.sh

echo "========================================="
echo "  TetherUnlock Installer"
echo "========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Find the .deb file
DEB_FILE=$(find /var/mobile/Documents /var/mobile/Downloads /tmp -name "*tetherunlock*.deb" 2>/dev/null | head -1)

if [ -z "$DEB_FILE" ]; then
    echo -e "${RED}Error: TetherUnlock.deb not found!${NC}"
    echo ""
    echo "Please copy the .deb file to one of these locations:"
    echo "  - /var/mobile/Documents/"
    echo "  - /var/mobile/Downloads/"
    echo "  - /tmp/"
    echo ""
    echo "You can use AirDrop, iCloud, or Files app to transfer."
    exit 1
fi

echo -e "${GREEN}Found package: $DEB_FILE${NC}"
echo ""

# Check if already installed
if dpkg -l | grep -q tetherunlock; then
    echo -e "${YELLOW}TetherUnlock is already installed. Upgrading...${NC}"
    dpkg -r com.tetherunlock.tweak 2>/dev/null || true
fi

# Install
echo -e "${GREEN}Installing TetherUnlock...${NC}"
dpkg -i "$DEB_FILE"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}  Installation Successful!${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Respring your device"
    echo "2. Open Settings → TetherUnlock"
    echo "3. Configure your preferences"
    echo "4. Enable TetherUnlock"
    echo ""
    read -p "Respring now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Respringing..."
        sbreload 2>/dev/null || killall -9 SpringBoard
    fi
else
    echo -e "${RED}Installation failed!${NC}"
    echo "Error details above. Try:"
    echo "1. Make sure jailbreak is active"
    echo "2. Check available storage"
    echo "3. Try installing via Sileo/Zebra instead"
    exit 1
fi
