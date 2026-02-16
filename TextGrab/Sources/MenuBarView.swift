import SwiftUI

struct MenuBarView: View {
    @ObservedObject var store: TextStore
    var onGrabText: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("TextGrab")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(store.items.count)")
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

            // Grab button
            Button(action: onGrabText) {
                HStack {
                    Image(systemName: "viewfinder")
                        .font(.system(size: 14))
                    Text("Grab Text from Screen")
                        .font(.system(size: 12, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 14)
            .padding(.bottom, 8)

            Divider()

            // Recent extractions
            if store.items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "text.viewfinder")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    Text("No text grabbed yet")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("Click the button above to start")
                        .font(.system(size: 11))
                        .foregroundColor(Color(NSColor.tertiaryLabelColor))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(store.items) { item in
                            TextRow(
                                item: item,
                                onCopy: { store.copyToClipboard(item) },
                                onDelete: { store.deleteItem(item) }
                            )
                            .padding(.horizontal, 10)

                            if item.id != store.items.last?.id {
                                Divider()
                                    .padding(.leading, 44)
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

                Button("Clear All") {
                    store.clearAll()
                }
                .buttonStyle(.borderless)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .frame(width: 300, height: 400)
    }
}
