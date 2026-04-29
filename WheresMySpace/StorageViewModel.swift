import Foundation
import SwiftUI

enum ScanTarget: String, CaseIterable, Identifiable {
    case userLibrary = "~/Library"
    case systemLibrary = "/Library"
    case applications = "/Applications"

    var id: String { rawValue }

    var url: URL {
        switch self {
        case .userLibrary:
            return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library")
        case .systemLibrary:
            return URL(fileURLWithPath: "/Library")
        case .applications:
            return URL(fileURLWithPath: "/Applications")
        }
    }

    var color: Color {
        switch self {
        case .userLibrary: return .blue
        case .systemLibrary: return .green
        case .applications: return .orange
        }
    }

    var label: String { rawValue }
}

struct ScanBatch: Sendable {
    let currentPath: String
    let newItems: [FileItem]
    let allFolderSizes: [URL: Int64]
    let totalSoFar: Int64
}

@MainActor
class StorageViewModel: ObservableObject {
    @Published var files: [ScanTarget: [FileItem]] = [:]
    @Published var folders: [ScanTarget: [FolderItem]] = [:]
    @Published var totalSizes: [ScanTarget: Int64] = [:]
    @Published var isScanning = false
    @Published var currentScanningFile: String = ""
    @Published var totalDiskSpace: Int64 = 0

    func scan() {
        guard !isScanning else { return }
        isScanning = true
        files = [:]
        folders = [:]
        totalSizes = [:]
        currentScanningFile = ""
        loadDiskInfo()

        var completedCount = 0
        for target in ScanTarget.allCases {
            Task {
                for await batch in scanDirectoryStream(target) {
                    await MainActor.run { [weak self] in
                        guard let self else { return }
                        if !batch.currentPath.isEmpty {
                            self.currentScanningFile = batch.currentPath
                        }
                        if !batch.newItems.isEmpty {
                            var existing = self.files[target] ?? []
                            existing.append(contentsOf: batch.newItems)
                            existing.sort { $0.size > $1.size }
                            self.files[target] = Array(existing.prefix(1000))
                        } else if self.files[target] == nil {
                            self.files[target] = []
                        }
                        if !batch.allFolderSizes.isEmpty {
                            self.folders[target] = batch.allFolderSizes
                                .compactMap { $0.value >= 100_000_000 ? FolderItem(url: $0.key, size: $0.value) : nil }
                                .sorted { $0.size > $1.size }
                        }
                        self.totalSizes[target] = batch.totalSoFar
                    }
                }
                completedCount += 1
                if completedCount == ScanTarget.allCases.count {
                    isScanning = false
                    currentScanningFile = ""
                }
            }
        }
    }

    func moveToTrash(ids: Set<UUID>, target: ScanTarget) {
        guard !ids.isEmpty, var targetFiles = files[target] else { return }
        let toRemove = targetFiles.filter { ids.contains($0.id) }
        guard !toRemove.isEmpty else { return }
        targetFiles.removeAll { ids.contains($0.id) }
        files[target] = targetFiles
        let removedSize = toRemove.reduce(Int64(0)) { $0 + $1.size }
        totalSizes[target] = max(0, (totalSizes[target] ?? 0) - removedSize)
        Task.detached {
            for item in toRemove {
                try? FileManager.default.trashItem(at: item.url, resultingItemURL: nil)
            }
        }
    }

    private func loadDiskInfo() {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/"),
              let total = attrs[.systemSize] as? Int64 else { return }
        totalDiskSpace = total
    }
}

private func scanDirectoryStream(_ target: ScanTarget) -> AsyncStream<ScanBatch> {
    AsyncStream { continuation in
        Task.detached(priority: .userInitiated) {
            let url = target.url
            guard FileManager.default.fileExists(atPath: url.path) else {
                continuation.yield(ScanBatch(currentPath: "", newItems: [], allFolderSizes: [:], totalSoFar: 0))
                continuation.finish()
                return
            }

            var pending: [FileItem] = []
            var folderSizes: [URL: Int64] = [:]
            var total: Int64 = 0
            var lastYield = Date()
            let rootDepth = url.pathComponents.count

            let keys: [URLResourceKey] = [.fileSizeKey, .isRegularFileKey]
            guard let enumerator = FileManager.default.enumerator(
                at: url,
                includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles, .skipsPackageDescendants],
                errorHandler: { _, _ in true }
            ) else {
                continuation.yield(ScanBatch(currentPath: "", newItems: [], allFolderSizes: [:], totalSoFar: 0))
                continuation.finish()
                return
            }

            while let fileURL = enumerator.nextObject() as? URL {
                guard let vals = try? fileURL.resourceValues(forKeys: Set(keys)),
                      vals.isRegularFile == true,
                      let size = vals.fileSize else { continue }

                let byteSize = Int64(size)
                total += byteSize

                let components = fileURL.pathComponents
                if components.count > rootDepth {
                    let folderURL = url.appendingPathComponent(components[rootDepth])
                    folderSizes[folderURL, default: 0] += byteSize
                }

                if byteSize >= 1_000_000 {
                    pending.append(FileItem(url: fileURL, size: byteSize))
                }

                let now = Date()
                if now.timeIntervalSince(lastYield) >= 0.3 {
                    continuation.yield(ScanBatch(
                        currentPath: fileURL.path,
                        newItems: pending,
                        allFolderSizes: folderSizes,
                        totalSoFar: total
                    ))
                    pending = []
                    lastYield = now
                }
            }

            continuation.yield(ScanBatch(
                currentPath: "",
                newItems: pending,
                allFolderSizes: folderSizes,
                totalSoFar: total
            ))
            continuation.finish()
        }
    }
}
