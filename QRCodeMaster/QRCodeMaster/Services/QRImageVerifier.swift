//
//  QRImageVerifier.swift
//  QRCodeMaster
//

import UIKit
import Vision

/// Decodes a **rendered** QR bitmap with Vision and compares the payload to what we intended to encode.
enum QRImageVerifier {

    enum Outcome: Equatable, Sendable {
        case idle
        case verifying
        /// Vision read a QR and its string equals the expected payload (after trim / simple URL normalize).
        case validMatchesContent
        /// A QR was read but the string differs (still a valid QR image).
        case readablePayloadMismatch(found: String)
        /// No QR symbology decoded from the image (styling may be too aggressive for Vision).
        case couldNotReadFromImage
        case failed(String)
    }

    /// Runs Vision off the main actor so the UI stays responsive.
    static func verify(image: UIImage, expectedPayload: String) async -> Outcome {
        await Task.detached(priority: .userInitiated) {
            verifySync(image: image, expectedPayload: expectedPayload)
        }.value
    }

    private static func verifySync(image: UIImage, expectedPayload: String) -> Outcome {
        guard let cgImage = image.cgImage else {
            return .failed("Image has no bitmap data.")
        }

        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return .failed(error.localizedDescription)
        }

        let observations = (request.results ?? []).compactMap { $0 as? VNBarcodeObservation }
            .filter { $0.symbology == .qr }

        guard let best = observations.max(by: { $0.confidence < $1.confidence }),
              let decoded = best.payloadStringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !decoded.isEmpty
        else {
            return .couldNotReadFromImage
        }

        let expected = expectedPayload.trimmingCharacters(in: .whitespacesAndNewlines)
        if payloadsEquivalent(decoded, expected) {
            return .validMatchesContent
        }
        return .readablePayloadMismatch(found: decoded)
    }

    /// Trim + NFC; URLs compared case-insensitively on full string.
    private static func payloadsEquivalent(_ a: String, _ b: String) -> Bool {
        let x = a.trimmingCharacters(in: .whitespacesAndNewlines)
            .precomposedStringWithCanonicalMapping
        let y = b.trimmingCharacters(in: .whitespacesAndNewlines)
            .precomposedStringWithCanonicalMapping
        if x == y { return true }

        if let ux = URL(string: x), let uy = URL(string: y) {
            return ux.absoluteString.lowercased() == uy.absoluteString.lowercased()
        }

        return x.lowercased() == y.lowercased()
    }
}
