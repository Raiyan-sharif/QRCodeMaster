//
//  BatchScanView.swift
//  QRCodeMaster
//

import AVFoundation
import SwiftData
import SwiftUI

/// Scan many codes in one session; save them together to Drafts without opening URLs.
struct BatchScanView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var authorization: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var entries: [BatchScanEntry] = []
    @State private var torchOn = false
    @State private var showSaveConfirmation = false
    @State private var lastSavedCount = 0
    @State private var showCopiedToast = false

    /// Suppresses duplicate camera callbacks for the same frame (same string within a short window).
    @State private var lastThrottle: (code: String, at: Date)?

    private let teal = Color(red: 0.18, green: 0.72, blue: 0.65)

    var body: some View {
        ZStack {
            if authorization == .authorized {
                MetadataScannerView { code, type in
                    acceptScan(code: code, type: type)
                }
                .ignoresSafeArea(edges: [.top, .leading, .trailing])

                overlayChrome
            } else {
                ContentUnavailableView(
                    "Camera access",
                    systemImage: "camera.fill",
                    description: Text(authorization == .denied ? "Enable camera access in Settings to batch scan." : "Allow camera access when prompted.")
                )
                Button("Open Settings") {
                    if let u = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(u)
                    }
                }
            }
        }
        .navigationTitle("Batch Scan")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            authorization = AVCaptureDevice.authorizationStatus(for: .video)
            if authorization == .notDetermined {
                AVCaptureDevice.requestAccess(for: .video) { ok in
                    DispatchQueue.main.async {
                        authorization = ok ? .authorized : .denied
                    }
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                lastThrottle = nil
            }
        }
        .alert("Saved to Drafts", isPresented: $showSaveConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(lastSavedCount) item(s) were added to your Drafts library.")
        }
        .overlay(alignment: .top) {
            if showCopiedToast {
                Text("Copied to clipboard")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var overlayChrome: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    toggleTorch()
                } label: {
                    Image(systemName: torchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                        .font(.title2)
                        .padding(12)
                        .background(.ultraThinMaterial, in: Circle())
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            Spacer(minLength: 0)

            Text("Scan codes one after another — URLs are not opened automatically.")
                .font(.caption.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.bottom, 8)

            batchListPanel
        }
    }

    private var batchListPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Scanned (\(entries.count))")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if !entries.isEmpty {
                    Menu {
                        Button("Copy all text", systemImage: "doc.on.doc") {
                            copyAll()
                        }
                        Button("Save all to Drafts", systemImage: "square.and.arrow.down.on.square") {
                            saveAllToDrafts()
                        }
                        Divider()
                        Button("Clear list", systemImage: "trash", role: .destructive) {
                            withAnimation { entries.removeAll() }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .padding(8)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.thinMaterial)

            if entries.isEmpty {
                ContentUnavailableView(
                    "No scans yet",
                    systemImage: "viewfinder.rectangular",
                    description: Text("Point the camera at QR codes and barcodes. Each successful read appears here.")
                )
                .frame(maxHeight: 220)
                .background(Color(.secondarySystemGroupedBackground))
            } else {
                List {
                    ForEach(entries) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.symbologyLabel)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(teal)
                            Text(item.payload)
                                .font(.caption)
                                .lineLimit(4)
                                .textSelection(.enabled)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteEntries)
                }
                .listStyle(.plain)
                .frame(maxHeight: 280)
                .scrollContentBackground(.hidden)
                .background(Color(.secondarySystemGroupedBackground))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    private func acceptScan(code: String, type: AVMetadataObject.ObjectType) {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let now = Date()
        if let t = lastThrottle, t.code == trimmed, now.timeIntervalSince(t.at) < 0.85 {
            return
        }
        lastThrottle = (trimmed, now)

        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            entries.append(BatchScanEntry(payload: trimmed, metadataType: type))
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
    }

    private func copyAll() {
        let text = entries.map(\.payload).joined(separator: "\n")
        UIPasteboard.general.string = text
        withAnimation {
            showCopiedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation { showCopiedToast = false }
        }
    }

    private func saveAllToDrafts() {
        guard !entries.isEmpty else { return }
        let count = entries.count
        for item in entries {
            persist(item)
        }
        try? modelContext.save()
        entries.removeAll()
        lastThrottle = nil
        lastSavedCount = count
        showSaveConfirmation = true
    }

    private func persist(_ item: BatchScanEntry) {
        let kind: SavedCodeKind
        switch item.metadataType {
        case .qr, .dataMatrix, .aztec:
            kind = .qr
        default:
            kind = .barcode
        }
        let sym = item.metadataType.rawValue
        let saved = SavedCode(
            kind: kind,
            payload: item.payload,
            title: "Batch · " + item.scannedAt.formatted(date: .abbreviated, time: .shortened),
            thumbnailData: nil,
            source: .scanned,
            barcodeSymbology: kind == .barcode ? sym : nil
        )
        modelContext.insert(saved)
    }

    private func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            if device.torchMode == .on {
                device.torchMode = .off
                torchOn = false
            } else {
                try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
                torchOn = true
            }
        } catch {
            torchOn = false
        }
    }
}

// MARK: - Row model

private struct BatchScanEntry: Identifiable {
    let id = UUID()
    let payload: String
    let metadataType: AVMetadataObject.ObjectType
    let scannedAt: Date

    init(payload: String, metadataType: AVMetadataObject.ObjectType, scannedAt: Date = .now) {
        self.payload = payload
        self.metadataType = metadataType
        self.scannedAt = scannedAt
    }

    var symbologyLabel: String {
        switch metadataType {
        case .qr: return "QR Code"
        case .ean13: return "EAN-13"
        case .ean8: return "EAN-8"
        case .upce: return "UPC-E"
        case .code128: return "Code 128"
        case .pdf417: return "PDF417"
        case .aztec: return "Aztec"
        case .dataMatrix: return "Data Matrix"
        default: return metadataType.rawValue
        }
    }
}

#Preview {
    NavigationStack {
        BatchScanView()
    }
    .modelContainer(AppModelContainer.make(inMemory: true))
}
