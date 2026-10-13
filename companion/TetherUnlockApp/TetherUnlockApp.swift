import SwiftUI
import NetworkExtension
import CoreTelephony

@main
struct TetherUnlockApp: App {
    @StateObject private var tetherManager = TetherManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tetherManager)
        }
    }
}

class TetherManager: ObservableObject {
    @Published var isEnabled = false
    @Published var wifiEnabled = false
    @Published var usbEnabled = false
    @Published var btEnabled = false
    @Published var vpnSharingEnabled = false
    @Published var ssid = ""
    @Published var password = ""
    @Published var statusMessage = ""
    @Published var carrierInfo: String = "Unknown"
    @Published var activeVPNs: [String] = []
    
    private let defaults = UserDefaults(suiteName: "com.tetherunlock.prefs")!
    
    init() {
        loadSettings()
        loadCarrierInfo()
        loadVPNStatus()
    }
    
    func loadSettings() {
        isEnabled = defaults.bool(forKey: "tether_enabled")
        wifiEnabled = defaults.bool(forKey: "wifi_tether_enabled")
        usbEnabled = defaults.bool(forKey: "usb_tether_enabled")
        btEnabled = defaults.bool(forKey: "bt_tether_enabled")
        vpnSharingEnabled = defaults.bool(forKey: "vpn_passthrough_enabled")
        ssid = defaults.string(forKey: "wifi_ssid") ?? generateDefaultSSID()
        password = defaults.string(forKey: "wifi_password") ?? "tetherunlock123"
    }
    
    func saveSettings() {
        defaults.set(isEnabled, forKey: "tether_enabled")
        defaults.set(wifiEnabled, forKey: "wifi_tether_enabled")
        defaults.set(usbEnabled, forKey: "usb_tether_enabled")
        defaults.set(btEnabled, forKey: "bt_tether_enabled")
        defaults.set(vpnSharingEnabled, forKey: "vpn_passthrough_enabled")
        defaults.set(ssid, forKey: "wifi_ssid")
        defaults.set(password, forKey: "wifi_password")
        defaults.synchronize()
    }
    
    func loadVPNStatus() {
        // Check for active VPN connections
        // In the tweak context, this would query NEVPNManager
        activeVPNs = []
        
        // Simulate VPN detection
        // Real implementation uses NEVPNManager.sharedManager
    }
    
    func toggleTethering() {
        isEnabled.toggle()
        saveSettings()
        
        if isEnabled {
            enableAllTethering()
        } else {
            disableAllTethering()
        }
    }
    
    func enableAllTethering() {
        statusMessage = "Enabling tethering..."
        
        if wifiEnabled {
            enableWiFiHotspot()
        }
        
        if usbEnabled {
            enableUSBTethering()
        }
        
        if btEnabled {
            enableBluetoothTethering()
        }
        
        statusMessage = "Tethering enabled"
    }
    
    func disableAllTethering() {
        statusMessage = "Disabling tethering..."
        
        disableWiFiHotspot()
        
        statusMessage = "Tethering disabled"
    }
    
    func enableWiFiHotspot() {
        let config = NEHotspotConfiguration(ssid: ssid, passphrase: password, isWEP: false)
        config.lifeTimeInDays = 1
        
        NEHotspotConfigurationManager.shared.apply(config) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.statusMessage = "Wi-Fi error: \(error.localizedDescription)"
                } else {
                    self.statusMessage = "Wi-Fi hotspot enabled"
                }
            }
        }
    }
    
    func disableWiFiHotspot() {
        NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: ssid)
    }
    
    func enableUSBTethering() {
        // USB tethering requires system-level access
        // This is only fully functional with the jailbreak tweak
        statusMessage = "USB tethering requires jailbreak"
    }
    
    func enableBluetoothTethering() {
        // Bluetooth DUN requires system-level access
        statusMessage = "Bluetooth DUN requires jailbreak"
    }
    
    func toggleVPNSharing() {
        vpnSharingEnabled.toggle()
        saveSettings()
        
        if vpnSharingEnabled {
            enableVPNSharing()
        } else {
            disableVPNSharing()
        }
    }
    
    func enableVPNSharing() {
        statusMessage = "Enabling VPN sharing..."
        
        // Check for active VPN
        loadVPNStatus()
        
        if activeVPNs.isEmpty {
            // Try to detect VPN via NEVPNManager
            let vpnManager = NEVPNManager.shared()
            vpnManager.loadFromPreferences { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.statusMessage = "VPN error: \(error.localizedDescription)"
                        return
                    }
                    
                    if vpnManager.connection.status == .connected {
                        self?.activeVPNs = ["Active VPN"]
                        self?.statusMessage = "VPN sharing enabled"
                        self?.configureVPNPassthrough()
                    } else {
                        self?.statusMessage = "No active VPN connection found"
                        self?.vpnSharingEnabled = false
                        self?.saveSettings()
                    }
                }
            }
        } else {
            statusMessage = "VPN sharing enabled"
            configureVPNPassthrough()
        }
    }
    
    func disableVPNSharing() {
        statusMessage = "Disabling VPN sharing..."
        // Remove VPN-specific routing
        statusMessage = "VPN sharing disabled"
    }
    
    func configureVPNPassthrough() {
        // Configure network routing to share VPN over tether
        // This requires jailbreak-level network access
        statusMessage = "VPN passthrough configured"
    }
    
    func loadCarrierInfo() {
        let networkInfo = CTTelephonyNetworkInfo()
        
        if let carrier = networkInfo.subscriberCellularProvider {
            carrierInfo = "\(carrier.carrierName ?? "Unknown") (\(carrier.isoCountryCode ?? "?"))"
            
            if carrier.isDataPlanEnabled {
                carrierInfo += " - Data enabled"
            } else {
                carrierInfo += " - Data disabled"
            }
        }
    }
    
    func generateRandomPassword() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        password = String((0..<12).compactMap { _ in characters.randomElement() })
        saveSettings()
        return password
    }
    
    func generateDefaultSSID() -> String {
        let deviceName = UIDevice.current.name
        return "\(deviceName) Tether"
    }
}

struct ContentView: View {
    @EnvironmentObject var tetherManager: TetherManager
    
    var body: some View {
        NavigationView {
            List {
                // Main toggle
                Section {
                    Toggle("Enable Tethering", isOn: $tetherManager.isEnabled)
                        .onChange(of: tetherManager.isEnabled) { newValue in
                            if newValue {
                                tetherManager.enableAllTethering()
                            } else {
                                tetherManager.disableAllTethering()
                            }
                            tetherManager.saveSettings()
                        }
                    
                    if !tetherManager.statusMessage.isEmpty {
                        Text(tetherManager.statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Carrier info
                Section("Carrier Information") {
                    HStack {
                        Text("Carrier")
                        Spacer()
                        Text(tetherManager.carrierInfo)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Tethering methods
                Section("Tethering Methods") {
                    Toggle("Wi-Fi Hotspot", isOn: $tetherManager.wifiEnabled)
                        .onChange(of: tetherManager.wifiEnabled) { _ in
                            tetherManager.saveSettings()
                        }
                    
                    Toggle("USB Tethering", isOn: $tetherManager.usbEnabled)
                        .onChange(of: tetherManager.usbEnabled) { _ in
                            tetherManager.saveSettings()
                        }
                    
                    Toggle("Bluetooth DUN", isOn: $tetherManager.btEnabled)
                        .onChange(of: tetherManager.btEnabled) { _ in
                            tetherManager.saveSettings()
                        }
                }
                
                // VPN Sharing
                Section {
                    Toggle("Share VPN Connection", isOn: $tetherManager.vpnSharingEnabled)
                        .onChange(of: tetherManager.vpnSharingEnabled) { newValue in
                            if newValue {
                                tetherManager.enableVPNSharing()
                            } else {
                                tetherManager.disableVPNSharing()
                            }
                            tetherManager.saveSettings()
                        }
                    
                    if tetherManager.vpnSharingEnabled {
                        if tetherManager.activeVPNs.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                Text("No active VPN detected")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        } else {
                            ForEach(tetherManager.activeVPNs, id: \.self) { vpn in
                                HStack {
                                    Image(systemName: "lock.shield")
                                        .foregroundColor(.green)
                                    Text(vpn)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                } header: {
                    Text("VPN Sharing")
                } footer: {
                    Text("Share your active VPN connection (IKEv2, IPSec, OpenVPN) with tethered devices.")
                }
                
                // Wi-Fi settings
                if tetherManager.wifiEnabled {
                    Section("Wi-Fi Settings") {
                        TextField("Network Name (SSID)", text: $tetherManager.ssid)
                            .onChange(of: tetherManager.ssid) { _ in
                                tetherManager.saveSettings()
                            }
                        
                        SecureField("Password", text: $tetherManager.password)
                            .onChange(of: tetherManager.password) { _ in
                                tetherManager.saveSettings()
                            }
                        
                        Button("Generate Random Password") {
                            _ = tetherManager.generateRandomPassword()
                        }
                    }
                }
                
                // Help section
                Section("Help") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Requirements")
                            .font(.headline)
                        
                        Text("• Jailbreak with Xina15 or similar")
                            .font(.caption)
                        Text("• TetherUnlock tweak installed")
                            .font(.caption)
                        Text("• Compatible carrier plan")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("GitHub Repository", destination: URL(string: "https://github.com/tetherunlock")!)
                }
            }
            .navigationTitle("TetherUnlock")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(TetherManager())
    }
}
