#!/bin/bash
# TetherUnlock IPA Builder
# Builds .ipa companion app for sideloading

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  TetherUnlock IPA Builder${NC}"
echo -e "${GREEN}========================================${NC}"

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Error: Xcode not found!${NC}"
    echo -e "${YELLOW}Install Xcode from the App Store${NC}"
    exit 1
fi

# Check for Xcode version
XCODE_VERSION=$(xcodebuild -version | head -1)
echo -e "${GREEN}Using: $XCODE_VERSION${NC}"

# Set variables
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="TetherUnlockApp"
SCHEME="TetherUnlockApp"
BUILD_DIR="$PROJECT_DIR/companion/build"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_PATH="$PROJECT_DIR/companion/export"
IPA_NAME="TetherUnlock.ipa"

# Clean previous builds
echo -e "${GREEN}Cleaning previous builds...${NC}"
rm -rf "$BUILD_DIR"
rm -rf "$EXPORT_PATH"
mkdir -p "$BUILD_DIR"

# Build settings
DEVICE="generic/platform=iOS"
CONFIGURATION="Release"
DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-}"

echo -e "${CYAN}Project: $PROJECT_DIR/companion/$APP_NAME.xcodeproj${NC}"
echo -e "${CYAN}Configuration: $CONFIGURATION${NC}"

# Archive
echo -e "${GREEN}Creating archive...${NC}"
xcodebuild \
    -project "$PROJECT_DIR/companion/$APP_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "$DEVICE" \
    -archivePath "$ARCHIVE_PATH" \
    DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
    CODE_SIGN_STYLE=Automatic \
    archive

if [ $? -ne 0 ]; then
    echo -e "${RED}Archive failed!${NC}"
    echo -e "${YELLOW}Make sure you have set DEVELOPMENT_TEAM in Xcode${NC}"
    exit 1
fi

echo -e "${GREEN}Archive created successfully${NC}"

# Export IPA
echo -e "${GREEN}Exporting IPA...${NC}"

# Create export options plist
EXPORT_OPTIONS="$BUILD_DIR/ExportOptions.plist"
cat > "$EXPORT_OPTIONS" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>$DEVELOPMENT_TEAM</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EOF

mkdir -p "$EXPORT_PATH"

xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS"

if [ $? -ne 0 ]; then
    echo -e "${RED}IPA export failed!${NC}"
    
    # Alternative: Manual export
    echo -e "${YELLOW}Trying manual export...${NC}"
    
    APP_PATH="$ARCHIVE_PATH/Products/Applications/$APP_NAME.app"
    
    if [ -d "$APP_PATH" ]; then
        IPA_PATH="$EXPORT_PATH/$IPA_NAME"
        
        mkdir -p "$EXPORT_PATH/Payload"
        cp -R "$APP_PATH" "$EXPORT_PATH/Payload/"
        
        cd "$EXPORT_PATH"
        zip -r "$IPA_NAME" Payload
        rm -rf Payload
        
        echo -e "${GREEN}Manual export successful${NC}"
    else
        exit 1
    fi
fi

# Find the IPA
IPA_FILE=$(find "$EXPORT_PATH" -name "*.ipa" | head -1)

if [ -n "$IPA_FILE" ]; then
    # Rename if needed
    if [ "$IPA_FILE" != "$EXPORT_PATH/$IPA_NAME" ]; then
        mv "$IPA_FILE" "$EXPORT_PATH/$IPA_NAME"
        IPA_FILE="$EXPORT_PATH/$IPA_NAME"
    fi
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Build Successful!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}IPA: $IPA_FILE${NC}"
    echo -e "${GREEN}Size: $(du -h "$IPA_FILE" | cut -f1)${NC}"
    echo ""
    echo -e "${YELLOW}Sideload Instructions:${NC}"
    echo ""
    echo -e "${CYAN}Option 1: AltStore${NC}"
    echo "  1. Install AltStore on your iPad"
    echo "  2. Transfer the .ipa via Files app"
    echo "  3. Open in AltStore and install"
    echo ""
    echo -e "${CYAN}Option 2: SideStore${NC}"
    echo "  1. Install SideStore"
    echo "  2. Import the .ipa"
    echo ""
    echo -e "${CYAN}Option 3: TrollStore (iPadOS 14.0-16.6.1)${NC}"
    echo "  1. Install TrollStore"
    echo "  2. Open the .ipa in Files"
    echo "  3. Share to TrollStore"
    echo ""
    echo -e "${CYAN}Option 4: Sideloadly${NC}"
    echo "  1. Connect iPad to computer"
    echo "  2. Open Sideloadly"
    echo "  3. Drag the .ipa and click Start"
    echo ""
    echo -e "${YELLOW}Note: Free Apple ID limits app to 7 days${NC}"
    echo -e "${YELLOW}      Paid developer account: 1 year${NC}"
else
    echo -e "${RED}No IPA file found!${NC}"
    exit 1
fi
