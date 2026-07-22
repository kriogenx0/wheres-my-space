import XCTest
@testable import WheresMySpace

final class WheresMySpaceTests: XCTestCase {
    func testFileItemNameAndPath() {
        let item = FileItem(url: URL(fileURLWithPath: "/tmp/example.bin"), size: 1_500_000)
        XCTAssertEqual(item.name, "example.bin")
        XCTAssertEqual(item.path, "/tmp/example.bin")
        XCTAssertFalse(item.formattedSize.isEmpty)
    }

    func testFolderItemName() {
        let folder = FolderItem(url: URL(fileURLWithPath: "/tmp/SomeFolder"), size: 2_000_000)
        XCTAssertEqual(folder.name, "SomeFolder")
    }

    func testScanTargetURLs() {
        XCTAssertEqual(ScanTarget.applications.url.path, "/Applications")
        XCTAssertEqual(ScanTarget.systemLibrary.url.path, "/Library")
    }

    @MainActor
    func testMoveToTrashUpdatesState() {
        let vm = StorageViewModel()
        let item = FileItem(url: URL(fileURLWithPath: "/tmp/wms-test-nonexistent-\(UUID().uuidString).bin"), size: 5_000_000)
        vm.files[.applications] = [item]
        vm.totalSizes[.applications] = 5_000_000

        vm.moveToTrash(ids: [item.id], target: .applications)

        XCTAssertEqual(vm.files[.applications]?.isEmpty, true)
        XCTAssertEqual(vm.totalSizes[.applications], 0)
    }

    @MainActor
    func testMoveFolderToTrashUpdatesState() {
        let vm = StorageViewModel()
        let folder = FolderItem(url: URL(fileURLWithPath: "/tmp/wms-test-nonexistent-\(UUID().uuidString)"), size: 3_000_000)
        vm.folders[.applications] = [folder]
        vm.totalSizes[.applications] = 3_000_000

        vm.moveFolderToTrash(folder: folder, target: .applications)

        XCTAssertEqual(vm.folders[.applications]?.isEmpty, true)
        XCTAssertEqual(vm.totalSizes[.applications], 0)
    }
}
