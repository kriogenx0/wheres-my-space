import SwiftUI

struct FileListView: View {
    let target: ScanTarget
    @ObservedObject var vm: StorageViewModel
    @State private var selection: Set<UUID> = []

    private var items: [FileItem] { vm.files[target] ?? [] }
    private var folders: [FolderItem] { vm.folders[target] ?? [] }
    private var largestFileSize: Int64 { items.first?.size ?? 1 }
    private var largestFolderSize: Int64 { folders.first?.size ?? 1 }

    var body: some View {
        Group {
            if vm.isScanning && vm.files[target] == nil {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Scanning \(target.label)…")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if items.isEmpty && folders.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text(vm.files[target] == nil ? "Press Scan to analyze files" : "No large files found")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selection) {
                    if !folders.isEmpty {
                        Section("Folders") {
                            ForEach(folders) { folder in
                                FolderRowView(
                                    folder: folder,
                                    largestSize: largestFolderSize,
                                    accentColor: target.color,
                                    onDelete: { vm.moveFolderToTrash(folder: folder, target: target) }
                                )
                                    .listRowSeparator(.visible)
                                    .contextMenu {
                                        Button("Reveal in Finder") {
                                            NSWorkspace.shared.activateFileViewerSelecting([folder.url])
                                        }
                                    }
                            }
                        }
                    }
                    if !items.isEmpty {
                        Section("Large Files") {
                            ForEach(items) { item in
                                FileRowView(
                                    item: item,
                                    largestSize: largestFileSize,
                                    accentColor: target.color,
                                    onDelete: {
                                        vm.moveToTrash(ids: [item.id], target: target)
                                        selection.remove(item.id)
                                    }
                                )
                                    .listRowSeparator(.visible)
                                    .contextMenu {
                                        Button("Reveal in Finder") {
                                            NSWorkspace.shared.activateFileViewerSelecting([item.url])
                                        }
                                        Button("Copy Path") {
                                            NSPasteboard.general.clearContents()
                                            NSPasteboard.general.setString(item.path, forType: .string)
                                        }
                                        Divider()
                                        Button("Move to Trash") {
                                            let fileIds = Set(items.map(\.id))
                                            let toDelete: Set<UUID> = selection.contains(item.id)
                                                ? selection.intersection(fileIds)
                                                : [item.id]
                                            vm.moveToTrash(ids: toDelete, target: target)
                                            selection.subtract(toDelete)
                                        }
                                    }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .onDeleteCommand {
                    let fileIds = Set(items.map(\.id))
                    let toDelete = selection.intersection(fileIds)
                    guard !toDelete.isEmpty else { return }
                    vm.moveToTrash(ids: toDelete, target: target)
                    selection.subtract(toDelete)
                }
            }
        }
        .onChange(of: target) { _ in selection = [] }
    }
}

struct FolderRowView: View {
    let folder: FolderItem
    let largestSize: Int64
    let accentColor: Color
    let onDelete: () -> Void
    @State private var isHovering = false
    @State private var showDeleteConfirm = false

    private var fraction: Double {
        largestSize > 0 ? Double(folder.size) / Double(largestSize) : 0
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
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
            }
            .frame(width: 80, height: 4)

            Image(systemName: "folder.fill")
                .foregroundStyle(accentColor)
                .font(.system(size: 13))
                .frame(width: 16)

            Text(folder.name)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)

            Spacer()

            Text(folder.formattedSize)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.primary)
                .frame(minWidth: 80, alignment: .trailing)

            RevealFolderButton(isVisible: isHovering) {
                NSWorkspace.shared.open(folder.url)
            }

            TrashButton(isVisible: isHovering) {
                showDeleteConfirm = true
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .confirmationDialog(
            "Move “\(folder.name)” to the Trash?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Move to Trash", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct FileRowView: View {
    let item: FileItem
    let largestSize: Int64
    let accentColor: Color
    let onDelete: () -> Void
    @State private var isHovering = false
    @State private var showDeleteConfirm = false

    private var fraction: Double {
        largestSize > 0 ? Double(item.size) / Double(largestSize) : 0
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
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
            }
            .frame(width: 80, height: 4)

            Image(systemName: "doc.fill")
                .foregroundStyle(.secondary)
                .font(.system(size: 13))
                .frame(width: 16)

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

            RevealFolderButton(isVisible: isHovering) {
                NSWorkspace.shared.activateFileViewerSelecting([item.url])
            }

            TrashButton(isVisible: isHovering) {
                showDeleteConfirm = true
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .confirmationDialog(
            "Move “\(item.name)” to the Trash?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Move to Trash", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        }
    }
}

private struct HoverIconButton: View {
    let systemName: String
    let helpText: String
    let isVisible: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12))
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.borderless)
        .help(helpText)
        .opacity(isVisible ? 1 : 0)
        .allowsHitTesting(isVisible)
    }
}

private struct RevealFolderButton: View {
    let isVisible: Bool
    let action: () -> Void

    var body: some View {
        HoverIconButton(systemName: "folder", helpText: "Open Enclosing Folder", isVisible: isVisible, action: action)
    }
}

private struct TrashButton: View {
    let isVisible: Bool
    let action: () -> Void

    var body: some View {
        HoverIconButton(systemName: "trash", helpText: "Move to Trash", isVisible: isVisible, action: action)
    }
}
