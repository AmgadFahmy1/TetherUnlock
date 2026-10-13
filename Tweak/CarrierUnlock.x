#import "Headers/TetherHeaders.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

%hook CTTelephonyNetworkInfo

// Hook subscriberCellularProvider to return modified carrier info
- (CTCarrier*)subscriberCellularProvider {
    CTCarrier *original = %orig;
    
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tetherunlock.prefs"];
    BOOL carrierUnlock = [defaults boolForKey:kCarrierUnlockEnabled];
    NSString *apn = [defaults stringForKey:kCustomAPN];
    
    if (carrierUnlock && original) {
        // Log carrier info for debugging
        NSLog(@"[TetherUnlock] Original carrier: %@, MCC: %@, MNC: %@",
              [original carrierName],
              [original mobileCountryCode],
              [original mobileNetworkCode]);
        
        // Note: We can't modify CTCarrier directly as it's immutable
        // The actual unlock happens through method swizzling of data plan checks
    }
    
    [defaults release];
    return original;
}

- (BOOL)isDataPlanEnabled {
    BOOL original = %orig;
    
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tetherunlock.prefs"];
    BOOL carrierUnlock = [defaults boolForKey:kCarrierUnlockEnabled];
    
    if (carrierUnlock && !original) {
        NSLog(@"[TetherUnlock] Forcing data plan enabled");
        [defaults release];
        return YES;
    }
    
    [defaults release];
    return original;
}

%end

// Hook CTCarrier methods for tethering support
%hook CTCarrier

- (BOOL)supportsCellularData {
    BOOL original = %orig;
    
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tetherunlock.prefs"];
    BOOL carrierUnlock = [defaults boolForKey:kCarrierUnlockEnabled];
    
    if (carrierUnlock) {
        [defaults release];
        return YES;
    }
    
    [defaults release];
    return original;
}

- (BOOL)supports3G {
    return YES; // Always report 3G support for tethering
}

- (BOOL)supports4G {
    return YES;
}

- (BOOL)supportsLTE {
    return YES;
}

%end
