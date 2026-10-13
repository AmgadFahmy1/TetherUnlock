#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <notify.h>

@interface TetherUnlockRootListController : PSListController
@end

@implementation TetherUnlockRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    
    return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier*)specifier {
    NSString *path = [NSString stringWithFormat:@"/var/mobile/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:path];
    
    id value = settings[specifier.properties[@"key"]];
    
    if (value == nil) {
        value = specifier.properties[@"default"];
    }
    
    return value;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    NSString *path = [NSString stringWithFormat:@"/var/mobile/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
    
    NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithContentsOfFile:path] ?: [NSMutableDictionary dictionary];
    settings[specifier.properties[@"key"]] = value;
    [settings writeToFile:path atomically:YES];
    
    CFStringRef notificationName = (CFStringRef)specifier.properties[@"PostNotification"];
    if (notificationName) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                             notificationName,
                                             NULL,
                                             NULL,
                                             YES);
    }
    
    // Notify tweak of changes
    notify_post("com.tetherunlock/respring");
}

- (void)respring {
    notify_post("com.tetherunlock/respring");
}

- (void)openGitHub {
    NSURL *url = [NSURL URLWithString:@"https://github.com/tetherunlock"];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

@end
