import AppKit
import CoreWLAN
import SystemConfiguration

class NetworkMonitor: ObservableObject {
    @Published var ssid: String = "—"
    @Published var signalStrength: Int = 0
    @Published var pingMs: String = "—"
    @Published var isConnected: Bool = false
    @Published var downloadSpeed: String = "—"
    @Published var uploadSpeed: String = "—"
    @Published var ipAddress: String = "—"
    @Published var pingHistory: [Double] = []

    var onStatusChange: (() -> Void)?
    private var pingTimer: Timer?
    private var wifiTimer: Timer?
    private let maxHistory = 30

    var statusText: String {
        if !isConnected { return "No Wi-Fi" }
        if pingMs == "—" { return "\(ssid)" }
        return "\(pingMs)ms"
    }

    var signalBars: Int {
        if signalStrength > -50 { return 4 }
        if signalStrength > -60 { return 3 }
        if signalStrength > -70 { return 2 }
        if signalStrength > -80 { return 1 }
        return 0
    }

    var signalLabel: String {
        switch signalBars {
        case 4: return "Excellent"
        case 3: return "Good"
        case 2: return "Fair"
        case 1: return "Weak"
        default: return "No Signal"
        }
    }

    var signalColor: String {
        switch signalBars {
        case 4, 3: return "green"
        case 2: return "yellow"
        case 1: return "red"
        default: return "gray"
        }
    }

    func start() {
        updateWiFiInfo()
        runPing()

        // Update Wi-Fi info every 5 seconds
        wifiTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateWiFiInfo()
        }

        // Ping every 3 seconds
        pingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.runPing()
        }
    }

    func stop() {
        pingTimer?.invalidate()
        wifiTimer?.invalidate()
    }

    func refresh() {
        updateWiFiInfo()
        runPing()
    }

    private func updateWiFiInfo() {
        guard let wifiClient = CWWiFiClient.shared().interface() else {
            DispatchQueue.main.async {
                self.isConnected = false
                self.ssid = "—"
                self.signalStrength = 0
                self.ipAddress = "—"
                self.onStatusChange?()
            }
            return
        }

        let name = wifiClient.ssid() ?? "—"
        let rssi = wifiClient.rssiValue()
        let connected = wifiClient.ssid() != nil
        let ip = getIPAddress() ?? "—"

        DispatchQueue.main.async {
            self.ssid = name
            self.signalStrength = rssi
            self.isConnected = connected
            self.ipAddress = ip
        }
    }

    private func runPing() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/sbin/ping")
            task.arguments = ["-c", "1", "-t", "3", "8.8.8.8"]

            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe

            do {
                try task.run()
                task.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""

                if let range = output.range(of: "time="),
                   let endRange = output.range(of: " ms", range: range.upperBound..<output.endIndex) {
                    let timeStr = String(output[range.upperBound..<endRange.lowerBound])
                    if let ms = Double(timeStr) {
                        DispatchQueue.main.async {
                            self?.pingMs = String(format: "%.0f", ms)
                            self?.pingHistory.append(ms)
                            if (self?.pingHistory.count ?? 0) > (self?.maxHistory ?? 30) {
                                self?.pingHistory.removeFirst()
                            }
                            self?.onStatusChange?()
                        }
                        return
                    }
                }

                DispatchQueue.main.async {
                    self?.pingMs = "timeout"
                }
            } catch {
                DispatchQueue.main.async {
                    self?.pingMs = "error"
                }
            }
        }
    }

    func runSpeedTest() {
        downloadSpeed = "testing..."
        uploadSpeed = "testing..."

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // Download test: fetch a small file and measure speed
            let testURL = URL(string: "https://speed.cloudflare.com/__down?bytes=5000000")!
            let start = Date()
            if let data = try? Data(contentsOf: testURL) {
                let elapsed = Date().timeIntervalSince(start)
                let mbps = (Double(data.count) * 8.0) / (elapsed * 1_000_000.0)
                DispatchQueue.main.async {
                    self?.downloadSpeed = String(format: "%.1f Mbps", mbps)
                }
            } else {
                DispatchQueue.main.async {
                    self?.downloadSpeed = "failed"
                }
            }

            // Upload test: send data and measure
            var request = URLRequest(url: URL(string: "https://speed.cloudflare.com/__up")!)
            request.httpMethod = "POST"
            let uploadData = Data(repeating: 0, count: 1_000_000)
            let uploadStart = Date()
            let semaphore = DispatchSemaphore(value: 0)
            var uploadSuccess = false

            let uploadTask = URLSession.shared.uploadTask(with: request, from: uploadData) { _, _, error in
                if error == nil {
                    uploadSuccess = true
                }
                semaphore.signal()
            }
            uploadTask.resume()
            semaphore.wait()

            if uploadSuccess {
                let elapsed = Date().timeIntervalSince(uploadStart)
                let mbps = (Double(uploadData.count) * 8.0) / (elapsed * 1_000_000.0)
                DispatchQueue.main.async {
                    self?.uploadSpeed = String(format: "%.1f Mbps", mbps)
                }
            } else {
                DispatchQueue.main.async {
                    self?.uploadSpeed = "failed"
                }
            }
        }
    }

    private func getIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        return address
    }
}
