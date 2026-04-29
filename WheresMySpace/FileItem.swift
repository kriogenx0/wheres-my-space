import Foundation

struct FileItem: Identifiable, Sendable {
    let id = UUID()
    let url: URL
    let size: Int64

    var name: String { url.lastPathComponent }
    var path: String { url.path }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}
