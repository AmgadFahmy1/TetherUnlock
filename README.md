# TetherUnlock

Complete tethering unlock solution for iPadOS 15.0-15.4.1 with Xina15 rootless jailbreak.

## Features

- **Wi-Fi Hotspot**: Create Wi-Fi access point with WPA2/WPA3 security
- **USB Tethering**: Share internet via USB/Lightning cable
- **Bluetooth DUN**: Bluetooth Dial-Up Networking tethering
- **Carrier Unlock**: Bypass carrier tethering restrictions
- **VPN Sharing**: Share active VPN connections (IKEv2, IPSec, OpenVPN) with tethered devices

## Requirements

- iPadOS 15.0 - 15.4.1
- Xina15 rootless jailbreak (or compatible)
- A12+ chip (iPad Air 3rd gen, iPad mini 5th gen, iPad 8th gen+, all iPad Pro)
- Active cellular data plan

## Quick Build

### Option 1: Docker (Recommended - Works anywhere)

```bash
# Build .deb using Docker
docker build -t tetherunlock .
docker run -v $(pwd):/build tetherunlock

# Or using docker-compose
docker-compose run tetherunlock-builder
```

### Option 2: Native Build (macOS/Linux)

```bash
# Build both .deb and .ipa
chmod +x build_all.sh
./build_all.sh

# Build only .deb
./build_all.sh --deb-only

# Build only .ipa (requires macOS + Xcode)
./build_all.sh --ipa-only
```

### Option 3: Manual Build

**For .deb (Theos):**
```bash
export THEOS=~/theos
make package FINALPACKAGE=1
```

**For .ipa (Xcode):**
```bash
cd companion
xcodebuild -project TetherUnlockApp.xcodeproj \
           -scheme TetherUnlockApp \
           -configuration Release \
           -destination 'generic/platform=iOS' \
           archive
```

## Output Files

| File | Location | Description |
|------|----------|-------------|
| `.deb` | `packages/` | Jailbreak package for Sileo/Zebra |
| `.ipa` | `companion/export/` | Sideloading app for AltStore/SideStore/TrollStore |

## Installation

### .deb Package (Jailbroken Devices)

1. Copy the `.deb` file to your iPad
2. Open in Sileo, Zebra, or Filza
3. Install and respring

**Or via SSH:**
```bash
scp packages/*.deb root@<iPad-IP>:/tmp/
ssh root@<iPad-IP>
dpkg -i /tmp/com.tetherunlock.tweak_*.deb
sbreload
```

### .ipa Package (Sideloading)

| Method | Instructions |
|--------|--------------|
| **AltStore** | Install AltStore → Transfer .ipa → Open in AltStore |
| **SideStore** | Install SideStore → Import .ipa |
| **TrollStore** | Open .ipa in Files → Share to TrollStore |
| **Sideloadly** | Connect iPad → Drag .ipa → Click Start |

## VPN Sharing

TetherUnlock can share your active VPN connection with all tethered devices:

### Supported VPN Protocols
- IKEv2 (built-in iOS VPN)
- IPSec/L2TP
- OpenVPN
- Any NEVPN-compatible protocol

### How It Works
1. Enable VPN on your iPad
2. Turn on tethering in TetherUnlock
3. Enable "Share VPN Connection" in settings
4. All tethered devices now route through your VPN

### VPN Settings
- **VPN Passthrough**: Routes tethered traffic through VPN tunnel
- **Share VPN DNS**: Uses VPN's DNS servers for tethered clients
- **Bypass Firewall**: Allows VPN protocol traffic through tether firewall

## Project Structure

```
TetherUnlock/
├── Tweak/                      # Theos tweak source
│   ├── Headers/               # Private API headers
│   ├── Tweak.x               # Main tweak entry
│   ├── TetherCore.x          # Core tethering controller
│   ├── WiFiTether.x          # Wi-Fi hotspot module
│   ├── USBTether.x           # USB tethering module
│   ├── BluetoothTether.x     # Bluetooth DUN module
│   ├── CarrierUnlock.x       # Carrier restriction bypass
│   ├── NetworkConfig.x       # Network configuration
│   └── VPNShare.x            # VPN sharing/passthrough
├── Prefs/                     # Settings UI (PreferenceBundle)
│   └── Resources/            # Settings plists
├── companion/                 # Standalone iOS app
│   ├── TetherUnlockApp/      # SwiftUI companion app
│   └── TetherUnlockApp.xcodeproj/
├── build_all.sh              # Universal build script
├── build_deb.sh              # .deb build script
├── build_ipa.sh              # .ipa build script
├── Dockerfile                # Docker build environment
├── docker-compose.yml        # Docker Compose config
├── Makefile                  # Theos build configuration
└── control                   # Debian package control
```

## Troubleshooting

### Build Issues

**"Theos not found"**
```bash
# Install Theos
bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"
```

**"No iOS SDK"**
```bash
# Download iOS 15.5 SDK
cd $THEOS/sdks
wget https://github.com/theos/sdks/archive/master.tar.gz
tar -xzf master.tar.gz
cp -r sdks-master/iPhoneOS15.5.sdk .
```

**"Code signing failed" (for .ipa)**
```bash
# Set your Apple Developer Team ID
export DEVELOPMENT_TEAM=YOUR_TEAM_ID
./build_ipa.sh
```

### Runtime Issues

| Issue | Solution |
|-------|----------|
| "No service" after enabling | Toggle airplane mode, respring |
| Wi-Fi hotspot not showing | Check cellular data, try 2.4GHz/5GHz |
| USB tethering not working | Use original cable, try different port |
| Bluetooth not connecting | Re-pair device, check compatibility |
| VPN not sharing | Ensure VPN is connected first |

## Technical Details

### Private APIs Used
- `CTTelephonyNetworkInfo` - Carrier information
- `NEHotspotConfigurationManager` - Wi-Fi hotspot
- `NEVPNManager` - VPN connection management
- `WiFiManagerClient` - MobileWiFi framework
- `IOBluetoothDevice` - Bluetooth management
- `NETunnelProviderManager` - Network extension

### Network Architecture
```
[Cellular] → [iPad] → [VPN Tunnel] → [Tether Interface] → [Clients]
                ↓
         [TetherUnlock]
         - NAT configuration
         - DNS forwarding
         - IP forwarding
         - VPN passthrough
```

## Uninstalling

**.deb:**
```bash
dpkg -r com.tetherunlock.tweak
```

**.ipa:**
- Delete app from home screen
- Or use AltStore/SideStore to uninstall

## License

MIT License

## Support

- GitHub: https://github.com/tetherunlock
- Issues: https://github.com/tetherunlock/issues

## Credits

- Inspired by TetherMe and MyWi
- Built with [Theos](https://theos.dev)
- VPN sharing based on NetworkExtension framework
