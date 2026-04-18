import SwiftUI

struct StorageBarView: View {
    @ObservedObject var vm: StorageViewModel

    private var grandTotal: Int64 {
        max(vm.totalSizes.values.reduce(0, +), 1)
    }

    private var diskTotal: Int64 {
        vm.totalDiskSpace > 0 ? vm.totalDiskSpace : grandTotal
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Storage Breakdown")
                .font(.headline)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background (unaccounted space)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: .quaternaryLabelColor))
                        .frame(height: 28)

                    HStack(spacing: 0) {
                        ForEach(ScanTarget.allCases) { target in
                            let size = vm.totalSizes[target] ?? 0
                            let fraction = diskTotal > 0 ? Double(size) / Double(diskTotal) : 0
                            let width = geo.size.width * fraction
                            if width > 1 {
                                Rectangle()
                                    .fill(target.color)
                                    .frame(width: width, height: 28)
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .frame(height: 28)

            // Legend
            HStack(spacing: 20) {
                ForEach(ScanTarget.allCases) { target in
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(target.color)
                            .frame(width: 14, height: 14)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(target.label)
                                .font(.caption)
                                .foregroundStyle(.primary)
                            let size = vm.totalSizes[target] ?? 0
                            Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                if vm.totalDiskSpace > 0 {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Total Disk")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(ByteCountFormatter.string(fromByteCount: vm.totalDiskSpace, countStyle: .file))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
