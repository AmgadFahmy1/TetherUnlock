#import "Headers/TetherHeaders.h"
#import <dlfcn.h>

@interface NetworkConfig : NSObject
+ (instancetype)shared;
- (BOOL)configureNetworkForTethering;
- (NSString*)getTetherInterface;
- (NSArray*)getNetworkInterfaces;
@end

@implementation NetworkConfig

+ (instancetype)shared {
    static NetworkConfig *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ shared = [[NetworkConfig alloc] init]; });
    return shared;
}

- (BOOL)configureNetworkForTethering {
    NSLog(@"[TetherUnlock] Configuring network for tethering");
    return YES;
}

- (NSString*)getTetherInterface {
    return @"en2";
}

- (NSArray*)getNetworkInterfaces {
    return @[@"en0", @"en1", @"en2", @"pdp_ip0"];
}

@end

BOOL tu_configureNetwork() {
    return [[NetworkConfig shared] configureNetworkForTethering];
}

NSArray* tu_getNetworkInterfaces() {
    return [[NetworkConfig shared] getNetworkInterfaces];
}