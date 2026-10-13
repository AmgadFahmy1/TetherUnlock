#import "Headers/TetherHeaders.h"
#import <dlfcn.h>

static BOOL nativeTetherActive = NO;

static BOOL enableNativeTethering() {
    NSLog(@"[TetherUnlock] Native tethering via Netrb/MIS");

    void *netrb = dlopen("/System/Library/PrivateFrameworks/Netrb.framework/Netrb", RTLD_LAZY);
    void *wifi = dlopen("/System/Library/PrivateFrameworks/MobileWiFi.framework/MobileWiFi", RTLD_LAZY);
    if (!netrb || !wifi) {
        NSLog(@"[TetherUnlock] Netrb/MobileWiFi unavailable");
        return NO;
    }

    typedef void* (*NETRBClientCreateFunc)(void*, void*, int);
    typedef int (*NETRBClientSetGlobalServiceStateFunc)(void*, int);
    typedef void (*WiFiManagerClientCreateFunc)(void*, int);
    typedef void (*WiFiManagerClientSetMISDiscoveryStateFunc)(void*, bool);

    NETRBClientCreateFunc netrbCreate = (NETRBClientCreateFunc)dlsym(netrb, "NETRBClientCreate");
    NETRBClientSetGlobalServiceStateFunc netrbSet = (NETRBClientSetGlobalServiceStateFunc)dlsym(netrb, "NETRBClientSetGlobalServiceState");
    WiFiManagerClientCreateFunc wifiCreate = (WiFiManagerClientCreateFunc)dlsym(wifi, "WiFiManagerClientCreate");
    WiFiManagerClientSetMISDiscoveryStateFunc wifiSetMIS = (WiFiManagerClientSetMISDiscoveryStateFunc)dlsym(wifi, "WiFiManagerClientSetMISDiscoveryState");

    BOOL ok = NO;

    if (netrbCreate && netrbSet) {
        void *client = netrbCreate(NULL, NULL, 0);
        if (client) {
            netrbSet(client, 1);
            ok = YES;
            NSLog(@"[TetherUnlock] Netrb service ON");
        }
    }

    if (wifiCreate && wifiSetMIS) {
        void *mgr = wifiCreate(NULL, 0);
        if (mgr) {
            wifiSetMIS(mgr, true);
            ok = YES;
            NSLog(@"[TetherUnlock] MIS discovery ON");
        }
    }

    nativeTetherActive = ok;
    return ok;
}

static BOOL disableNativeTethering() {
    void *netrb = dlopen("/System/Library/PrivateFrameworks/Netrb.framework/Netrb", RTLD_LAZY);
    void *wifi = dlopen("/System/Library/PrivateFrameworks/MobileWiFi.framework/MobileWiFi", RTLD_LAZY);

    if (netrb) {
        typedef void* (*NETRBClientCreateFunc)(void*, void*, int);
        typedef int (*NETRBClientSetGlobalServiceStateFunc)(void*, int);
        NETRBClientCreateFunc netrbCreate = (NETRBClientCreateFunc)dlsym(netrb, "NETRBClientCreate");
        NETRBClientSetGlobalServiceStateFunc netrbSet = (NETRBClientSetGlobalServiceStateFunc)dlsym(netrb, "NETRBClientSetGlobalServiceState");
        if (netrbCreate && netrbSet) {
            void *client = netrbCreate(NULL, NULL, 0);
            if (client) netrbSet(client, 0);
        }
    }

    if (wifi) {
        typedef void* (*WiFiManagerClientCreateFunc)(void*, int);
        typedef void (*WiFiManagerClientSetMISDiscoveryStateFunc)(void*, bool);
        WiFiManagerClientCreateFunc wifiCreate = (WiFiManagerClientCreateFunc)dlsym(wifi, "WiFiManagerClientCreate");
        WiFiManagerClientSetMISDiscoveryStateFunc wifiSetMIS = (WiFiManagerClientSetMISDiscoveryStateFunc)dlsym(wifi, "WiFiManagerClientSetMISDiscoveryState");
        if (wifiCreate && wifiSetMIS) {
            void *mgr = wifiCreate(NULL, 0);
            if (mgr) wifiSetMIS(mgr, false);
        }
    }

    nativeTetherActive = NO;
    return YES;
}

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    NSLog(@"[TetherUnlock] Native tethering module loaded");
}
%end

BOOL tu_enableNativeTether() { return enableNativeTethering(); }
BOOL tu_disableNativeTether() { return disableNativeTethering(); }
BOOL tu_isNativeTetherActive() { return nativeTetherActive; }
