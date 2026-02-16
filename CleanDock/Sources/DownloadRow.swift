import SwiftUI

struct DownloadRow: View {
    let item: DownloadItem
    let onOpen: () -> Void
    let onShowInFinder: () -> Void
    let onTrash: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // File icon from OS
            Image(nsImage: item.icon)
                .resizable()
                .frame(width: 32, height: 32)

            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.filename)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack(spacing: 6) {
                    Text(item.sizeString)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    Text("·")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    Text(relativeTime(from: item.date))
                        .font(.system(size: 10))
                        .foregroundColor(item.isOld ? .orange : .secondary)
                }
            }

            Spacer()

            // Trash button
            Button(action: onTrash) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.borderless)
            .help("Move to Trash")
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onOpen()
        }
        .onDrag {
            NSItemProvider(object: item.url as NSURL)
        }
        .contextMenu {
            Button("Open") { onOpen() }
            Button("Show in Finder") { onShowInFinder() }
            Divider()
            Button("Move to Trash") { onTrash() }
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
