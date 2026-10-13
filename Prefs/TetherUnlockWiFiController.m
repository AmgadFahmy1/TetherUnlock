#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface TetherUnlockWiFiController : PSListController
@end

@implementation TetherUnlockWiFiController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"WiFi" target:self];
    }
    
    return _specifiers;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Update UI based on current state
    [self reloadSpecifiers];
}

- (void)generateRandomPassword {
    // Generate random WPA2 password
    NSString *charset = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *password = [NSMutableString string];
    
    for (int i = 0; i < 12; i++) {
        uint32_t random = arc4random_uniform((uint32_t)charset.length);
        unichar character = [charset characterAtIndex:random];
        [password appendFormat:@"%C", character];
    }
    
    // Update preference
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tetherunlock.prefs"];
    [defaults setObject:password forKey:@"wifi_password"];
    [defaults synchronize];
    [defaults release];
    
    [self reloadSpecifiers];
}

@end
