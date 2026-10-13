#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface TetherUnlockUSBController : PSListController
@end

@implementation TetherUnlockUSBController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"USB" target:self];
    }
    
    return _specifiers;
}

- (void)refreshStatus {
    // Get USB tethering status
    // This would interface with the tweak's USB module
    
    [self reloadSpecifiers];
}

@end
