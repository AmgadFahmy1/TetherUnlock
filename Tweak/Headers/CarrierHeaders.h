#ifndef CARRIER_HEADERS_H
#define CARRIER_HEADERS_H

#import <Foundation/Foundation.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

// Private CoreTelephony APIs for carrier unlock
@interface CTCarrier (CarrierUnlock)
- (void)setSupports3G:(BOOL)supports;
- (BOOL)supports3G;
- (void)setSupports4G:(BOOL)supports;
- (BOOL)supports4G;
- (void)setSupportsLTE:(BOOL)supports;
- (BOOL)supportsLTE;
- (void)setSupports5G:(BOOL)supports;
- (BOOL)supports5G;
- (NSString*)isoCountryCode;
- (NSString*)mobileCountryCode;
- (NSString*)mobileNetworkCode;
- (BOOL)allowsVOIP;
- (BOOL)isDataPlanEnabled;
@end

// Carrier bundle manipulation
@interface CTCarrierBundle : NSObject
+ (instancetype)sharedBundle;
- (NSDictionary*)carrierBundle;
- (BOOL)isTetheringAllowed;
- (void)setTetheringAllowed:(BOOL)allowed;
- (BOOL)isPersonalHotspotAllowed;
- (void)setPersonalHotspotAllowed:(BOOL)allowed;
@end

// Network selection
@interface CTNetworkSelection : NSObject
- (NSArray*)availableNetworks;
- (BOOL)selectNetwork:(NSString*)network;
@end

// Data session
@interface CTDataSession : NSObject
- (BOOL)isActive;
- (void)start;
- (void)stop;
@end

// APN configuration
@interface CTAPNSettings : NSObject
@property (nonatomic, retain) NSString* apn;
@property (nonatomic, retain) NSString* username;
@property (nonatomic, retain) NSString* password;
@property (nonatomic, retain) NSString* proxy;
@property (nonatomic, retain) NSString* port;
@property (nonatomic, assign) NSInteger type;
- (BOOL)apply;
@end

#endif
