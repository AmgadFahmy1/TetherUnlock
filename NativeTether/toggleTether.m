#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <dlfcn.h>
#import <stdio.h>
#import <string.h>

#define NETRB_SERVICE_STATE_OFF 0
#define NETRB_SERVICE_STATE_ON  1

typedef void *NETRBClientRef;
typedef void *WiFiManagerClientRef;

typedef NETRBClientRef (*NETRBClientCreateFunc)(CFAllocatorRef, void *, int);
typedef void (*NETRBClientDestroyFunc)(NETRBClientRef);
typedef int (*NETRBClientGetGlobalServiceStateFunc)(NETRBClientRef, int *, int *);
typedef int (*NETRBClientSetGlobalServiceStateFunc)(NETRBClientRef, int);

typedef WiFiManagerClientRef (*WiFiManagerClientCreateFunc)(CFAllocatorRef, int);
typedef void (*WiFiManagerClientSetMISDiscoveryStateFunc)(WiFiManagerClientRef, bool);
typedef bool (*WiFiManagerClientGetMISDiscoveryStateFunc)(WiFiManagerClientRef);

static void setTethering(BOOL enable) {
    void *netrbHandle = dlopen("/System/Library/PrivateFrameworks/Netrb.framework/Netrb", RTLD_LAZY);
    if (netrbHandle) {
        NETRBClientCreateFunc create = (NETRBClientCreateFunc)dlsym(netrbHandle, "NETRBClientCreate");
        NETRBClientDestroyFunc destroy = (NETRBClientDestroyFunc)dlsym(netrbHandle, "NETRBClientDestroy");
        NETRBClientGetGlobalServiceStateFunc get = (NETRBClientGetGlobalServiceStateFunc)dlsym(netrbHandle, "NETRBClientGetGlobalServiceState");
        NETRBClientSetGlobalServiceStateFunc set = (NETRBClientSetGlobalServiceStateFunc)dlsym(netrbHandle, "NETRBClientSetGlobalServiceState");

        if (create && set) {
            NETRBClientRef client = create(kCFAllocatorDefault, NULL, 0);
            if (client) {
                int state = 0;
                int unk = 0;
                if (get) {
                    get(client, &state, &unk);
                    printf("[toggleTether] netrb current state: %d\n", state);
                }
                int newState = enable ? NETRB_SERVICE_STATE_ON : NETRB_SERVICE_STATE_OFF;
                int rc = set(client, newState);
                printf("[toggleTether] netrb set state %d -> rc=%d\n", newState, rc);
                if (destroy) destroy(client);
            } else {
                printf("[toggleTether] NETRBClientCreate failed\n");
            }
        } else {
            printf("[toggleTether] Netrb symbols missing\n");
        }
    } else {
        printf("[toggleTether] dlopen Netrb failed: %s\n", dlerror());
    }

    void *wifiHandle = dlopen("/System/Library/PrivateFrameworks/MobileWiFi.framework/MobileWiFi", RTLD_LAZY);
    if (wifiHandle) {
        WiFiManagerClientCreateFunc wifiCreate = (WiFiManagerClientCreateFunc)dlsym(wifiHandle, "WiFiManagerClientCreate");
        WiFiManagerClientSetMISDiscoveryStateFunc setMIS = (WiFiManagerClientSetMISDiscoveryStateFunc)dlsym(wifiHandle, "WiFiManagerClientSetMISDiscoveryState");
        WiFiManagerClientGetMISDiscoveryStateFunc getMIS = (WiFiManagerClientGetMISDiscoveryStateFunc)dlsym(wifiHandle, "WiFiManagerClientGetMISDiscoveryState");

        if (wifiCreate && setMIS) {
            WiFiManagerClientRef mgr = wifiCreate(kCFAllocatorDefault, 0);
            if (mgr) {
                if (getMIS) {
                    printf("[toggleTether] MIS discovery current: %d\n", getMIS(mgr) ? 1 : 0);
                }
                setMIS(mgr, enable ? true : false);
                printf("[toggleTether] MIS discovery set to %d\n", enable ? 1 : 0);
            } else {
                printf("[toggleTether] WiFiManagerClientCreate failed\n");
            }
        } else {
            printf("[toggleTether] MobileWiFi symbols missing\n");
        }
    } else {
        printf("[toggleTether] dlopen MobileWiFi failed: %s\n", dlerror());
    }
}

int main(int argc, char *argv[]) {
    @autoreleasepool {
        BOOL enable = YES;
        if (argc > 1) {
            if (strcmp(argv[1], "off") == 0 || strcmp(argv[1], "0") == 0 || strcmp(argv[1], "disable") == 0) {
                enable = NO;
            } else if (strcmp(argv[1], "on") == 0 || strcmp(argv[1], "1") == 0 || strcmp(argv[1], "enable") == 0) {
                enable = YES;
            } else {
                printf("Usage: toggleTether [on|off]\n");
                return 1;
            }
        }
        printf("[toggleTether] %s native tethering (Netrb + MIS)\n", enable ? "Enabling" : "Disabling");
        setTethering(enable);
        printf("[toggleTether] done\n");
    }
    return 0;
}
