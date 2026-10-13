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

- (void)runToggleTether:(BOOL)enable {
    NSString *toolPath = nil;
    NSArray *candidates = @[@"/var/jb/usr/bin/toggleTether", @"/usr/bin/toggleTether"];
    for (NSString *path in candidates) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            toolPath = path;
            break;
        }
    }

    if (!toolPath) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"TetherUnlock"
                                                                       message:@"toggleTether tool not found. Reinstall the package."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    NSTask *task = [[NSTask alloc] init];
    task.launchPath = toolPath;
    task.arguments = enable ? @[@"on"] : @[@"off"];
    task.standardOutput = [NSPipe pipe];
    task.standardError = [NSPipe pipe];

    @try {
        [task launch];
        [task waitUntilExit];

        NSFileHandle *outHandle = [[task standardOutput] fileHandleForReading];
        NSData *outData = [outHandle readDataToEndOfFile];
        NSString *output = [[NSString alloc] initWithData:outData encoding:NSUTF8StringEncoding] ?: @"";

        NSString *resultMsg = enable ? @"Native tethering ENABLED." : @"Native tethering DISABLED.";
        if (output.length > 0) {
            resultMsg = [resultMsg stringByAppendingFormat:@"\n\n%@", output];
        }

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"TetherUnlock"
                                                                       message:resultMsg
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    } @catch (NSException *exception) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"TetherUnlock"
                                                                       message:[NSString stringWithFormat:@"Failed to run toggleTether: %@", exception.reason]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)enableNativeTether {
    [self runToggleTether:YES];
}

- (void)disableNativeTether {
    [self runToggleTether:NO];
}

- (void)openGitHub {
    NSURL *url = [NSURL URLWithString:@"https://github.com/tetherunlock"];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

@end
