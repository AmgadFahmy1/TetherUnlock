import SwiftUI
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
    @Published var wifiEnabled = true
    @Published var usbEnabled = true
    @Published var btEnabled = true
    @Published var vpnSharingEnabled = false
    @Published var ssid = ""
    @Published var password = ""
    @Published var statusMessage = ""
    @Published var carrierInfo: String = "Unknown"

    private let defaults = UserDefaults(suiteName: "com.tetherunlock.prefs")!

    init() {
        loadSettings()
        loadCarrierInfo()
    }

    func loadSettings() {
        isEnabled = defaults.bool(forKey: "tether_enabled")
        wifiEnabled = defaults.object(forKey: "wifi_tether_enabled") as? Bool ?? true
        usbEnabled = defaults.object(forKey: "usb_tether_enabled") as? Bool ?? true
        btEnabled = defaults.object(forKey: "bt_tether_enabled") as? Bool ?? true
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
        postCommand()
    }

    private func postCommand() {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("com.tetherunlock.command" as CFString),
            nil, nil, true
        )
        statusMessage = isEnabled
            ? "Command sent: enabling native tethering (Netrb/MIS)..."
            : "Command sent: disabling native tethering..."
    }

    func toggleTethering() {
        isEnabled.toggle()
        saveSettings()
    }

    func loadCarrierInfo() {
        let networkInfo = CTTelephonyNetworkInfo()
        if let carrier = networkInfo.subscriberCellularProvider {
            carrierInfo = "\(carrier.carrierName ?? "Unknown") (\(carrier.isoCountryCode ?? "?"))"
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
                Section {
                    Toggle("Enable Tethering", isOn: $tetherManager.isEnabled)
                        .onChange(of: tetherManager.isEnabled) { _ in
                            tetherManager.saveSettings()
                        }

                    if !tetherManager.statusMessage.isEmpty {
                        Text(tetherManager.statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } footer: {
                    Text("Sends the command to the TetherUnlock tweak, which drives Apple's built-in tethering stack (Netrb + Internet Sharing). Also available in Settings -> TetherUnlock.")
                }

                Section("Carrier Information") {
                    HStack {
                        Text("Carrier")
                        Spacer()
                        Text(tetherManager.carrierInfo)
                            .foregroundColor(.secondary)
                    }
                }

                Section {
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
                } header: {
                    Text("Tethering Methods")
                } footer: {
                    Text("The native Apple stack manages all three interfaces together when tethering is enabled. These switches record your preference for the tweak.")
                }

                Section {
                    Toggle("Share VPN Connection", isOn: $tetherManager.vpnSharingEnabled)
                        .onChange(of: tetherManager.vpnSharingEnabled) { _ in
                            tetherManager.saveSettings()
                        }
                } header: {
                    Text("VPN Sharing")
                } footer: {
                    Text("Requires an active VPN and on-device validation (coming in the next build after SSH recon). Saving the preference now; the routing hook will be enabled once validated.")
                }

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

                Section("Help") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Requirements")
                            .font(.headline)
                        Text("• Jailbreak: unc0ver (iPhone, rootful) or Xina15 (iPad, rootless)")
                            .font(.caption)
                        Text("• TetherUnlock tweak installed (matching your jailbreak type)")
                            .font(.caption)
                        Text("• A carrier plan without tethering restrictions, or Carrier Unlock enabled")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.1.0")
                            .foregroundColor(.secondary)
                    }
                    Link("GitHub Repository", destination: URL(string: "https://github.com/AmgadFahmy1/TetherUnlock")!)
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
