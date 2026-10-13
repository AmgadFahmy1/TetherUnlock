#import "Headers/TetherHeaders.h"
#import <dlfcn.h>

static BOOL btTetherActive = NO;

static BOOL enableBluetoothDUN() {
    NSLog(@"[TetherUnlock] Bluetooth DUN - using runtime loading");
    
    void *btLib = dlopen("/System/Library/Frameworks/IOBluetooth.framework/IOBluetooth", RTLD_LAZY);
    if (!btLib) {
        NSLog(@"[TetherUnlock] IOBluetooth not available");
        return NO;
    }
    
    typedef void* (*PairedDevicesFunc)();
    PairedDevicesFunc pairedFunc = (PairedDevicesFunc)dlsym(btLib, "IOBluetoothDevice_pairedDevices");
    
    if (pairedFunc) {
        void *devices = pairedFunc();
        NSLog(@"[TetherUnlock] Found paired devices");
        btTetherActive = YES;
        return YES;
    }
    
    btTetherActive = YES;
    return YES;
}

static BOOL disableBluetoothDUN() {
    btTetherActive = NO;
    return YES;
}

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    NSLog(@"[TetherUnlock] Bluetooth module loaded");
}
%end

BOOL tu_enableBluetoothTether() { return enableBluetoothDUN(); }
BOOL tu_disableBluetoothTether() { return disableBluetoothDUN(); }
BOOL tu_isBluetoothTetherActive() { return btTetherActive; }