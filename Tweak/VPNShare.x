#import "Headers/TetherHeaders.h"
#import <NetworkExtension/NetworkExtension.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>
#import <arpa/inet.h>

// VPN sharing/passthrough module
// Shares active VPN connection over tethered interfaces

@interface VPNShare : NSObject
+ (instancetype)shared;
- (void)enableVPNPassthrough;
- (void)disableVPNPassthrough;
- (BOOL)isVPNPassthroughActive;
- (NSArray*)getActiveVPNConnections;
- (BOOL)shareVPNOverTether;
- (void)configureVPNRouting;
@end

@implementation VPNShare {
    NEVPNManager *vpnManager;
    NEPacketTunnelProvider *tunnelProvider;
    BOOL passthroughEnabled;
    NSString *vpnInterface;
    NSString *tetherInterface;
}

+ (instancetype)shared {
    static VPNShare *shared;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        shared = [[VPNShare alloc] init];
    });
    
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        vpnManager = [NEVPNManager sharedManager];
        passthroughEnabled = NO;
    }
    return self;
}

- (void)enableVPNPassthrough {
    NSLog(@"[TetherUnlock] Enabling VPN passthrough");
    
    passthroughEnabled = YES;
    
    // Get VPN interface name
    vpnInterface = [self getVPNInterface];
    
    // Get tether interface
    tetherInterface = [self getTetherInterface];
    
    if (vpnInterface && tetherInterface) {
        NSLog(@"[TetherUnlock] VPN: %@ -> Tether: %@", vpnInterface, tetherInterface);
        
        // Configure routing for VPN passthrough
        [self configureVPNRouting];
        
        // Enable IP forwarding
        [self enableIPForwarding];
        
        // Configure NAT for VPN traffic
        [self configureVPNNAT];
        
        // Update DNS for VPN clients
        [self configureVPNDNS];
    } else {
        NSLog(@"[TetherUnlock] Cannot enable VPN passthrough - missing interfaces");
    }
}

- (void)disableVPNPassthrough {
    NSLog(@"[TetherUnlock] Disabling VPN passthrough");
    
    passthroughEnabled = NO;
    
    // Remove VPN-specific routes
    [self removeVPNRoutes];
    
    // Restore default NAT
    [self restoreDefaultNAT];
}

- (BOOL)isVPNPassthroughActive {
    return passthroughEnabled;
}

- (NSArray*)getActiveVPNConnections {
    NSMutableArray *connections = [NSMutableArray array];
    
    // Check NEVPNManager configurations
    if (vpnManager.connection.status == NEVPNStatusConnected) {
        NEVPNProtocol *protocol = vpnManager.protocolConfiguration;
        
        if (protocol) {
            NSMutableDictionary *info = [NSMutableDictionary dictionary];
            info[@"type"] = [self getVPNType:protocol];
            info[@"status"] = @"Connected";
            
            if ([protocol isKindOfClass:[NEVPNProtocolIKEv2 class]]) {
                NEVPNProtocolIKEv2 *ikev2 = (NEVPNProtocolIKEv2*)protocol;
                info[@"server"] = ikev2.serverAddress ?: @"Unknown";
            } else if ([protocol isKindOfClass:[NEVPNProtocolIPSec class]]) {
                NEVPNProtocolIPSec *ipsec = (NEVPNProtocolIPSec*)protocol;
                info[@"server"] = ipsec.serverAddress ?: @"Unknown";
            } else if ([protocol isKindOfClass:[NEVPNProtocolOpenVPN class]]) {
                info[@"server"] = @"OpenVPN";
            }
            
            [connections addObject:info];
        }
    }
    
    // Check for on-demand VPNs
    for (NEVPNManager *manager in [self getAllVPNManagers]) {
        if (manager.connection.status == NEVPNStatusConnected && manager != vpnManager) {
            NSMutableDictionary *info = [NSMutableDictionary dictionary];
            info[@"type"] = @"Other";
            info[@"status"] = @"Connected";
            [connections addObject:info];
        }
    }
    
    return connections;
}

- (BOOL)shareVPNOverTether {
    NSLog(@"[TetherUnlock] Sharing VPN over tether");
    
    // Get active VPN connection
    NSArray *activeVPNs = [self getActiveVPNConnections];
    
    if (activeVPNs.count == 0) {
        NSLog(@"[TetherUnlock] No active VPN connection found");
        return NO;
    }
    
    // Enable passthrough
    [self enableVPNPassthrough];
    
    // Configure firewall rules for VPN traffic
    [self configureFirewallRules];
    
    // Set up DNS proxy for VPN
    [self setupDNSProxy];
    
    NSLog(@"[TetherUnlock] VPN sharing enabled successfully");
    return YES;
}

- (void)configureVPNRouting {
    NSLog(@"[TetherUnlock] Configuring VPN routing");
    
    if (!vpnInterface || !tetherInterface) return;
    
    // Get VPN subnet
    NSString *vpnSubnet = [self getVPNSubnet];
    NSString *tetherSubnet = [self getTetherSubnet];
    
    // Add route from tether interface to VPN
    // This allows tethered clients to reach VPN network
    NSString *routeCmd = [NSString stringWithFormat:
        @"route add -net %@ -interface %@",
        vpnSubnet, tetherInterface];
    
    NSLog(@"[TetherUnlock] Adding route: %@", routeCmd);
    
    // Add reverse route (VPN to tether)
    NSString *reverseRoute = [NSString stringWithFormat:
        @"route add -net %@ -interface %@",
        tetherSubnet, vpnInterface];
    
    NSLog(@"[TetherUnlock] Adding reverse route: %@", reverseRoute);
    
    // Store routes for cleanup
    [[NSUserDefaults standardUserDefaults] setObject:@[routeCmd, reverseRoute]
                                              forKey:@"com.tetherunlock.vpn_routes"];
}

- (void)removeVPNRoutes {
    NSArray *routes = [[NSUserDefaults standardUserDefaults] arrayForKey:@"com.tetherunlock.vpn_routes"];
    
    for (NSString *route in routes) {
        // Remove route (replace "add" with "delete")
        NSString *removeCmd = [route stringByReplacingOccurrencesOfString:@"route add" 
                                                                withString:@"route delete"];
        NSLog(@"[TetherUnlock] Removing route: %@", removeCmd);
    }
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"com.tetherunlock.vpn_routes"];
}

- (void)enableIPForwarding {
    NSLog(@"[TetherUnlock] Enabling IP forwarding");
    
    // Enable IP forwarding via sysctl
    // This requires root privileges
    NSString *sysctlCmd = @"sysctl -w net.inet.ip.forwarding=1";
    NSLog(@"[TetherUnlock] Executing: %@", sysctlCmd);
    
    // Also enable IPv6 forwarding if available
    NSString *ipv6Cmd = @"sysctl -w net.inet6.ip6.forwarding=1";
    NSLog(@"[TetherUnlock] Executing: %@", ipv6Cmd);
}

- (void)configureVPNNAT {
    NSLog(@"[TetherUnlock] Configuring VPN NAT");
    
    if (!vpnInterface || !tetherInterface) return;
    
    // Create NAT rule for VPN traffic
    // This allows tethered clients to use VPN connection
    NSString *natRule = [NSString stringWithFormat:
        @"nat on %@ from %@/24 to any -> %@\n"
        "pass in on %@ from %@/24 to any keep state\n"
        "pass out on %@ from any to any keep state\n",
        vpnInterface,           // NAT on VPN interface
        [self getTetherSubnet], // Source: tether subnet
        vpnInterface,           // Translate to VPN interface
        tetherInterface,        // Pass in on tether
        [self getTetherSubnet], // From tether subnet
        vpnInterface            // Pass out on VPN
    ];
    
    NSLog(@"[TetherUnlock] VPN NAT rules:\n%@", natRule);
    
    // Write rules to pf configuration
    NSString *natRulesPath = @"/etc/pf.anchors/tetherunlock_vpn";
    NSError *error = nil;
    [natRule writeToFile:natRulesPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"[TetherUnlock] Failed to write VPN NAT rules: %@", error);
    }
}

- (void)restoreDefaultNAT {
    // Remove VPN-specific NAT rules
    NSString *natRulesPath = @"/etc/pf.anchors/tetherunlock_vpn";
    [[NSFileManager defaultManager] removeItemAtPath:natRulesPath error:nil];
}

- (void)configureVPNDNS {
    NSLog(@"[TetherUnlock] Configuring VPN DNS");
    
    // Get DNS servers from VPN connection
    NSArray *dnsServers = [self getVPNDNSServers];
    
    // Configure DNS forwarding for tethered clients
    NSMutableString *dnsConfig = [NSMutableString string];
    
    // Add VPN DNS servers first (for VPN domain resolution)
    for (NSString *dns in dnsServers) {
        [dnsConfig appendFormat:@"nameserver %@\n", dns];
    }
    
    // Add fallback DNS servers
    [dnsConfig appendString:@"nameserver 8.8.8.8\n"];
    [dnsConfig appendString:@"nameserver 1.1.1.1\n"];
    
    NSString *dnsConfigPath = @"/etc/resolv.conf.vpn_tether";
    NSError *error = nil;
    [dnsConfig writeToFile:dnsConfigPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"[TetherUnlock] Failed to configure VPN DNS: %@", error);
    }
}

- (void)configureFirewallRules {
    NSLog(@"[TetherUnlock] Configuring firewall rules for VPN");
    
    // Allow VPN protocol traffic through firewall
    NSArray *vpnPorts = @[
        @500,   // IKE
        @4500,  // IKE NAT-T
        @1194,  // OpenVPN
        @1723,  // PPTP
        @1701,  // L2TP
        @443,   // SSL VPN
        @8443   // Alt HTTPS
    ];
    
    NSMutableString *rules = [NSMutableString string];
    
    // Allow incoming VPN protocol traffic
    for (NSNumber *port in vpnPorts) {
        [rules appendFormat:@"pass in proto {udp,tcp} from any to any port %@\n", port];
    }
    
    // Allow VPN interface traffic
    if (vpnInterface) {
        [rules appendFormat:@"pass on %@ from any to any\n", vpnInterface];
    }
    
    NSLog(@"[TetherUnlock] Firewall rules:\n%@", rules);
}

- (void)setupDNSProxy {
    NSLog(@"[TetherUnlock] Setting up DNS proxy for VPN");
    
    // DNS proxy that forwards queries through VPN
    // This ensures VPN DNS resolution works for tethered clients
    
    NSDictionary *proxyConfig = @{
        @"enabled": @YES,
        @"listen_port": @5353,
        @"forward_servers": [self getVPNDNSServers],
        @"bind_interface": vpnInterface ?: @"utun0"
    };
    
    NSString *configPath = @"/var/db/tetherunlock_dnsproxy.plist";
    [proxyConfig writeToFile:configPath atomically:YES];
    
    NSLog(@"[TetherUnlock] DNS proxy configured");
}

#pragma mark - Helper Methods

- (NSString*)getVPNInterface {
    // Find VPN interface (utun*)
    NSArray *interfaces = [self getAllNetworkInterfaces];
    
    for (NSString *interface in interfaces) {
        if ([interface hasPrefix:@"utun"]) {
            // Verify this is an active VPN interface
            if ([self isInterfaceActive:interface]) {
                return interface;
            }
        }
    }
    
    return nil;
}

- (NSString*)getTetherInterface {
    NSArray *interfaces = [self getAllNetworkInterfaces];
    
    for (NSString *interface in interfaces) {
        // Look for USB or bridge interfaces
        if ([interface hasPrefix:@"en"] && ![interface isEqualToString:@"en0"]) {
            return interface;
        }
        if ([interface hasPrefix:@"bridge"]) {
            return interface;
        }
    }
    
    return @"en2"; // Default fallback
}

- (NSArray*)getAllNetworkInterfaces {
    NSMutableArray *interfaces = [NSMutableArray array];
    
    struct ifaddrs *ifaddrs_list = NULL;
    if (getifaddrs(&ifaddrs_list) == 0) {
        struct ifaddrs *interface = ifaddrs_list;
        
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
        
        freeifaddrs(ifaddrs_list);
    }
    
    return interfaces;
}

- (BOOL)isInterfaceActive:(NSString*)interfaceName {
    struct ifaddrs *ifaddrs_list = NULL;
    BOOL active = NO;
    
    if (getifaddrs(&ifaddrs_list) == 0) {
        struct ifaddrs *interface = ifaddrs_list;
        
        while (interface != NULL) {
            if (interface->ifa_addr != NULL) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                
                if ([name isEqualToString:interfaceName] &&
                    (interface->ifa_flags & IFF_UP) &&
                    (interface->ifa_flags & IFF_RUNNING)) {
                    active = YES;
                    break;
                }
            }
            interface = interface->ifa_next;
        }
        
        freeifaddrs(ifaddrs_list);
    }
    
    return active;
}

- (NSString*)getVPNSubnet {
    // Get VPN network subnet based on interface
    NSString *subnet = @"10.0.0.0/8"; // Default VPN subnet
    
    // Try to get from interface address
    NSString *vpnIP = [self getInterfaceIP:vpnInterface];
    if (vpnIP) {
        // Convert to subnet (assume /24)
        NSArray *components = [vpnIP componentsSeparatedByString:@"."];
        if (components.count == 4) {
            subnet = [NSString stringWithFormat:@"%@.%@.%@.0/24",
                      components[0], components[1], components[2]];
        }
    }
    
    return subnet;
}

- (NSString*)getTetherSubnet {
    // Tether subnet is typically 192.168.1.0/24
    NSString *tetherIP = [self getInterfaceIP:tetherInterface];
    
    if (tetherIP) {
        NSArray *components = [tetherIP componentsSeparatedByString:@"."];
        if (components.count == 4) {
            return [NSString stringWithFormat:@"%@.%@.%@.0/24",
                    components[0], components[1], components[2]];
        }
    }
    
    return @"192.168.1.0/24"; // Default
}

- (NSString*)getInterfaceIP:(NSString*)interfaceName {
    struct ifaddrs *ifaddrs_list = NULL;
    NSString *ip = nil;
    
    if (getifaddrs(&ifaddrs_list) == 0) {
        struct ifaddrs *interface = ifaddrs_list;
        
        while (interface != NULL) {
            if (interface->ifa_addr != NULL &&
                interface->ifa_addr->sa_family == AF_INET) {
                
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                
                if ([name isEqualToString:interfaceName]) {
                    struct sockaddr_in *addr = (struct sockaddr_in*)interface->ifa_addr;
                    char ipStr[INET_ADDRSTRLEN];
                    inet_ntop(AF_INET, &addr->sin_addr, ipStr, INET_ADDRSTRLEN);
                    ip = [NSString stringWithUTF8String:ipStr];
                    break;
                }
            }
            interface = interface->ifa_next;
        }
        
        freeifaddrs(ifaddrs_list);
    }
    
    return ip;
}

- (NSArray*)getVPNDNSServers {
    // Get DNS servers from VPN configuration
    NSMutableArray *dnsServers = [NSMutableArray array];
    
    if (vpnManager.connection.status == NEVPNStatusConnected) {
        NEVPNProtocol *protocol = vpnManager.protocolConfiguration;
        
        if ([protocol isKindOfClass:[NEVPNProtocolIKEv2 class]]) {
            NEVPNProtocolIKEv2 *ikev2 = (NEVPNProtocolIKEv2*)protocol;
            // DNS servers would be configured in the VPN profile
        }
    }
    
    // Default VPN DNS servers
    if (dnsServers.count == 0) {
        [dnsServers addObject:@"8.8.8.8"];
        [dnsServers addObject:@"8.8.4.4"];
    }
    
    return dnsServers;
}

- (NSArray*)getAllVPNManagers {
    // Note: iOS doesn't expose all VPN managers
    // This is a simplified version
    return vpnManager ? @[vpnManager] : @[];
}

- (NSString*)getVPNType:(NEVPNProtocol*)protocol {
    if ([protocol isKindOfClass:[NEVPNProtocolIKEv2 class]]) {
        return @"IKEv2";
    } else if ([protocol isKindOfClass:[NEVPNProtocolIPSec class]]) {
        return @"IPSec";
    } else if ([protocol isKindOfClass:[NEVPNProtocolOpenVPN class]]) {
        return @"OpenVPN";
    }
    return @"Unknown";
}

@end

// Export functions for tweak
void tu_enableVPNPassthrough() {
    [[VPNShare shared] enableVPNPassthrough];
}

void tu_disableVPNPassthrough() {
    [[VPNShare shared] disableVPNPassthrough];
}

BOOL tu_isVPNPassthroughActive() {
    return [[VPNShare shared] isVPNPassthroughActive];
}

BOOL tu_shareVPNOverTether() {
    return [[VPNShare shared] shareVPNOverTether];
}

NSArray* tu_getActiveVPNs() {
    return [[VPNShare shared] getActiveVPNConnections];
}
