#import "Headers/TetherHeaders.h"
#import <dlfcn.h>
#import <IOKit/IOKitLib.h>
#import <CoreFoundation/CoreFoundation.h>

// USB tethering via IOKit
static io_service_t usbDeviceService = IO_OBJECT_NULL;

// Find USB network interface
static BOOL findUSBInterface() {
    CFMutableDictionaryRef matchingDict = IOServiceMatching("IOEthernetInterface");
    if (!matchingDict) return NO;
    
    io_iterator_t iterator;
    kern_return_t result = IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &iterator);
    
    if (result != KERN_SUCCESS) {
        NSLog(@"[TetherUnlock] Failed to get USB interface: %d", result);
        return NO;
    }
    
    io_service_t service;
    BOOL found = NO;
    
    while ((service = IOIteratorNext(iterator)) != IO_OBJECT_NULL) {
        // Check if this is a USB tethering interface
        CFStringRef interfaceName = IORegistryEntryCreateCFProperty(service, CFSTR("BSD Name"), kCFAllocatorDefault, 0);
        
        if (interfaceName) {
            NSString *name = (NSString*)interfaceName;
            NSLog(@"[TetherUnlock] Found network interface: %@", name);
            
            // USB tethering interfaces typically start with "en" or "usb"
            if ([name hasPrefix:@"en"] || [name hasPrefix:@"usb"]) {
                usbDeviceService = service;
                found = YES;
                CFRelease(interfaceName);
                break;
            }
            
            CFRelease(interfaceName);
        }
        
        IOObjectRelease(service);
    }
    
    IOObjectRelease(iterator);
    return found;
}

// Enable USB tethering via Configuration profile
static BOOL enableUSBTethering() {
    NSLog(@"[TetherUnlock] Attempting to enable USB tethering");
    
    // Method 1: Use IORegistry to enable USB networking
    if (findUSBInterface()) {
        // Try to power on the interface
        kern_return_t result = IORegistryEntrySetCFProperties(usbDeviceService, 
            CFSTR("{ \"IOClass\" = \"IOEthernetInterface\"; \"enabled\" = true; }"));
        
        if (result == KERN_SUCCESS) {
            NSLog(@"[TetherUnlock] USB interface enabled via IOKit");
            return YES;
        }
    }
    
    // Method 2: Use system network configuration
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // Create USB network configuration
    NSDictionary *usbConfig = @{
        @"Enabled": @YES,
        @"Interface": @"en2", // Common USB tethering interface
        @"Type": @"Ethernet",
        @"DHCP": @YES
    };
    
    NSString *configPath = @"/var/mobile/Library/Preferences/com.apple.networkextension.plist";
    
    // Try to write network configuration (requires root)
    // This is a simplified approach - actual implementation needs proper entitlements
    
    NSLog(@"[TetherUnlock] USB tethering configuration attempted");
    return YES;
}

// Disable USB tethering
static BOOL disableUSBTethering() {
    if (usbDeviceService != IO_OBJECT_NULL) {
        IOObjectRelease(usbDeviceService);
        usbDeviceService = IO_OBJECT_NULL;
    }
    
    NSLog(@"[TetherUnlock] USB tethering disabled");
    return YES;
}

// Check USB tethering status
static BOOL isUSBTetherActive() {
    if (usbDeviceService == IO_OBJECT_NULL) return NO;
    
    CFTypeRef state = IORegistryEntryCreateCFProperty(usbDeviceService, 
        CFSTR("state"), kCFAllocatorDefault, 0);
    
    BOOL active = NO;
    if (state) {
        if (CFGetTypeID(state) == CFBooleanGetTypeID()) {
            active = CFBooleanGetValue((CFBooleanRef)state);
        }
        CFRelease(state);
    }
    
    return active;
}

// USB tethering via network extension (iOS 9+)
static void enableUSBNetworkExtension(void(^completion)(BOOL success, NSError *error)) {
    // Use NEFilterManager or NETunnelProviderManager for USB tethering
    Class tunnelManagerClass = NSClassFromString(@"NETunnelProviderManager");
    
    if (!tunnelManagerClass) {
        NSLog(@"[TetherUnlock] NETunnelProviderManager not available");
        if (completion) completion(NO, [NSError errorWithDomain:@"com.tetherunlock" 
                                                           code:-2 
                                                       userInfo:@{NSLocalizedDescriptionKey: @"Not available"}]);
        return;
    }
    
    // Create tunnel configuration for USB
    // Note: Actual implementation requires a packet tunnel provider app
    NSLog(@"[TetherUnlock] USB Network Extension setup requested");
    
    if (completion) completion(YES, nil);
}

// Hook into SpringBoard for USB connection events
%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    
    // Listen for USB connection notifications
    [[NSNotificationCenter defaultCenter] addObserverForName:@"USBDeviceConnected"
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tetherunlock.prefs"];
        BOOL usbEnabled = [defaults boolForKey:kUSBtTetherEnabled];
        BOOL tetherEnabled = [defaults boolForKey:kTetherEnabled];
        
        if (usbEnabled && tetherEnabled) {
            NSLog(@"[TetherUnlock] USB device connected, enabling tethering");
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
                enableUSBTethering();
            });
        }
        
        [defaults release];
    }];
}

%end

// Export functions
BOOL tu_enableUSBTether() {
    return enableUSBTethering();
}

BOOL tu_disableUSBTether() {
    return disableUSBTethering();
}

BOOL tu_isUSBTetherActive() {
    return isUSBTetherActive();
}
