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

@MainActor
class StorageViewModel: ObservableObject {
    @Published var files: [ScanTarget: [FileItem]] = [:]
    @Published var totalSizes: [ScanTarget: Int64] = [:]
    @Published var isScanning = false
    @Published var scanningTarget: ScanTarget? = nil
    @Published var totalDiskSpace: Int64 = 0

    func scan() {
        guard !isScanning else { return }
        isScanning = true
        files = [:]
        totalSizes = [:]
        loadDiskInfo()

        Task {
            await withTaskGroup(of: (ScanTarget, [FileItem], Int64).self) { group in
                for target in ScanTarget.allCases {
                    group.addTask {
                        let result = await Task.detached(priority: .userInitiated) {
                            scanDirectory(target)
                        }.value
                        return result
                    }
                }
                for await (target, items, total) in group {
                    self.files[target] = items
                    self.totalSizes[target] = total
                }
            }
            isScanning = false
            scanningTarget = nil
        }
    }

    private func loadDiskInfo() {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/"),
              let total = attrs[.systemSize] as? Int64 else { return }
        totalDiskSpace = total
    }
}

// Free function runs off-actor on a background thread
private func scanDirectory(_ target: ScanTarget) -> (ScanTarget, [FileItem], Int64) {
    let url = target.url
    guard FileManager.default.fileExists(atPath: url.path) else {
        return (target, [], 0)
    }

    var items: [FileItem] = []
    var total: Int64 = 0

    let keys: [URLResourceKey] = [.fileSizeKey, .isRegularFileKey]
    guard let enumerator = FileManager.default.enumerator(
        at: url,
        includingPropertiesForKeys: keys,
        options: [.skipsHiddenFiles, .skipsPackageDescendants],
        errorHandler: { _, _ in true }
    ) else {
        return (target, [], 0)
    }

    while let fileURL = enumerator.nextObject() as? URL {
        guard let vals = try? fileURL.resourceValues(forKeys: Set(keys)),
              let isRegular = vals.isRegularFile, isRegular,
              let size = vals.fileSize else { continue }
        let byteSize = Int64(size)
        total += byteSize
        if byteSize >= 1_000_000 {
            items.append(FileItem(url: fileURL, size: byteSize))
        }
    }

    items.sort { $0.size > $1.size }
    return (target, Array(items.prefix(1000)), total)
}
