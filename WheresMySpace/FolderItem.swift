import Foundation

struct FolderItem: Identifiable, Sendable {
    let id: UUID
    let url: URL
    var size: Int64

    init(url: URL, size: Int64) {
        self.id = UUID()
        self.url = url
        self.size = size
    }

    var name: String { url.lastPathComponent }
    var formattedSize: String { ByteCountFormatter.string(fromByteCount: size, countStyle: .file) }
}
