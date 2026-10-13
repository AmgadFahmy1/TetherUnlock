#import "Headers/TetherHeaders.h"
#import "Headers/CarrierHeaders.h"
#import <dlfcn.h>
#import <objc/runtime.h>

// Global state
static BOOL tetherEnabled = NO;
static BOOL wifiTetherEnabled = NO;
static BOOL usbTetherEnabled = NO;
static BOOL btTetherEnabled = NO;
static NSString *customSSID = nil;
static NSString *customPassword = nil;
static NSString *customAPN = nil;

// Load preferences
static void loadPreferences() {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tetherunlock.prefs"];
    
    tetherEnabled = [defaults boolForKey:kTetherEnabled] ?: NO;
    wifiTetherEnabled = [defaults boolForKey:kWiFiTetherEnabled] ?: YES;
    usbTetherEnabled = [defaults boolForKey:kUSBtTetherEnabled] ?: YES;
    btTetherEnabled = [defaults boolForKey:kBTTetherEnabled] ?: YES;
    
    customSSID = [defaults stringForKey:kWiFiSSID];
    customPassword = [defaults stringForKey:kWiFiPassword];
    customAPN = [defaults stringForKey:kCustomAPN];
    
    if (!customSSID) {
        // Generate default SSID based on device name
        NSString *deviceName = [[UIDevice currentDevice] name];
        customSSID = [NSString stringWithFormat:@"%@ Tether", deviceName];
    }
    
    if (!customPassword) {
        customPassword = @"tetherunlock123"; // Default password
    }
    
    [defaults release];
}

// Notify on state change
static void notifyStateChanged(BOOL enabled) {
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFSTR("com.tetherunlock/statechanged"),
        NULL,
        NULL,
        YES
    );
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TetherUnlockStateChanged
                                                        object:nil
                                                      userInfo:@{@"enabled": @(enabled)}];
}

// Apply carrier unlock
static void applyCarrierUnlock() {
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [networkInfo subscriberCellularProvider];
    
    if (!carrier) return;
    
    // Try to enable data plan if disabled
    if (![carrier isDataPlanEnabled]) {
        // Use private method if available
        if ([carrier respondsToSelector:@selector(setDataPlanEnabled:)]) {
            [carrier performSelector:@selector(setDataPlanEnabled:) withObject:@YES];
        }
    }
    
    [networkInfo release];
}

%ctor {
    @autoreleasepool {
        loadPreferences();
        
        // Register for Darwin notifications
        int token;
        notify_register_dispatch("com.tetherunlock/respring", &token, dispatch_get_main_queue(), ^(int t) {
            loadPreferences();
            if (tetherEnabled) {
                applyCarrierUnlock();
            }
            notifyStateChanged(tetherEnabled);
        });
        
        // Initial carrier unlock if enabled
        if (tetherEnabled) {
            dispatch_async(dispatch_get_main_queue(), ^{
                applyCarrierUnlock();
            });
        }
    }
}
