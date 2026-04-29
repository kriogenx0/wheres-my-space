import SwiftUI

struct ContentView: View {
    @StateObject private var vm = StorageViewModel()
    @State private var selectedTab: ScanTarget = .userLibrary

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Where's My Space")
                        .font(.title2.bold())
                    Text("Find large files consuming disk space")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if vm.isScanning {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(vm.currentScanningFile.isEmpty
                             ? "Scanning…"
                             : URL(fileURLWithPath: vm.currentScanningFile).lastPathComponent)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: 220, alignment: .leading)
                    }
                }
                Button {
                    vm.scan()
                } label: {
                    Label("Scan", systemImage: "magnifyingglass")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.isScanning)
                .keyboardShortcut("r", modifiers: .command)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Storage Bar
            StorageBarView(vm: vm)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            Divider()

            // Tab picker
            Picker("Directory", selection: $selectedTab) {
                ForEach(ScanTarget.allCases) { target in
                    HStack {
                        Circle()
                            .fill(target.color)
                            .frame(width: 8, height: 8)
                        Text(target.label)
                    }
                    .tag(target)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)

            // File list
            FileListView(target: selectedTab, vm: vm)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Footer
            if let count = vm.files[selectedTab]?.count, count > 0 {
                Divider()
                HStack {
                    Text("\(count) files shown")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let total = vm.totalSizes[selectedTab] {
                        Text("Total: \(ByteCountFormatter.string(fromByteCount: total, countStyle: .file))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
            }
        }
        .frame(minWidth: 800, minHeight: 560)
    }
}
