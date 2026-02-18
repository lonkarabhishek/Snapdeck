import SwiftUI

struct MenuBarView: View {
    @ObservedObject var store: ShelfStore

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("DropShelf")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Button(action: { store.objectWillChange.send() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Refresh")
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

            // Selection bar
            if !store.items.isEmpty {
                HStack(spacing: 8) {
                    Button(action: {
                        if store.selectedIds.count == store.items.count {
                            store.clearSelection()
                        } else {
                            store.selectAll()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: store.selectedIds.count == store.items.count ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 11))
                            Text(store.selectedIds.count == store.items.count ? "Deselect All" : "Select All")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.secondary)
                    }
                    .buttonStyle(.borderless)

                    Spacer()

                    if store.hasSelection {
                        Text("\(store.selectedIds.count) selected")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)

                        Button(action: { store.copySelectedToClipboard() }) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 10))
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.borderless)
                        .help("Copy selected")

                        Button(action: { store.removeSelected() }) {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.borderless)
                        .help("Remove selected")
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 6)
            }

            Divider()

            // Drop zone + item list
            if store.items.isEmpty {
                dropZoneEmpty
            } else {
                itemList
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

                if !store.items.isEmpty {
                    Button("Clear All") {
                        store.clearAll()
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .frame(width: 300, height: 400)
    }

    private var dropZoneEmpty: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray.and.arrow.down")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text("Drop files, images, or text here")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Text("Drag them out whenever you need them")
                .font(.system(size: 11))
                .foregroundColor(Color(NSColor.tertiaryLabelColor))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                )
                .padding(12)
        )
    }

    private var itemList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Drop zone banner at top
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("Drop anywhere to add")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.05))
                )
                .padding(.horizontal, 10)
                .padding(.vertical, 4)

                ForEach(store.items) { item in
                    ShelfRow(
                        item: item,
                        isSelected: store.selectedIds.contains(item.id),
                        onSelect: { store.toggleSelection(item) },
                        onCopy: { store.copyToClipboard(item) },
                        onRemove: { store.removeItem(item) }
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
}
