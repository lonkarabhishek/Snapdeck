import SwiftUI

struct MenuBarView: View {
    @ObservedObject var store: ScreenshotStore

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Recent Screenshots")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Button(action: { store.refresh() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Refresh")
                Text("\(store.screenshots.count)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            if store.screenshots.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    Text("No screenshots yet")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("Take a screenshot to get started")
                        .font(.system(size: 11))
                        .foregroundColor(Color(NSColor.tertiaryLabelColor))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(store.screenshots) { item in
                            ScreenshotRow(
                                item: item,
                                onCopy: { store.copyToClipboard(screenshot: item) },
                                onShowInFinder: { store.showInFinder(screenshot: item) }
                            )
                            .padding(.horizontal, 10)

                            if item.id != store.screenshots.last?.id {
                                Divider()
                                    .padding(.leading, 80)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Divider()

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
        .frame(width: 300, height: 400)
    }
}
