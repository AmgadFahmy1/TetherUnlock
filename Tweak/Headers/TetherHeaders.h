#ifndef TETHER_HEADERS_H
#define TETHER_HEADERS_H

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <notify.h>

// CoreTelephony private interfaces
@interface CTCarrier (Private)
- (BOOL)supportsCellularData;
- (NSString*)carrierName;
- (NSString*)mobileCountryCode;
- (NSString*)mobileNetworkCode;
- (BOOL)isDataPlanEnabled;
- (BOOL)isSIMLocked;
@end

@interface CTTelephonyNetworkInfo (Private)
- (CTCarrier*)subscriberCellularProvider;
- (CTCarrier*)currentCarrier;
- (NSString*)currentRadioAccessTechnology;
- (void)setAllowsVOIP:(BOOL)allow;
- (BOOL)allowsVOIP;
- (NSArray*)supportedDataRates;
@end

// Network configuration
@interface NEHotspotNetwork : NSObject
+ (void)fetchCurrentWithCompletionHandler:(void(^)(NEHotspotNetwork *currentNetwork))handler;
@end

@interface NEHotspotConfiguration : NSObject
@property (nonatomic, copy) NSString *SSID;
@property (nonatomic, copy) NSString *passphrase;
@property (nonatomic) BOOL isWEP;
- (instancetype)initWithSSID:(NSString *)SSID passphrase:(NSString *)passphrase isWEP:(BOOL)isWEP;
@end

@interface NEHotspotConfigurationManager : NSObject
+ (instancetype)sharedManager;
- (void)applyConfiguration:(NEHotspotConfiguration *)configuration
                 completion:(void(^)(NSError *error))completion;
@end

// MobileWiFi private framework
@interface WiFiManagerClient : NSObject
+ (WiFiManagerClient*)shared;
- (void)setProperty:(id)property forKey:(CFStringRef)key;
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)enabled;
- (CFArrayRef)copyDevices;
@end

@interface WiFiDeviceClient : NSObject
- (BOOL)powerOn;
- (void)setPower:(BOOL)power;
- (CFStringRef)interfaceName;
- (BOOL)associateToNetwork:(NSDictionary*)network password:(NSString*)password;
@end

// Bluetooth
@interface IOBluetoothDevice : NSObject
+ (NSArray*)pairedDevices;
- (NSString*)name;
- (NSString*)addressString;
- (BOOL)isConnected;
@end

@interface IOBluetoothRFCOMMChannel : NSObject
@end

// Preferences
@interface PSSpecifier : NSObject
+ (PSSpecifier*)preferenceSpecifierNamed:(NSString*)name
                                  target:(id)target
                                  set:(SEL)set
                                  get:(SEL)get
                                  detail:(Class)detail
                                    cell:(int)cell
                                    edit:(Class)edit;
@property (nonatomic, retain) NSDictionary* properties;
@property (nonatomic, retain) NSString* identifier;
@end

// SpringBoard hooks
@interface SpringBoard : UIApplication
- (void)applicationDidFinishLaunching:(id)application;
@end

@interface SBApplication : NSObject
- (NSString*)bundleIdentifier;
@end

// Network setup
@interface SCNetworkInterface : NSObject
@end

// Tethering state
typedef NS_ENUM(NSInteger, TetheringType) {
    TetheringTypeNone = 0,
    TetheringTypeWiFi = 1,
    TetheringTypeUSB = 2,
    TetheringTypeBluetooth = 3
};

// Notification constants
#define TetherUnlockStateChanged @"TetherUnlockStateChanged"
#define TetherUnlockConfigChanged @"TetherUnlockConfigChanged"

// UserDefaults keys
#define kTetherEnabled @"tether_enabled"
#define kWiFiTetherEnabled @"wifi_tether_enabled"
#define kUSBtTetherEnabled @"usb_tether_enabled"
#define kBTTetherEnabled @"bt_tether_enabled"
#define kWiFiSSID @"wifi_ssid"
#define kWiFiPassword @"wifi_password"
#define kCarrierUnlockEnabled @"carrier_unlock_enabled"
#define kCustomAPN @"custom_apn"

// VPN sharing keys
#define kVPNPassthroughEnabled @"vpn_passthrough_enabled"
#define kVPNShareOverTether @"vpn_share_over_tether"
#define kVPNDNSSharing @"vpn_dns_sharing"
#define kVPNFirewallBypass @"vpn_firewall_bypass"

#endif
