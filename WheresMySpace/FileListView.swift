import SwiftUI

struct FileListView: View {
    let target: ScanTarget
    @ObservedObject var vm: StorageViewModel

    private var items: [FileItem] {
        vm.files[target] ?? []
    }

    private var largestSize: Int64 {
        items.first?.size ?? 1
    }

    var body: some View {
        Group {
            if vm.isScanning && (vm.files[target] == nil) {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Scanning \(target.label)…")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text(vm.files[target] == nil ? "Press Scan to analyze files" : "No large files found")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(items) { item in
                    FileRowView(item: item, largestSize: largestSize, accentColor: target.color)
                        .listRowSeparator(.visible)
                }
                .listStyle(.plain)
            }
        }
    }
}

struct FileRowView: View {
    let item: FileItem
    let largestSize: Int64
    let accentColor: Color

    private var fraction: Double {
        largestSize > 0 ? Double(item.size) / Double(largestSize) : 0
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Relative size bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(accentColor.opacity(0.15))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(accentColor)
                        .frame(width: geo.size.width * fraction, height: 4)
                }
                .frame(height: 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 80, height: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Text(item.path)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Text(item.formattedSize)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.primary)
                .frame(minWidth: 80, alignment: .trailing)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .contextMenu {
            Button("Reveal in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([item.url])
            }
            Button("Copy Path") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(item.path, forType: .string)
            }
        }
    }
}
