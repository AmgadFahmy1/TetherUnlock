import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var tetherManager: TetherManager
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Advanced Settings") {
                    Toggle("Carrier Unlock", isOn: .constant(true))
                    
                    TextField("Custom APN", text: .constant(""))
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section("Network Settings") {
                    Picker("Wi-Fi Band", selection: .constant("Auto")) {
                        Text("2.4 GHz").tag("2.4GHz")
                        Text("5 GHz").tag("5GHz")
                        Text("Auto").tag("Auto")
                    }
                    
                    Picker("Security", selection: .constant("WPA2")) {
                        Text("WPA2").tag("WPA2")
                        Text("WPA3").tag("WPA3")
                        Text("Open").tag("Open")
                    }
                }
                
                Section("USB Settings") {
                    Toggle("Auto-configure DHCP", isOn: .constant(true))
                    
                    TextField("IP Range", text: .constant("192.168.1.100-200"))
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section("Bluetooth Settings") {
                    Toggle("Auto-connect", isOn: .constant(true))
                    
                    SecureField("PIN Code", text: .constant("1234"))
                }
                
                Section {
                    Button("Apply All Changes") {
                        applyChanges()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.blue)
                    
                    Button("Reset to Defaults") {
                        resetToDefaults()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .alert("Settings", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    func applyChanges() {
        tetherManager.saveSettings()
        alertMessage = "Settings saved. Respring may be required for some changes."
        showingAlert = true
    }
    
    func resetToDefaults() {
        tetherManager.ssid = tetherManager.generateDefaultSSID()
        tetherManager.password = "tetherunlock123"
        tetherManager.wifiEnabled = true
        tetherManager.usbEnabled = true
        tetherManager.btEnabled = true
        tetherManager.saveSettings()
        alertMessage = "Settings reset to defaults."
        showingAlert = true
    }
}

struct DevicesView: View {
    @State private var bluetoothDevices: [BluetoothDevice] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            List {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if bluetoothDevices.isEmpty {
                    HStack {
                        Spacer()
                        VStack {
                            Image(systemName: "bluetooth")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("No devices found")
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                } else {
                    Section("Bluetooth Devices") {
                        ForEach(bluetoothDevices, id: \.address) { device in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(device.name)
                                        .font(.headline)
                                    Text(device.address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if device.isConnected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Devices")
            .onAppear {
                loadDevices()
            }
            .refreshable {
                loadDevices()
            }
        }
    }
    
    func loadDevices() {
        isLoading = true
        
        // Simulate loading Bluetooth devices
        // In reality, this would use IOBluetooth APIs
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.bluetoothDevices = [
                BluetoothDevice(name: "Example Device", address: "00:00:00:00:00:00", isConnected: false)
            ]
            self.isLoading = false
        }
    }
}

struct BluetoothDevice {
    let name: String
    let address: String
    let isConnected: Bool
}

struct HelpView: View {
    var body: some View {
        NavigationView {
            List {
                Section("Getting Started") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How to use TetherUnlock:")
                            .font(.headline)
                        
                        Text("1. Install the TetherUnlock tweak via your package manager")
                            .font(.body)
                        Text("2. Respring your device")
                            .font(.body)
                        Text("3. Open Settings > TetherUnlock to configure")
                            .font(.body)
                        Text("4. Toggle on the tethering methods you need")
                            .font(.body)
                        Text("5. Connect your devices")
                            .font(.body)
                    }
                }
                
                Section("Troubleshooting") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Common issues:")
                            .font(.headline)
                        
                        Text("• Make sure you have an active cellular data plan")
                            .font(.body)
                        Text("• Some carriers block tethering - try enabling Carrier Unlock")
                            .font(.body)
                        Text("• Wi-Fi hotspot may require 5GHz on some models")
                            .font(.body)
                        Text("• USB tethering needs a Lightning/USB-C cable")
                            .font(.body)
                    }
                }
                
                Section("Compatibility") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Supported:")
                            .font(.headline)
                        
                        Text("• iPadOS 15.0 - 15.4.1")
                            .font(.body)
                        Text("• Xina15 rootless jailbreak")
                            .font(.body)
                        Text("• All iPad models (A12+)")
                            .font(.body)
                    }
                }
                
                Section("Links") {
                    Link("GitHub Repository", destination: URL(string: "https://github.com/tetherunlock")!)
                    
                    Link("Report an Issue", destination: URL(string: "https://github.com/tetherunlock/issues")!)
                }
            }
            .navigationTitle("Help")
        }
    }
}
