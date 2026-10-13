#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <notify.h>
#import <spawn.h>
#import <fcntl.h>
#import <sys/wait.h>

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

    const char *argv_on[] = {[toolPath fileSystemRepresentation], "on", NULL};
    const char *argv_off[] = {[toolPath fileSystemRepresentation], "off", NULL};
    const char **argv = enable ? argv_on : argv_off;

    posix_spawn_file_actions_t actions;
    posix_spawn_file_actions_init(&actions);
    posix_spawn_file_actions_addopen(&actions, 1, "/dev/null", O_WRONLY, 0);
    posix_spawn_file_actions_addopen(&actions, 2, "/dev/null", O_WRONLY, 0);

    pid_t pid = 0;
    int status = posix_spawn(&pid, [toolPath fileSystemRepresentation], &actions, NULL, (char *const *)argv, NULL);
    posix_spawn_file_actions_destroy(&actions);

    if (status == 0) {
        int exitStatus = 0;
        waitpid(pid, &exitStatus, 0);
        NSString *resultMsg = enable ? @"Native tethering ENABLED." : @"Native tethering DISABLED.";
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"TetherUnlock"
                                                                       message:resultMsg
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"TetherUnlock"
                                                                       message:[NSString stringWithFormat:@"Failed to run toggleTether (error %d)", status]
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
