//
//  MetadataScannerView.swift
//  QRCodeMaster
//

import AVFoundation
import SwiftUI
import UIKit

struct MetadataScannerView: UIViewRepresentable {
    var onFound: (String, AVMetadataObject.ObjectType) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFound: onFound)
    }

    func makeUIView(context: Context) -> PreviewView {
        let v = PreviewView()
        context.coordinator.attach(to: v)
        return v
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Keep handler fresh; avoid stale SwiftUI closures.
        context.coordinator.onFound = onFound
    }

    static func dismantleUIView(_ uiView: PreviewView, coordinator: Coordinator) {
        coordinator.stopSession()
    }

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        private let session = AVCaptureSession()
        private let output = AVCaptureMetadataOutput()
        var onFound: (String, AVMetadataObject.ObjectType) -> Void
        private var attached = false

        init(onFound: @escaping (String, AVMetadataObject.ObjectType) -> Void) {
            self.onFound = onFound
        }

        func attach(to preview: PreviewView) {
            guard !attached else { return }
            attached = true

            session.beginConfiguration()
            session.sessionPreset = .high

            guard
                let device = AVCaptureDevice.default(for: .video),
                let input = try? AVCaptureDeviceInput(device: device),
                session.canAddInput(input)
            else {
                session.commitConfiguration()
                return
            }
            session.addInput(input)

            guard session.canAddOutput(output) else {
                session.commitConfiguration()
                return
            }
            session.addOutput(output)

            let want: [AVMetadataObject.ObjectType] = [
                .qr, .ean13, .ean8, .upce, .code128, .pdf417, .aztec, .dataMatrix,
            ]
            output.metadataObjectTypes = want.filter { output.availableMetadataObjectTypes.contains($0) }

            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            session.commitConfiguration()

            preview.attach(session: session)
            DispatchQueue.global(qos: .userInitiated).async {
                if !self.session.isRunning {
                    self.session.startRunning()
                }
            }
        }

        func stopSession() {
            session.stopRunning()
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let s = obj.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !s.isEmpty
            else { return }
            onFound(s, obj.type)
        }
    }

    final class PreviewView: UIView {
        private var previewLayer: AVCaptureVideoPreviewLayer?

        func attach(session: AVCaptureSession) {
            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            self.layer.addSublayer(layer)
            previewLayer = layer
            layoutIfNeeded()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer?.frame = bounds
        }
    }
}
