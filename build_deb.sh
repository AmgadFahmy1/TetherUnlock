#!/bin/bash
# TetherUnlock Build Script
# Builds .deb package for jailbroken iPadOS 15.0-15.4.1 (Xina15 rootless)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  TetherUnlock .deb Builder${NC}"
echo -e "${GREEN}========================================${NC}"

# Check for Theos
if [ -z "$THEOS" ]; then
    if [ -d "$HOME/theos" ]; then
        export THEOS="$HOME/theos"
    elif [ -d "/opt/theos" ]; then
        export THEOS="/opt/theos"
    else
        echo -e "${RED}Error: Theos not found!${NC}"
        echo -e "${YELLOW}Install Theos from: https://theos.dev${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}Using Theos at: $THEOS${NC}"

# Check for SDK
if [ ! -d "$THEOS/sdks" ] || [ -z "$(ls -A "$THEOS/sdks" 2>/dev/null)" ]; then
    echo -e "${YELLOW}Warning: No iOS SDKs found in $THEOS/sdks${NC}"
    echo -e "${YELLOW}Download iOS 15.5 SDK and place in $THEOS/sdks/${NC}"
fi

# Clean previous builds
echo -e "${GREEN}Cleaning previous builds...${NC}"
make clean 2>/dev/null || true
rm -rf .theos
rm -rf packages

# Set build environment
export TARGET="iphone:clang:15.5:15.0"
export ARCHS="arm64 arm64e"
export THEOS_PACKAGE_SCHEME="rootless"

# Build
echo -e "${GREEN}Building TetherUnlock tweak...${NC}"
make package FINALPACKAGE=1

# Check if build succeeded
if [ $? -eq 0 ]; then
    DEB_FILE=$(ls packages/*.deb 2>/dev/null | head -1)
    
    if [ -n "$DEB_FILE" ]; then
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}  Build Successful!${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}Package: $DEB_FILE${NC}"
        echo -e "${GREEN}Size: $(du -h "$DEB_FILE" | cut -f1)${NC}"
        echo ""
        echo -e "${YELLOW}Installation Instructions:${NC}"
        echo "1. Copy the .deb file to your iPad"
        echo "2. Open in Sileo/Zebra package manager"
        echo "3. Install and respring"
        echo ""
        echo -e "${YELLOW}Or install via SSH:${NC}"
        echo "  scp $DEB_FILE root@<iPad-IP>:/tmp/"
        echo "  ssh root@<iPad-IP}"
        echo "  dpkg -i /tmp/$(basename $DEB_FILE)"
        echo "  sbreload"
    else
        echo -e "${RED}Error: No .deb file generated${NC}"
        exit 1
    fi
else
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi
