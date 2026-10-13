#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <IOBluetooth/IOBluetooth.h>

@interface TetherUnlockBTController : PSListController
@end

@implementation TetherUnlockBTController

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *specifiers = [[self loadSpecifiersFromPlistName:@"Bluetooth" target:self] mutableCopy];
        
        // Add paired devices list
        NSArray *pairedDevices = [IOBluetoothDevice pairedDevices];
        
        if (pairedDevices.count > 0) {
            PSSpecifier *group = [PSSpecifier preferenceSpecifierNamed:@"Paired Devices"
                                                               target:self
                                                                  set:NULL
                                                                  get:NULL
                                                               detail:Nil
                                                                 cell:PSGroupCell
                                                                 edit:Nil];
            [specifiers addObject:group];
            
            for (IOBluetoothDevice *device in pairedDevices) {
                NSString *name = [device name] ?: @"Unknown Device";
                NSString *address = [device addressString];
                
                PSSpecifier *deviceSpec = [PSSpecifier preferenceSpecifierNamed:name
                                                                        target:self
                                                                           set:NULL
                                                                           get:@selector(isDeviceConnected:)
                                                                       detail:Nil
                                                                         cell:PSSwitchCell
                                                                         edit:Nil];
                deviceSpec.properties[@"device_address"] = address;
                [specifiers addObject:deviceSpec];
            }
        }
        
        _specifiers = specifiers;
    }
    
    return _specifiers;
}

- (NSNumber*)isDeviceConnected:(PSSpecifier*)specifier {
    NSString *address = specifier.properties[@"device_address"];
    IOBluetoothDevice *device = [IOBluetoothDevice deviceWithAddressString:address];
    
    return @([device isConnected]);
}

- (void)connectDevice:(PSSpecifier*)specifier {
    NSString *address = specifier.properties[@"device_address"];
    
    // Connect to device for tethering
    // This would call into the tweak's Bluetooth module
    
    [self reloadSpecifiers];
}

@end
