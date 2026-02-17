import SwiftUI

struct MenuBarView: View {
    @ObservedObject var monitor: NetworkMonitor
    @State private var isTestingSpeed = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("WiFiMon")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Button(action: { monitor.refresh() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Refresh")
                Circle()
                    .fill(monitor.isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // Connection info
            VStack(spacing: 12) {
                // Network name
                infoRow(icon: "wifi", label: "Network", value: monitor.ssid)

                // Signal strength
                HStack(spacing: 10) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                    Text("Signal")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                    HStack(spacing: 2) {
                        ForEach(0..<4, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(i < monitor.signalBars ? signalColor : Color.secondary.opacity(0.2))
                                .frame(width: 4, height: CGFloat(6 + i * 3))
                        }
                    }
                    Text(monitor.signalLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(signalColor)
                }

                // Ping
                infoRow(icon: "bolt.horizontal", label: "Ping", value: monitor.pingMs == "—" ? "—" : "\(monitor.pingMs) ms")

                // IP
                infoRow(icon: "network", label: "IP Address", value: monitor.ipAddress)

                Divider()

                // Speed test section
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "speedometer")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(width: 24)
                        Text("Speed Test")
                            .font(.system(size: 11, weight: .medium))
                        Spacer()
                        Button(action: {
                            isTestingSpeed = true
                            monitor.runSpeedTest()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                                isTestingSpeed = false
                            }
                        }) {
                            Text(isTestingSpeed ? "Testing..." : "Run Test")
                                .font(.system(size: 10, weight: .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(isTestingSpeed ? Color.secondary.opacity(0.2) : Color.accentColor)
                                .foregroundColor(isTestingSpeed ? .secondary : .white)
                                .cornerRadius(4)
                        }
                        .buttonStyle(.borderless)
                        .disabled(isTestingSpeed)
                    }

                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 10))
                                .foregroundColor(.green)
                            Text(monitor.downloadSpeed)
                                .font(.system(size: 11, design: .monospaced))
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                            Text(monitor.uploadSpeed)
                                .font(.system(size: 11, design: .monospaced))
                        }
                        Spacer()
                    }
                    .padding(.leading, 34)
                }

                Divider()

                // Ping history
                if !monitor.pingHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ping History")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)

                        PingGraph(values: monitor.pingHistory)
                            .frame(height: 40)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Spacer()

            Divider()

            // Footer
            HStack {
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
                .font(.system(size: 11))
                .foregroundColor(.secondary)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .frame(width: 300, height: 420)
    }

    private var signalColor: Color {
        switch monitor.signalBars {
        case 4, 3: return .green
        case 2: return .yellow
        case 1: return .red
        default: return .secondary
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(width: 24)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
        }
    }
}

struct PingGraph: View {
    let values: [Double]

    var body: some View {
        GeometryReader { geometry in
            let maxVal = max(values.max() ?? 1, 1)
            let width = geometry.size.width
            let height = geometry.size.height
            let step = values.count > 1 ? width / CGFloat(values.count - 1) : width

            Path { path in
                for (index, value) in values.enumerated() {
                    let x = CGFloat(index) * step
                    let y = height - (CGFloat(value / maxVal) * height)
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.accentColor, lineWidth: 1.5)
        }
    }
}
