import SwiftUI
import UniformTypeIdentifiers

struct MenuBarView: View {
    @ObservedObject var store: ShelfStore
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("DropShelf")
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
                .foregroundColor(isTargeted ? .accentColor : .secondary)

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
                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                )
                .padding(12)
        )
        .onDrop(of: [.fileURL, .image, .plainText], isTargeted: $isTargeted) { providers in
            store.handleDrop(providers: providers)
        }
    }

    private var itemList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Drop zone banner at top
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(isTargeted ? .accentColor : .secondary)
                    Text("Drop here to add")
                        .font(.system(size: 11))
                        .foregroundColor(isTargeted ? .accentColor : .secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isTargeted ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.05))
                )
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .onDrop(of: [.fileURL, .image, .plainText], isTargeted: $isTargeted) { providers in
                    store.handleDrop(providers: providers)
                }

                ForEach(store.items) { item in
                    ShelfRow(
                        item: item,
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
        .onDrop(of: [.fileURL, .image, .plainText], isTargeted: .constant(false)) { providers in
            store.handleDrop(providers: providers)
        }
    }
}
