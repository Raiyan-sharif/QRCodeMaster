//
//  ScannerView.swift
//  QRCodeMaster
//

import AVFoundation
import SwiftData
import SwiftUI

struct ScannerView: View {
    /// Switch to the Create tab (or first tab) so the user always has an obvious way off the scanner.
    var onGoToCreate: () -> Void = {}

    @Environment(\.modelContext) private var modelContext

    @State private var authorization: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var lastCode: String?
    @State private var torchOn = false
    @State private var showPasteAlert = false
    @State private var pasteCandidate: String?

    var body: some View {
        ZStack {
            if authorization == .authorized {
                MetadataScannerView { code, type in
                    guard code != lastCode else { return }
                    lastCode = code
                    persistScan(code, type: type)
                    if let url = Self.safeOpenableURL(from: code) {
                        UIApplication.shared.open(url)
                    }
                }
                // Keep the bottom safe area so the tab bar stays visible and tappable.
                .ignoresSafeArea(edges: [.top, .leading, .trailing])

                VStack {
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
                        Button("Paste") {
                            if let s = UIPasteboard.general.string, !s.isEmpty {
                                pasteCandidate = s
                                showPasteAlert = true
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                    }
                    .padding()
                    Spacer()
                    Text("Point the camera at a code")
                        .font(.subheadline.weight(.semibold))
                        .padding(12)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 28)
                }
            } else {
                ContentUnavailableView(
                    "Camera access",
                    systemImage: "camera.fill",
                    description: Text(authorization == .denied ? "Enable camera access in Settings to scan codes." : "Allow camera access when prompted.")
                )
                Button("Open Settings") {
                    if let u = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(u)
                    }
                }
            }
        }
        .navigationTitle("Scan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    onGoToCreate()
                } label: {
                    Label("Create", systemImage: "chevron.backward")
                }
                .accessibilityHint("Go to the Create tab")
            }
        }
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
        .alert("Save clipboard text?", isPresented: $showPasteAlert) {
            Button("Save to Library") {
                if let pasteCandidate {
                    persistScan(pasteCandidate, type: .qr)
                    lastCode = pasteCandidate
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(pasteCandidate ?? "")
        }
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

    private func persistScan(_ code: String, type: AVMetadataObject.ObjectType) {
        let kind: SavedCodeKind
        switch type {
        case .qr, .dataMatrix, .aztec:
            kind = .qr
        default:
            kind = .barcode
        }
        let sym = type.rawValue
        let item = SavedCode(
            kind: kind,
            payload: code,
            title: "Scan · " + Date.now.formatted(date: .abbreviated, time: .shortened),
            thumbnailData: nil,
            source: .scanned,
            barcodeSymbology: kind == .barcode ? sym : nil
        )
        modelContext.insert(item)
        try? modelContext.save()
    }

    /// Only http(s) URLs are opened automatically.
    private static func safeOpenableURL(from string: String) -> URL? {
        let t = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let u = URL(string: t), let scheme = u.scheme?.lowercased() else { return nil }
        guard scheme == "http" || scheme == "https" else { return nil }
        return u
    }
}
