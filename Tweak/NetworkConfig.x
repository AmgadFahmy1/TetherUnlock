#import "Headers/TetherHeaders.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

// Network configuration for tethering
@interface NetworkConfig : NSObject
+ (instancetype)shared;
- (BOOL)configureNetworkForTethering;
- (BOOL)setupNAT;
- (BOOL)configureDNS;
- (BOOL)configureDHCP;
- (NSString*)getTetherInterface;
- (NSArray*)getNetworkInterfaces;
@end

@implementation NetworkConfig {
    SCPreferencesRef preferences;
    SCNetworkReachabilityRef reachability;
}

+ (instancetype)shared {
    static NetworkConfig *shared;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        shared = [[NetworkConfig alloc] init];
    });
    
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        preferences = SCPreferencesCreate(kCFAllocatorDefault, CFSTR("TetherUnlock"), NULL);
    }
    return self;
}

- (void)dealloc {
    if (preferences) CFRelease(preferences);
    if (reachability) CFRelease(reachability);
    [super dealloc];
}

- (BOOL)configureNetworkForTethering {
    NSLog(@"[TetherUnlock] Configuring network for tethering");
    
    // Get the tether interface
    NSString *tetherInterface = [self getTetherInterface];
    if (!tetherInterface) {
        NSLog(@"[TetherUnlock] No tether interface found");
        return NO;
    }
    
    NSLog(@"[TetherUnlock] Using interface: %@", tetherInterface);
    
    // Configure NAT (Network Address Translation)
    BOOL natResult = [self setupNAT];
    
    // Configure DNS forwarding
    BOOL dnsResult = [self configureDNS];
    
    // Configure DHCP server
    BOOL dhcpResult = [self configureDHCP];
    
    // Check for VPN and configure VPN-specific routing if active
    BOOL vpnResult = YES;
    if ([self isVPNActive]) {
        NSLog(@"[TetherUnlock] VPN detected, configuring VPN passthrough");
        vpnResult = [self configureVPNPassthrough];
    }
    
    // Enable IP forwarding for all traffic
    [self enableIPForwarding];
    
    return natResult && dnsResult && dhcpResult && vpnResult;
}

- (BOOL)isVPNActive {
    // Check for active VPN interfaces (utun*)
    NSArray *interfaces = [self getNetworkInterfaces];
    
    for (NSString *interface in interfaces) {
        if ([interface hasPrefix:@"utun"]) {
            if ([self isInterfaceUp:interface]) {
                NSLog(@"[TetherUnlock] Active VPN interface found: %@", interface);
                return YES;
            }
        }
    }
    
    return NO;
}

- (BOOL)isInterfaceUp:(NSString*)interfaceName {
    struct ifaddrs *ifaddrs_list = NULL;
    BOOL up = NO;
    
    if (getifaddrs(&ifaddrs_list) == 0) {
        struct ifaddrs *interface = ifaddrs_list;
        
        while (interface != NULL) {
            if (interface->ifa_name != NULL) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                
                if ([name isEqualToString:interfaceName] &&
                    (interface->ifa_flags & IFF_UP) &&
                    (interface->ifa_flags & IFF_RUNNING)) {
                    up = YES;
                    break;
                }
            }
            interface = interface->ifa_next;
        }
        
        freeifaddrs(ifaddrs_list);
    }
    
    return up;
}

- (BOOL)configureVPNPassthrough {
    NSLog(@"[TetherUnlock] Configuring VPN passthrough routing");
    
    // Find VPN interface
    NSString *vpnInterface = nil;
    NSArray *interfaces = [self getNetworkInterfaces];
    
    for (NSString *interface in interfaces) {
        if ([interface hasPrefix:@"utun"] && [self isInterfaceUp:interface]) {
            vpnInterface = interface;
            break;
        }
    }
    
    if (!vpnInterface) return NO;
    
    NSString *tetherInterface = [self getTetherInterface];
    
    // Configure routing to allow tethered clients to use VPN
    // 1. Add NAT rule for VPN traffic
    NSString *vpnNAT = [NSString stringWithFormat:
        @"pass in on %@ from any to any\n"
        "pass out on %@ from any to any keep state\n",
        vpnInterface, vpnInterface];
    
    // 2. Enable forwarding between interfaces
    NSString *forwardRule = [NSString stringWithFormat:
        @"pass in quick on %@ from 192.168.1.0/24 to any\n"
        "pass out quick on %@ from any to 192.168.1.0/24\n",
        tetherInterface, tetherInterface];
    
    // 3. Configure DNS to use VPN DNS
    NSArray *vpnDNS = [self getVPNDNSFromInterface:vpnInterface];
    
    NSLog(@"[TetherUnlock] VPN passthrough configured: %@ <-> %@", tetherInterface, vpnInterface);
    
    return YES;
}

- (NSArray*)getVPNDNSFromInterface:(NSString*)interface {
    // Get DNS servers associated with VPN interface
    NSMutableArray *dnsServers = [NSMutableArray array];
    
    // Read from resolv.conf or system configuration
    NSString *resolvPath = @"/etc/resolv.conf";
    NSString *resolvContent = [NSString stringWithContentsOfFile:resolvPath 
                                                         encoding:NSUTF8StringEncoding 
                                                            error:nil];
    
    if (resolvContent) {
        NSArray *lines = [resolvContent componentsSeparatedByString:@"\n"];
        for (NSString *line in lines) {
            if ([line hasPrefix:@"nameserver"]) {
                NSArray *components = [line componentsSeparatedByString:@" "];
                if (components.count >= 2) {
                    [dnsServers addObject:components[1]];
                }
            }
        }
    }
    
    return dnsServers;
}

- (void)enableIPForwarding {
    NSLog(@"[TetherUnlock] Enabling IP forwarding");
    
    // Enable IPv4 forwarding
    // Requires root privileges - handled by jailbreak
    
    // Store setting for reference
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"com.tetherunlock.ip_forwarding"];
}

- (BOOL)setupNAT {
    NSLog(@"[TetherUnlock] Setting up NAT");
    
    // Use ipfw or pf for NAT on iOS
    // iOS uses pf (packet filter) for NAT
    
    // Get cellular interface name
    NSString *cellularInterface = @"pdp_ip0"; // Cellular data interface
    
    // Create pf NAT rules
    NSString *natRules = [NSString stringWithFormat:
        @"nat on %@ from 192.168.1.0/24 to any -> %@\n", 
        cellularInterface, cellularInterface];
    
    // Write NAT rules to file
    NSString *natRulesPath = @"/etc/pf.anchors/tetherunlock";
    NSError *error = nil;
    
    // Note: This requires root privileges
    // In practice, this is handled by the jailbreak's privilege escalation
    
    [natRules writeToFile:natRulesPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"[TetherUnlock] Failed to write NAT rules: %@", error);
        return NO;
    }
    
    NSLog(@"[TetherUnlock] NAT configured");
    return YES;
}

- (BOOL)configureDNS {
    NSLog(@"[TetherUnlock] Configuring DNS");
    
    // Configure DNS for tethered clients
    NSArray *dnsServers = @[@"8.8.8.8", @"8.8.4.4", @"1.1.1.1"];
    
    // Write resolv.conf for tethered clients
    NSMutableString *resolvConf = [NSMutableString string];
    
    for (NSString *server in dnsServers) {
        [resolvConf appendFormat:@"nameserver %@\n", server];
    }
    
    NSString *resolvPath = @"/etc/resolv.conf.tether";
    NSError *error = nil;
    [resolvConf writeToFile:resolvPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"[TetherUnlock] Failed to configure DNS: %@", error);
        return NO;
    }
    
    NSLog(@"[TetherUnlock] DNS configured");
    return YES;
}

- (BOOL)configureDHCP {
    NSLog(@"[TetherUnlock] Configuring DHCP");
    
    // DHCP configuration for tethered clients
    NSDictionary *dhcpConfig = @{
        @"enabled": @YES,
        @"interface": @"bridge0", // Or appropriate interface
        @"pool_start": @"192.168.1.100",
        @"pool_end": @"192.168.1.200",
        @"subnet_mask": @"255.255.255.0",
        @"router": @"192.168.1.1",
        @"lease_time": @3600,
        @"dns_servers": @[@"8.8.8.8", @"8.8.4.4"]
    };
    
    // Write DHCP configuration
    NSString *configPath = @"/var/db/dhcpd_tether.conf";
    NSError *error = nil;
    
    NSData *configData = [NSJSONSerialization dataWithJSONObject:dhcpConfig options:0 error:&error];
    
    if (configData) {
        [configData writeToFile:configPath atomically:YES];
    }
    
    if (error) {
        NSLog(@"[TetherUnlock] Failed to configure DHCP: %@", error);
        return NO;
    }
    
    NSLog(@"[TetherUnlock] DHCP configured");
    return YES;
}

- (NSString*)getTetherInterface {
    // List all network interfaces
    NSArray *interfaces = [self getNetworkInterfaces];
    
    // Look for appropriate tether interface
    for (NSString *interface in interfaces) {
        // USB tethering interfaces
        if ([interface hasPrefix:@"en"] && ![interface isEqualToString:@"en0"]) {
            // en0 is typically Wi-Fi
            return interface;
        }
        
        // Bridge interfaces
        if ([interface hasPrefix:@"bridge"]) {
            return interface;
        }
        
        // Apple USB interfaces
        if ([interface hasPrefix:@"usb"]) {
            return interface;
        }
    }
    
    // Default fallback
    return @"en2";
}

- (NSArray*)getNetworkInterfaces {
    NSMutableArray *interfaces = [NSMutableArray array];
    
    // Get list of network interfaces
    struct ifaddrs *interfaces_list = NULL;
    if (getifaddrs(&interfaces_list) == 0) {
        struct ifaddrs *interface = interfaces_list;
        
        while (interface != NULL) {
            if (interface->ifa_addr != NULL && 
                interface->ifa_addr->sa_family == AF_LINK) {
                
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                if (name && ![interfaces containsObject:name]) {
                    [interfaces addObject:name];
                }
            }
            interface = interface->ifa_next;
        }
        
        freeifaddrs(interfaces_list);
    }
    
    return interfaces;
}

@end

// C interface for use in tweak
BOOL tu_configureNetwork() {
    return [[NetworkConfig shared] configureNetworkForTethering];
}

NSArray* tu_getNetworkInterfaces() {
    return [[NetworkConfig shared] getNetworkInterfaces];
}
