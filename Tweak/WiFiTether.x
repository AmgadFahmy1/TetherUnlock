#import "Headers/TetherHeaders.h"
#import <dlfcn.h>
#import <objc/runtime.h>

// MobileWiFi framework loading
static void *wifiFramework = NULL;

typedef const void *TUWiFiManagerClientRef;
typedef const void *TUWiFiDeviceClientRef;

typedef void *(*TUWiFiManagerClientCreate)(CFAllocatorRef allocator, int flags);
typedef CFArrayRef (*TUWiFiManagerClientCopyDevices)(TUWiFiManagerClientRef manager);
typedef void (*TUWiFiManagerClientSetProperty)(TUWiFiManagerClientRef manager, CFStringRef key, CFPropertyListRef value);
typedef BOOL (*TUWiFiDeviceClientPowerOn)(TUWiFiDeviceClientRef device);
typedef void (*TUWiFiDeviceClientSetPower)(TUWiFiDeviceClientRef device, BOOL power);
typedef CFStringRef (*TUWiFiDeviceClientCopyInterfaceName)(TUWiFiDeviceClientRef device);
typedef void (*TUWiFiDeviceClientScanAsync)(TUWiFiDeviceClientRef device, CFDictionaryRef dict, void *callback, void *info);

static TUWiFiManagerClientRef wifiManager = NULL;

// Initialize WiFi framework
static BOOL initWiFiFramework() {
    if (wifiFramework) return YES;
    
    wifiFramework = dlopen("/System/Library/PrivateFrameworks/MobileWiFi.framework/MobileWiFi", RTLD_LAZY);
    if (!wifiFramework) {
        NSLog(@"[TetherUnlock] Failed to load MobileWiFi framework");
        return NO;
    }
    
    TUWiFiManagerClientCreate createFunc = (TUWiFiManagerClientCreate)dlsym(wifiFramework, "WiFiManagerClientCreate");
    if (createFunc) {
        wifiManager = createFunc(kCFAllocatorDefault, 0);
    }
    
    return wifiManager != NULL;
}

// Enable Wi-Fi hotspot via private APIs
static BOOL enableWiFiHotspot(NSString *ssid, NSString *password) {
    if (!initWiFiFramework()) return NO;
    
    TUWiFiManagerClientSetProperty setPropFunc = 
        (TUWiFiManagerClientSetProperty)dlsym(wifiFramework, "WiFiManagerClientSetProperty");
    
    if (!setPropFunc) return NO;
    
    // Create hotspot configuration dictionary
    NSMutableDictionary *hotspotConfig = [NSMutableDictionary dictionary];
    [hotspotConfig setObject:ssid forKey:@"SSID"];
    [hotspotConfig setObject:password forKey:@"password"];
    [hotspotConfig setObject:@YES forKey:@"enabled"];
    [hotspotConfig setObject:@NO forKey:@"isWEP"];
    
    // Set hotspot properties
    NSDictionary *props = @{
        @"tetherEnabled": @YES,
        @"hotspotSSID": ssid,
        @"hotspotPassword": password,
        @"channel": @6, // 2.4GHz channel 6
        @"security": @"WPA2"
    };
    
    CFStringRef keys[] = {
        CFSTR("tetherEnabled"),
        CFSTR("hotspotConfig")
    };
    CFPropertyListRef values[] = {
        kCFBooleanTrue,
        (__bridge CFPropertyListRef)props
    };
    
    CFDictionaryRef dict = CFDictionaryCreate(kCFAllocatorDefault,
                                               (const void**)keys,
                                               (const void**)values,
                                               2,
                                               &kCFTypeDictionaryKeyCallBacks,
                                               &kCFTypeDictionaryValueCallBacks);
    
    setPropFunc(wifiManager, CFSTR("tetherConfig"), dict);
    CFRelease(dict);
    
    return YES;
}

// Disable Wi-Fi hotspot
static BOOL disableWiFiHotspot() {
    if (!initWiFiFramework()) return NO;
    
    TUWiFiManagerClientSetProperty setPropFunc = 
        (TUWiFiManagerClientSetProperty)dlsym(wifiFramework, "WiFiManagerClientSetProperty");
    
    if (!setPropFunc) return NO;
    
    setPropFunc(wifiManager, CFSTR("tetherEnabled"), kCFBooleanFalse);
    return YES;
}

// Get current Wi-Fi status
static BOOL isWiFiEnabled() {
    if (!initWiFiFramework()) return NO;
    
    TUWiFiManagerClientRef manager = wifiManager;
    if (!manager) return NO;
    
    // Try to get WiFiManagerClientCopyPower method
    typedef BOOL (*TUWiFiManagerClientGetPower)(TUWiFiManagerClientRef);
    TUWiFiManagerClientGetPower getPower = 
        (TUWiFiManagerClientGetPower)dlsym(wifiFramework, "WiFiManagerClientGetPower");
    
    if (getPower) {
        return getPower(manager);
    }
    
    return YES; // Assume enabled if we can't check
}

// NEHotspotConfiguration based approach (iOS 11+)
static void enableHotspotNE(NSString *ssid, NSString *password, void(^completion)(BOOL success, NSError *error)) {
    Class configClass = NSClassFromString(@"NEHotspotConfiguration");
    Class managerClass = NSClassFromString(@"NEHotspotConfigurationManager");
    
    if (!configClass || !managerClass) {
        NSLog(@"[TetherUnlock] NEHotspotConfiguration not available");
        if (completion) completion(NO, [NSError errorWithDomain:@"com.tetherunlock" 
                                                           code:-1 
                                                       userInfo:@{NSLocalizedDescriptionKey: @"Not available"}]);
        return;
    }
    
    id config = [[configClass alloc] initWithSSID:ssid passphrase:password isWEP:NO];
    id manager = [managerClass performSelector:@selector(sharedManager)];
    
    [manager applyConfiguration:config completion:^(NSError *error) {
        if (completion) {
            completion(error == nil, error);
        }
    }];
    
    [config release];
}

// Main Wi-Fi tethering controller
%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tetherunlock.prefs"];
    BOOL wifiEnabled = [defaults boolForKey:kWiFiTetherEnabled];
    NSString *ssid = [defaults stringForKey:kWiFiSSID];
    NSString *password = [defaults stringForKey:kWiFiPassword];
    
    if (!ssid) {
        NSString *deviceName = [[UIDevice currentDevice] name];
        ssid = [NSString stringWithFormat:@"%@ Tether", deviceName];
    }
    if (!password) password = @"tetherunlock123";
    
    if (wifiEnabled && [defaults boolForKey:kTetherEnabled]) {
        NSLog(@"[TetherUnlock] Initializing Wi-Fi hotspot: %@", ssid);
        enableHotspotNE(ssid, password, ^(BOOL success, NSError *error) {
            if (success) {
                NSLog(@"[TetherUnlock] Wi-Fi hotspot enabled successfully");
            } else {
                NSLog(@"[TetherUnlock] Failed to enable hotspot: %@", error);
                // Fallback to private API
                enableWiFiHotspot(ssid, password);
            }
        });
    }
    
    [defaults release];
}

%end

// Export functions for other modules
BOOL tu_enableWiFiTether(NSString *ssid, NSString *password) {
    return enableWiFiHotspot(ssid, password);
}

BOOL tu_disableWiFiTether() {
    return disableWiFiHotspot();
}

BOOL tu_isWiFiTetherActive() {
    return isWiFiEnabled();
}
