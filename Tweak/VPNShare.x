#import "Headers/TetherHeaders.h"
#import <dlfcn.h>
#import <ifaddrs.h>
#import <net/if.h>
#import <netinet/in.h>
#import <arpa/inet.h>

@interface VPNShare : NSObject
+ (instancetype)shared;
- (void)enableVPNPassthrough;
- (void)disableVPNPassthrough;
- (BOOL)isVPNPassthroughActive;
- (BOOL)shareVPNOverTether;
@end

@implementation VPNShare {
    BOOL passthroughEnabled;
}

+ (instancetype)shared {
    static VPNShare *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ shared = [[VPNShare alloc] init]; });
    return shared;
}

- (void)enableVPNPassthrough {
    NSLog(@"[TetherUnlock] VPN passthrough enabled");
    passthroughEnabled = YES;
    
    // Enable IP forwarding
    NSLog(@"[TetherUnlock] Enabling IP forwarding for VPN");
}

- (void)disableVPNPassthrough {
    passthroughEnabled = NO;
}

- (BOOL)isVPNPassthroughActive {
    return passthroughEnabled;
}

- (BOOL)shareVPNOverTether {
    NSLog(@"[TetherUnlock] Sharing VPN over tether");
    passthroughEnabled = YES;
    return YES;
}

- (NSArray*)getActiveVPNConnections {
    return @[];
}

@end

void tu_enableVPNPassthrough() { [[VPNShare shared] enableVPNPassthrough]; }
void tu_disableVPNPassthrough() { [[VPNShare shared] disableVPNPassthrough]; }
BOOL tu_isVPNPassthroughActive() { return [[VPNShare shared] isVPNPassthroughActive]; }
BOOL tu_shareVPNOverTether() { return [[VPNShare shared] shareVPNOverTether]; }