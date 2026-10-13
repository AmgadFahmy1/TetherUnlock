#import "Headers/TetherHeaders.h"
#import <IOBluetooth/IOBluetooth.h>
#import <CoreBluetooth/CoreBluetooth.h>

// Bluetooth DUN (Dial-Up Networking) tethering
static CBCentralManager *bluetoothManager = nil;
static BOOL btTetherActive = NO;

// Bluetooth profile UUIDs
#define kDUNServiceUUID @"00001103-0000-1000-8000-00805F9B34FB" // DUN
#define kPANServiceUUID @"00001115-0000-1000-8000-00805F9B34FB" // PAN
#define kNAPServiceUUID @"00001116-0000-1000-8000-00805F9B34FB" // Network Access Point

// Initialize CoreBluetooth
static void initBluetoothManager() {
    if (bluetoothManager) return;
    
    dispatch_queue_t queue = dispatch_queue_create("com.tetherunlock.bluetooth", DISPATCH_QUEUE_SERIAL);
    bluetoothManager = [[CBCentralManager alloc] initWithDelegate:nil queue:queue];
    
    NSLog(@"[TetherUnlock] Bluetooth manager initialized");
}

// Enable Bluetooth DUN tethering
static BOOL enableBluetoothDUN() {
    NSLog(@"[TetherUnlock] Attempting to enable Bluetooth DUN");
    
    initBluetoothManager();
    
    if (!bluetoothManager) {
        NSLog(@"[TetherUnlock] Bluetooth not available");
        return NO;
    }
    
    // Check if Bluetooth is powered on
    if (bluetoothManager.state != CBCentralManagerStatePoweredOn) {
        NSLog(@"[TetherUnlock] Bluetooth is not powered on");
        return NO;
    }
    
    // Method 1: Use IOBluetooth for classic Bluetooth DUN
    NSArray *pairedDevices = [IOBluetoothDevice pairedDevices];
    
    for (IOBluetoothDevice *device in pairedDevices) {
        NSString *address = [device addressString];
        NSString *name = [device name];
        
        NSLog(@"[TetherUnlock] Checking device: %@ (%@)", name, address);
        
        // Check if device supports DUN
        IOBluetoothSDPServiceRecord *dunService = 
            [device getServiceRecordWithName:@"Dial-Up Networking"];
        
        if (dunService) {
            NSLog(@"[TetherUnlock] Found DUN-capable device: %@", name);
            
            // Try to connect to DUN service
            IOBluetoothRFCOMMChannel *channel = nil;
            IOReturn result = [device openRFCOMMChannelSync:&channel
                                                 withChannelID:[dunService getRFCOMMChannelID]
                                                       delegate:nil];
            
            if (result == kIOReturnSuccess) {
                NSLog(@"[TetherUnlock] Connected to DUN service on %@", name);
                btTetherActive = YES;
                return YES;
            }
        }
        
        // Check for PAN service as fallback
        IOBluetoothSDPServiceRecord *panService = 
            [device getServiceRecordWithName:@"Network Access Point"];
        
        if (panService) {
            NSLog(@"[TetherUnlock] Found PAN-capable device: %@", name);
            // PAN provides network access without DUN
            btTetherActive = YES;
            return YES;
        }
    }
    
    // Method 2: Use NetworkExtension for Bluetooth tethering
    Class neTetheringManager = NSClassFromString(@"NETetheringManager");
    
    if (neTetheringManager) {
        NSLog(@"[TetherUnlock] Using NE tethering manager");
        // NE tethering is available on iOS 14+
        // Note: This requires special entitlements
    }
    
    NSLog(@"[TetherUnlock] No DUN-capable devices found");
    return NO;
}

// Disable Bluetooth DUN
static BOOL disableBluetoothDUN() {
    NSLog(@"[TetherUnlock] Disabling Bluetooth DUN");
    
    // Disconnect any active DUN connections
    NSArray *pairedDevices = [IOBluetoothDevice pairedDevices];
    
    for (IOBluetoothDevice *device in pairedDevices) {
        if ([device isConnected]) {
            // Check if this is a DUN connection
            IOBluetoothSDPServiceRecord *dunService = 
                [device getServiceRecordWithName:@"Dial-Up Networking"];
            
            if (dunService) {
                [device closeConnection];
                NSLog(@"[TetherUnlock] Disconnected DUN from %@", [device name]);
            }
        }
    }
    
    btTetherActive = NO;
    return YES;
}

// Check Bluetooth tethering status
static BOOL isBluetoothDUNActive() {
    return btTetherActive;
}

// Get paired Bluetooth devices
static NSArray* getBluetoothDevices() {
    initBluetoothManager();
    return [IOBluetoothDevice pairedDevices];
}

// Connect to specific device for tethering
static BOOL connectBluetoothDevice(NSString *address) {
    IOBluetoothDevice *device = [IOBluetoothDevice deviceWithAddressString:address];
    
    if (!device) {
        NSLog(@"[TetherUnlock] Device not found: %@", address);
        return NO;
    }
    
    NSLog(@"[TetherUnlock] Connecting to device: %@", [device name]);
    
    // Try DUN first
    IOBluetoothSDPServiceRecord *dunService = 
        [device getServiceRecordWithName:@"Dial-Up Networking"];
    
    if (dunService) {
        IOBluetoothRFCOMMChannel *channel = nil;
        IOReturn result = [device openRFCOMMChannelSync:&channel
                                             withChannelID:[dunService getRFCOMMChannelID]
                                                   delegate:nil];
        
        if (result == kIOReturnSuccess) {
            NSLog(@"[TetherUnlock] Connected via DUN");
            btTetherActive = YES;
            return YES;
        }
    }
    
    // Fallback to PAN
    IOBluetoothSDPServiceRecord *panService = 
        [device getServiceRecordWithName:@"Network Access Point"];
    
    if (panService) {
        // PAN connection is handled differently
        [device performSelector:@selector(openConnection) withObject:nil];
        btTetherActive = YES;
        return YES;
    }
    
    return NO;
}

// Hook SpringBoard for Bluetooth events
%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    
    // Listen for Bluetooth connection changes
    [[NSNotificationCenter defaultCenter] addObserverForName:@"BluetoothDeviceConnected"
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tetherunlock.prefs"];
        BOOL btEnabled = [defaults boolForKey:kBTTetherEnabled];
        BOOL tetherEnabled = [defaults boolForKey:kTetherEnabled];
        
        if (btEnabled && tetherEnabled) {
            NSLog(@"[TetherUnlock] Bluetooth device connected");
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
                enableBluetoothDUN();
            });
        }
        
        [defaults release];
    }];
}

%end

// Export functions
BOOL tu_enableBluetoothTether() {
    return enableBluetoothDUN();
}

BOOL tu_disableBluetoothTether() {
    return disableBluetoothDUN();
}

BOOL tu_isBluetoothTetherActive() {
    return isBluetoothDUNActive();
}

NSArray* tu_getBluetoothDevices() {
    return getBluetoothDevices();
}

BOOL tu_connectBluetoothDevice(NSString *address) {
    return connectBluetoothDevice(address);
}
