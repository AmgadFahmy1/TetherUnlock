#!/bin/bash
# TetherUnlock Universal Build Script
# Builds both .deb and .ipa packages

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${BOLD}${GREEN}"
echo "╔══════════════════════════════════════════╗"
echo "║     TetherUnlock Universal Builder       ║"
echo "║   iPadOS 15.0-15.4.1 / Xina15           ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# Parse arguments
BUILD_DEB=true
BUILD_IPA=true
RELEASE=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --deb-only)
            BUILD_IPA=false
            shift
            ;;
        --ipa-only)
            BUILD_DEB=false
            shift
            ;;
        --debug)
            RELEASE=false
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --deb-only    Build only .deb package"
            echo "  --ipa-only    Build only .ipa package"
            echo "  --debug       Build debug version"
            echo "  --help        Show this help"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Function to check dependencies
check_dependencies() {
    local missing=()
    
    if [ "$BUILD_DEB" = true ]; then
        if [ -z "$THEOS" ] && [ ! -d "$HOME/theos" ] && [ ! -d "/opt/theos" ]; then
            missing+=("Theos (for .deb)")
        fi
    fi
    
    if [ "$BUILD_IPA" = true ]; then
        if ! command -v xcodebuild &> /dev/null; then
            missing+=("Xcode (for .ipa)")
        fi
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${YELLOW}Missing dependencies:${NC}"
        for dep in "${missing[@]}"; do
            echo "  - $dep"
        done
        echo ""
        echo -e "${YELLOW}You can also use Docker to build:${NC}"
        echo "  docker build -t tetherunlock ."
        echo "  docker run -v \$(pwd):/build tetherunlock"
        return 1
    fi
    return 0
}

# Build .deb
build_deb() {
    echo -e "${CYAN}${BOLD}━━━ Building .deb Package ━━━${NC}"
    
    if [ -z "$THEOS" ]; then
        if [ -d "$HOME/theos" ]; then
            export THEOS="$HOME/theos"
        elif [ -d "/opt/theos" ]; then
            export THEOS="/opt/theos"
        else
            echo -e "${RED}Theos not found${NC}"
            return 1
        fi
    fi
    
    # Clean
    make clean 2>/dev/null || true
    rm -rf .theos packages
    
    # Set flags
    if [ "$RELEASE" = true ]; then
        FINAL_FLAG="FINALPACKAGE=1"
    else
        FINAL_FLAG=""
    fi
    
    # Build
    if make package $FINAL_FLAG; then
        DEB_FILE=$(ls packages/*.deb 2>/dev/null | head -1)
        if [ -n "$DEB_FILE" ]; then
            echo -e "${GREEN}✓ .deb built: $DEB_FILE${NC}"
            return 0
        fi
    fi
    
    echo -e "${RED}✗ .deb build failed${NC}"
    return 1
}

# Build .ipa
build_ipa() {
    echo -e "${CYAN}${BOLD}━━━ Building .ipa Package ━━━${NC}"
    
    # Set team ID if provided
    if [ -n "$DEVELOPMENT_TEAM" ]; then
        export DEVELOPMENT_TEAM
    fi
    
    # Run IPA build script
    if bash "$SCRIPT_DIR/build_ipa.sh"; then
        IPA_FILE="companion/export/TetherUnlock.ipa"
        if [ -f "$IPA_FILE" ]; then
            echo -e "${GREEN}✓ .ipa built: $IPA_FILE${NC}"
            return 0
        fi
    fi
    
    echo -e "${RED}✗ .ipa build failed${NC}"
    return 1
}

# Main build process
echo -e "${BOLD}Checking dependencies...${NC}"
check_dependencies || {
    echo -e "${YELLOW}Continuing with available builds...${NC}"
    if ! command -v xcodebuild &> /dev/null; then
        BUILD_IPA=false
        echo -e "${YELLOW}Skipping .ipa (Xcode not available)${NC}"
    fi
    if [ -z "$THEOS" ] && [ ! -d "$HOME/theos" ] && [ ! -d "/opt/theos" ]; then
        BUILD_DEB=false
        echo -e "${YELLOW}Skipping .deb (Theos not available)${NC}"
    fi
}

# Build packages
SUCCESS=true
RESULTS=""

if [ "$BUILD_DEB" = true ]; then
    if build_deb; then
        RESULTS+="  ✓ TetherUnlock.deb\n"
    else
        RESULTS+="  ✗ TetherUnlock.deb (failed)\n"
        SUCCESS=false
    fi
fi

if [ "$BUILD_IPA" = true ]; then
    if build_ipa; then
        RESULTS+="  ✓ TetherUnlock.ipa\n"
    else
        RESULTS+="  ✗ TetherUnlock.ipa (failed)\n"
        SUCCESS=false
    fi
fi

# Summary
echo ""
echo -e "${BOLD}${GREEN}"
echo "╔══════════════════════════════════════════╗"
echo "║           Build Summary                  ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${BOLD}Packages created:${NC}"
echo -e "$RESULTS"

if [ "$SUCCESS" = true ]; then
    echo -e "${GREEN}${BOLD}Build completed successfully!${NC}"
    echo ""
    echo -e "${CYAN}Output locations:${NC}"
    [ "$BUILD_DEB" = true ] && echo "  .deb: packages/"
    [ "$BUILD_IPA" = true ] && echo "  .ipa: companion/export/"
else
    echo -e "${YELLOW}${BOLD}Build completed with warnings${NC}"
fi
