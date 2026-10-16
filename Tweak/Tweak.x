#import "Headers/TetherHeaders.h"
#import <notify.h>

extern BOOL tu_enableNativeTether(void);
extern BOOL tu_disableNativeTether(void);
extern BOOL tu_isNativeTetherActive(void);

static BOOL tetherEnabled = NO;

static void tlog(NSString *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    NSString *msg = [[[NSString alloc] initWithFormat:fmt arguments:ap] autorelease];
    va_end(ap);
    NSLog(@"[TetherUnlock] %@", msg);
    NSString *line = [NSString stringWithFormat:@"%@ %@\n", [NSDate date], msg];
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:@"/var/tmp/tetherunlock.log"];
    if (!fh) {
        [[NSFileManager defaultManager] createFileAtPath:@"/var/tmp/tetherunlock.log" contents:nil attributes:nil];
        fh = [NSFileHandle fileHandleForWritingAtPath:@"/var/tmp/tetherunlock.log"];
    }
    if (fh) {
        [fh seekToEndOfFile];
        [fh writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
        [fh closeFile];
    }
}

static BOOL readBoolPref(CFStringRef key) {
    CFPropertyListRef v = CFPreferencesCopyAppValue(key, CFSTR("com.tetherunlock.prefs"));
    BOOL b = NO;
    if (v) {
        b = [(id)v boolValue];
        CFRelease(v);
    }
    return b;
}

static void loadPreferences(void) {
    tetherEnabled = readBoolPref(CFSTR("tether_enabled"));
}

static void applyState(void) {
    if (tetherEnabled) {
        BOOL ok = tu_enableNativeTether();
        tlog(@"applyState: enable native tether -> %@", ok ? @"OK" : @"FAILED");
    } else {
        tu_disableNativeTether();
        tlog(@"applyState: disable native tether");
    }
}

static void handleCommand(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    tlog(@"Command received: %@", (id)name);
    loadPreferences();
    applyState();
}

%ctor {
    @autoreleasepool {
        NSString *bid = [NSBundle mainBundle].bundleIdentifier;
        if (![bid isEqualToString:@"com.apple.springboard"]) {
            return;
        }
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        NULL,
                                        handleCommand,
                                        CFSTR("com.tetherunlock.command"),
                                        NULL,
                                        CFNotificationSuspensionBehaviorDeliverImmediately);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        NULL,
                                        handleCommand,
                                        CFSTR("com.tetherunlock/respring"),
                                        NULL,
                                        CFNotificationSuspensionBehaviorDeliverImmediately);
        loadPreferences();
        tlog(@"Tweak loaded (enabled=%d)", tetherEnabled);
        if (tetherEnabled) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                applyState();
            });
        }
    }
}
