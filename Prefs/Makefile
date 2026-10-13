THEOS_PACKAGE_SCHEME=rootless
TARGET := iphone:clang:15.6:15.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = TetherUnlockPrefs

TetherUnlockPrefs_FILES = TetherUnlockRootListController.m \
                          TetherUnlockWiFiController.m \
                          TetherUnlockUSBController.m \
                          TetherUnlockBTController.m

TetherUnlockPrefs_INSTALL_PATH = /Library/PreferenceBundles
TetherUnlockPrefs_FRAMEWORKS = UIKit CoreTelephony CoreFoundation
TetherUnlockPrefs_PRIVATE_FRAMEWORKS = Preferences
TetherUnlockPrefs_CFLAGS = -Wno-deprecated-declarations -Wno-error

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/TetherUnlockPrefs.plist$(ECHO_END)
