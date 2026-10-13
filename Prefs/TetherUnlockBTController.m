#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface TetherUnlockBTController : PSListController
@end

@implementation TetherUnlockBTController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"Bluetooth" target:self] mutableCopy];
    }
    return _specifiers;
}

@end