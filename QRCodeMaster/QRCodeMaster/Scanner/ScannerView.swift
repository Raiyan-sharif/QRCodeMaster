//
//  ScannerView.swift
//  QRCodeMaster
//

import AVFoundation
import SwiftData
import SwiftUI
import UIKit

struct ScannerView: View {
    /// Switch to the Create tab (or first tab) so the user always has an obvious way off the scanner.
    var onGoToCreate: () -> Void = {}

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var authorization: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var lastCode: String?
    @State private var torchOn = false
    @State private var showSaveToFolderAlert = false
    @State private var pasteCandidate: String?
    /// Full decoded payload for copy / preview (plain-text QRs have no browser handoff).
    @State private var lastScanPayload: String?

    var body: some View {
        ZStack {
            if authorization == .authorized {
                MetadataScannerView { code, type in
                    // Delegate queue is main; keep updates synchronous so `lastCode` deduping is reliable.
                    guard code != lastCode else { return }
                    lastCode = code
                    persistScan(code, type: type)
                    if let url = Self.safeOpenableURL(from: code) {
                        lastScanPayload = nil
                        UIApplication.shared.open(url)
                    } else {
                        // Plain text / Wi‑Fi / contact / etc.: confirm what was read (no browser handoff).
                        showScanFeedback(code)
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
                        Button("Save to Folder") {
                            if let s = UIPasteboard.general.string, !s.isEmpty {
                                pasteCandidate = s
                                showSaveToFolderAlert = true
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

                    if let payload = lastScanPayload {
                        VStack(alignment: .center, spacing: 10) {
                            Text(Self.truncatedForDisplay(payload))
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .lineLimit(6)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .center)

                            HStack(spacing: 12) {
                                Button {
                                    UIPasteboard.general.string = payload
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                        .font(.subheadline.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .accessibilityHint("Copies the full scanned text to the clipboard")

                                Button("Done") {
                                    withAnimation {
                                        lastScanPayload = nil
                                        // Allow scanning the same QR again; `lastCode` was blocking re-detect.
                                        lastCode = nil
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
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
            // Fresh session when opening Scan (tab switch or returning from Safari / another screen).
            resetTransientScanState()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                // Leaving the app (e.g. URL opened in Safari) — don’t keep the old result sheet.
                resetTransientScanState()
            }
        }
        .alert("Save to Folder?", isPresented: $showSaveToFolderAlert) {
            Button("Save to Folder") {
                if let pasteCandidate {
                    persistScan(pasteCandidate, type: .qr)
                    lastCode = pasteCandidate
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The clipboard text will be saved to your Drafts folder.\n\n\(pasteCandidate ?? "")")
        }
    }

    private func resetTransientScanState() {
        lastScanPayload = nil
        lastCode = nil
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

    /// Only well-formed http(s) URLs are opened automatically (plain-text QRs stay in-app).
    private static func safeOpenableURL(from string: String) -> URL? {
        let t = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let u = URL(string: t), let scheme = u.scheme?.lowercased() else { return nil }
        guard scheme == "http" || scheme == "https" else { return nil }
        guard let host = u.host, !host.isEmpty else { return nil }
        return u
    }

    private func showScanFeedback(_ code: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            lastScanPayload = code
        }
    }

    private static func truncatedForDisplay(_ code: String, maxLen: Int = 400) -> String {
        guard code.count > maxLen else { return code }
        return String(code.prefix(maxLen)) + "…"
    }
}
