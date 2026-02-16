import SwiftUI

struct MenuBarView: View {
    @ObservedObject var store: DownloadStore

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("CleanDock")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(store.items.count) files")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 4)

            // Stats bar
            if store.oldItemsCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    Text("\(store.oldItemsCount) files older than 30 days")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    Spacer()
                    Button("Clean") {
                        store.cleanOldFiles()
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.orange)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.08))
            }

            // Auto-clean toggle
            HStack {
                Toggle(isOn: $store.autoCleanEnabled) {
                    Text("Auto-clean on launch")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .toggleStyle(.switch)
                .controlSize(.mini)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)

            Divider()

            // File list
            if store.items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    Text("Downloads folder is empty")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("Nice and clean!")
                        .font(.system(size: 11))
                        .foregroundColor(Color(NSColor.tertiaryLabelColor))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(store.items) { item in
                            DownloadRow(
                                item: item,
                                onOpen: { store.openFile(item) },
                                onShowInFinder: { store.showInFinder(item) },
                                onTrash: { store.moveToTrash(item) }
                            )
                            .padding(.horizontal, 10)

                            if item.id != store.items.last?.id {
                                Divider()
                                    .padding(.leading, 52)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

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

                Button("Open Downloads") {
                    NSWorkspace.shared.open(store.downloadsDir)
                }
                .buttonStyle(.borderless)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .frame(width: 320, height: 450)
    }
}
