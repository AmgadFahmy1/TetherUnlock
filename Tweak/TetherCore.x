#import "Headers/TetherHeaders.h"

// Main tethering controller
@interface TetherCore : NSObject
+ (instancetype)shared;
- (void)enableAllTethering;
- (void)disableAllTethering;
- (void)enableTetheringType:(TetheringType)type;
- (void)disableTetheringType:(TetheringType)type;
- (BOOL)isTetheringActive;
- (NSDictionary*)getTetheringStatus;
- (void)enableVPNSharing;
- (void)disableVPNSharing;
- (BOOL)isVPNSharingActive;
@end

@implementation TetherCore {
    BOOL vpnSharingEnabled;
}

+ (instancetype)shared {
    static TetherCore *shared;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        shared = [[TetherCore alloc] init];
    });
    
    return shared;
}

- (void)enableAllTethering {
    NSLog(@"[TetherUnlock] Enabling all tethering methods");
    
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tetherunlock.prefs"];
    [defaults setBool:YES forKey:kTetherEnabled];
    [defaults synchronize];
    [defaults release];
    
    // Enable carrier unlock first
    [self unlockCarrier];
    
    // Enable each tethering method based on preferences
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        // Wi-Fi tethering
        if ([self isWiFiTetherEnabled]) {
            [self enableTetheringType:TetheringTypeWiFi];
        }
        
        // USB tethering
        if ([self isUSBTetherEnabled]) {
            [self enableTetheringType:TetheringTypeUSB];
        }
        
        // Bluetooth tethering
        if ([self isBluetoothTetherEnabled]) {
            [self enableTetheringType:TetheringTypeBluetooth];
        }
    });
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TetherUnlockStateChanged
                                                        object:nil
                                                      userInfo:@{@"enabled": @YES}];
}

- (void)disableAllTethering {
    NSLog(@"[TetherUnlock] Disabling all tethering methods");
    
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tetherunlock.prefs"];
    [defaults setBool:NO forKey:kTetherEnabled];
    [defaults synchronize];
    [defaults release];
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        [self disableTetheringType:TetheringTypeWiFi];
        [self disableTetheringType:TetheringTypeUSB];
        [self disableTetheringType:TetheringTypeBluetooth];
    });
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TetherUnlockStateChanged
                                                        object:nil
                                                      userInfo:@{@"enabled": @NO}];
}

- (void)enableTetheringType:(TetheringType)type {
    switch (type) {
        case TetheringTypeWiFi: {
            NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tetherunlock.prefs"];
            NSString *ssid = [defaults stringForKey:kWiFiSSID];
            NSString *password = [defaults stringForKey:kWiFiPassword];
            
            if (!ssid) {
                NSString *deviceName = [[UIDevice currentDevice] name];
                ssid = [NSString stringWithFormat:@"%@ Tether", deviceName];
            }
            if (!password) password = @"tetherunlock123";
            
            [defaults setBool:YES forKey:kWiFiTetherEnabled];
            [defaults synchronize];
            [defaults release];
            
            // Call Wi-Fi tether function
            BOOL (*enableWiFi)(NSString*, NSString*) = NULL;
            enableWiFi = (BOOL (*)(NSString*, NSString*))CFBundleGetFunctionPointerForName(
                CFBundleGetMainBundle(), CFSTR("tu_enableWiFiTether"));
            
            if (enableWiFi) {
                enableWiFi(ssid, password);
            }
            break;
        }
            
        case TetheringTypeUSB: {
            NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tetherunlock.prefs"];
            [defaults setBool:YES forKey:kUSBtTetherEnabled];
            [defaults synchronize];
            [defaults release];
            
            BOOL (*enableUSB)() = NULL;
            enableUSB = (BOOL (*)())CFBundleGetFunctionPointerForName(
                CFBundleGetMainBundle(), CFSTR("tu_enableUSBTether"));
            
            if (enableUSB) {
                enableUSB();
            }
            break;
        }
            
        case TetheringTypeBluetooth: {
            NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tetherunlock.prefs"];
            [defaults setBool:YES forKey:kBTTetherEnabled];
            [defaults synchronize];
            [defaults release];
            
            BOOL (*enableBT)() = NULL;
            enableBT = (BOOL (*)())CFBundleGetFunctionPointerForName(
                CFBundleGetMainBundle(), CFSTR("tu_enableBluetoothTether"));
            
            if (enableBT) {
                enableBT();
            }
            break;
        }
            
        default:
            break;
    }
}

- (void)disableTetheringType:(TetheringType)type {
    switch (type) {
        case TetheringTypeWiFi: {
            NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tetherunlock.prefs"];
            [defaults setBool:NO forKey:kWiFiTetherEnabled];
            [defaults synchronize];
            [defaults release];
            
            BOOL (*disableWiFi)() = NULL;
            disableWiFi = (BOOL (*)())CFBundleGetFunctionPointerForName(
                CFBundleGetMainBundle(), CFSTR("tu_disableWiFiTether"));
            
            if (disableWiFi) {
                disableWiFi();
            }
            break;
        }
            
        case TetheringTypeUSB: {
            NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tetherunlock.prefs"];
            [defaults setBool:NO forKey:kUSBtTetherEnabled];
            [defaults synchronize];
            [defaults release];
            
            BOOL (*disableUSB)() = NULL;
            disableUSB = (BOOL (*)())CFBundleGetFunctionPointerForName(
                CFBundleGetMainBundle(), CFSTR("tu_disableUSBTether"));
            
            if (disableUSB) {
                disableUSB();
            }
            break;
        }
            
        case TetheringTypeBluetooth: {
            NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tetherunlock.prefs"];
            [defaults setBool:NO forKey:kBTTetherEnabled];
            [defaults synchronize];
            [defaults release];
            
            BOOL (*disableBT)() = NULL;
            disableBT = (BOOL (*)())CFBundleGetFunctionPointerForName(
                CFBundleGetMainBundle(), CFSTR("tu_disableBluetoothTether"));
            
            if (disableBT) {
                disableBT();
            }
            break;
        }
            
        default:
            break;
    }
}

- (BOOL)isTetheringActive {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tetherunlock.prefs"];
    BOOL enabled = [defaults boolForKey:kTetherEnabled];
    [defaults release];
    return enabled;
}

- (BOOL)isWiFiTetherEnabled {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tetherunlock.prefs"];
    BOOL enabled = [defaults boolForKey:kWiFiTetherEnabled];
    [defaults release];
    return enabled;
}

- (BOOL)isUSBTetherEnabled {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tetherunlock.prefs"];
    BOOL enabled = [defaults boolForKey:kUSBtTetherEnabled];
    [defaults release];
    return enabled;
}

- (BOOL)isBluetoothTetherEnabled {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tetherunlock.prefs"];
    BOOL enabled = [defaults boolForKey:kBTTetherEnabled];
    [defaults release];
    return enabled;
}

- (NSDictionary*)getTetheringStatus {
    NSMutableDictionary *status = [NSMutableDictionary dictionary];
    
    status[@"active"] = @([self isTetheringActive]);
    status[@"wifi"] = @([self isWiFiTetherEnabled]);
    status[@"usb"] = @([self isUSBTetherEnabled]);
    status[@"bluetooth"] = @([self isBluetoothTetherEnabled]);
    status[@"vpn_sharing"] = @(vpnSharingEnabled);
    
    // Get connected client count
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tetherunlock.prefs"];
    status[@"ssid"] = [defaults stringForKey:kWiFiSSID] ?: @"Unknown";
    [defaults release];
    
    return status;
}

- (void)enableVPNSharing {
    NSLog(@"[TetherUnlock] Enabling VPN sharing");
    
    vpnSharingEnabled = YES;
    
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tetherunlock.prefs"];
    [defaults setBool:YES forKey:kVPNPassthroughEnabled];
    [defaults setBool:YES forKey:kVPNShareOverTether];
    [defaults synchronize];
    [defaults release];
    
    // Enable VPN passthrough
    void (*enableVPN)() = NULL;
    enableVPN = (void (*)())CFBundleGetFunctionPointerForName(
        CFBundleGetMainBundle(), CFSTR("tu_enableVPNPassthrough"));
    
    if (enableVPN) {
        enableVPN();
    }
    
    // Share VPN over tether
    BOOL (*shareVPN)() = NULL;
    shareVPN = (BOOL (*)())CFBundleGetFunctionPointerForName(
        CFBundleGetMainBundle(), CFSTR("tu_shareVPNOverTether"));
    
    if (shareVPN) {
        shareVPN();
    }
    
    NSLog(@"[TetherUnlock] VPN sharing enabled");
}

- (void)disableVPNSharing {
    NSLog(@"[TetherUnlock] Disabling VPN sharing");
    
    vpnSharingEnabled = NO;
    
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tetherunlock.prefs"];
    [defaults setBool:NO forKey:kVPNPassthroughEnabled];
    [defaults setBool:NO forKey:kVPNShareOverTether];
    [defaults synchronize];
    [defaults release];
    
    void (*disableVPN)() = NULL;
    disableVPN = (void (*)())CFBundleGetFunctionPointerForName(
        CFBundleGetMainBundle(), CFSTR("tu_disableVPNPassthrough"));
    
    if (disableVPN) {
        disableVPN();
    }
    
    NSLog(@"[TetherUnlock] VPN sharing disabled");
}

- (BOOL)isVPNSharingActive {
    return vpnSharingEnabled;
}

- (void)unlockCarrier {
    // Apply carrier unlock
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tetherunlock.prefs"];
    [defaults setBool:YES forKey:kCarrierUnlockEnabled];
    [defaults synchronize];
    [defaults release];
    
    NSLog(@"[TetherUnlock] Carrier unlock applied");
}

@end

// Export for use by other modules
TetherCore* TUCore() {
    return [TetherCore shared];
}
