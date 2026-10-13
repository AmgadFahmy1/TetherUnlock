THEOS_PACKAGE_SCHEME=rootless
TARGET := iphone:clang:15.6:15.0
ARCHS = arm64 arm64e

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TetherUnlock

TetherUnlock_FILES = Tweak/Tweak.x \
                     Tweak/TetherCore.x \
                     Tweak/WiFiTether.x \
                     Tweak/USBTether.x \
                     Tweak/BluetoothTether.x \
                     Tweak/CarrierUnlock.x \
                     Tweak/NetworkConfig.x \
                     Tweak/VPNShare.x \
                     Tweak/NativeTether.x

TetherUnlock_CFLAGS = -Wno-deprecated-declarations -Wno-error -Wno-unused-variable -Wno-unused-function
TetherUnlock_FRAMEWORKS = UIKit CoreTelephony NetworkExtension SystemConfiguration IOKit Foundation
TetherUnlock_PRIVATE_FRAMEWORKS = Preferences MobileWiFi
TetherUnlock_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk

TOOL_NAME = toggleTether

toggleTether_FILES = NativeTether/toggleTether.m
toggleTether_CFLAGS = -Wno-deprecated-declarations
toggleTether_FRAMEWORKS = Foundation CoreFoundation
toggleTether_CODESIGN_FLAGS = -SNativeTether/entitlements.plist
toggleTether_INSTALL_PATH = /usr/bin

include $(THEOS_MAKE_PATH)/tool.mk

SUBPROJECTS += Prefs
include $(THEOS_MAKE_PATH)/aggregate.mk
