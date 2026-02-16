import SwiftUI

struct MenuBarView: View {
    @ObservedObject var store: ClipboardStore

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("KleepMe")
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

            // Search bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                TextField("Search clipboard...", text: $store.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                if !store.searchText.isEmpty {
                    Button(action: { store.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 8)

            Divider()

            // Item list
            if store.displayItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clipboard")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    Text(store.searchText.isEmpty ? "No clipboard history" : "No matches")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    if store.searchText.isEmpty {
                        Text("Copy something to get started")
                            .font(.system(size: 11))
                            .foregroundColor(Color(NSColor.tertiaryLabelColor))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(store.displayItems) { item in
                            ClipboardRow(
                                item: item,
                                onCopy: { store.copyToClipboard(item) },
                                onTogglePin: { store.togglePin(item) },
                                onDelete: { store.deleteItem(item) }
                            )
                            .padding(.horizontal, 10)

                            if item.id != store.displayItems.last?.id {
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
