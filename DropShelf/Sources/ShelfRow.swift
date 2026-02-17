import SwiftUI
import UniformTypeIdentifiers

struct ShelfRow: View {
    let item: ShelfItem
    let onCopy: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Icon
            Image(nsImage: item.icon)
                .resizable()
                .frame(width: 32, height: 32)
                .cornerRadius(4)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack(spacing: 4) {
                    Text(typeLabel)
                        .font(.system(size: 10))
                        .foregroundColor(typeColor)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(typeColor.opacity(0.12))
                        .cornerRadius(3)

                    Text(relativeTime(from: item.date))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Copy button
            Button(action: onCopy) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.borderless)
            .help("Copy to clipboard")

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.borderless)
            .help("Remove from shelf")
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onDrag {
            switch item.type {
            case .file:
                if let url = item.fileURL {
                    return NSItemProvider(object: url as NSURL)
                }
            case .text:
                if let text = item.text {
                    return NSItemProvider(object: text as NSString)
                }
            case .image:
                if let data = item.imageData, let image = NSImage(data: data) {
                    return NSItemProvider(object: image)
                }
            }
            return NSItemProvider()
        }
        .contextMenu {
            Button("Copy") { onCopy() }
            if item.type == .file, let url = item.fileURL {
                Button("Show in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
                Button("Open") {
                    NSWorkspace.shared.open(url)
                }
            }
            Divider()
            Button("Remove") { onRemove() }
        }
    }

    private var typeLabel: String {
        switch item.type {
        case .file: return "File"
        case .text: return "Text"
        case .image: return "Image"
        }
    }

    private var typeColor: Color {
        switch item.type {
        case .file: return .blue
        case .text: return .green
        case .image: return .purple
        }
    }

    private func relativeTime(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let mins = Int(interval / 60)
            return "\(mins) min\(mins == 1 ? "" : "s") ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
}
