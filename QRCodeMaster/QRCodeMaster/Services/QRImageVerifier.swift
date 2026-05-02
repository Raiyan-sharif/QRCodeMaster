//
//  QRImageVerifier.swift
//  QRCodeMaster
//

import CoreImage
import UIKit
import Vision

/// Decodes a **rendered** QR bitmap with Vision and compares the payload to what we intended to encode.
/// Uses several vision passes (orientation, upscale, high-contrast mono) because styled QRs often
/// fail a single raw `CGImage` decode even when real scanners can read them.
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

    private static let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    /// Minimum shortest edge in **pixels** for the upscaled pass (Vision is much more reliable with enough resolution).
    private static let minUpscaleSidePixels: CGFloat = 1200

    /// Runs Vision off the main actor so the UI stays responsive.
    static func verify(image: UIImage, expectedPayload: String) async -> Outcome {
        await Task.detached(priority: .userInitiated) {
            verifySync(image: image, expectedPayload: expectedPayload)
        }.value
    }

    private static func verifySync(image: UIImage, expectedPayload: String) -> Outcome {
        guard image.cgImage != nil else {
            return .failed("Image has no bitmap data.")
        }

        let variants = buildVisionVariants(from: image)
        guard !variants.isEmpty else {
            return .failed("Image has no bitmap data.")
        }

        for variant in variants {
            guard let decoded = decodeQRPayload(cgImage: variant.cgImage, orientation: variant.orientation) else {
                continue
            }
            let trimmed = decoded.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let expected = expectedPayload.trimmingCharacters(in: .whitespacesAndNewlines)
            if payloadsEquivalent(trimmed, expected) {
                return .validMatchesContent
            }
            return .readablePayloadMismatch(found: trimmed)
        }

        return .couldNotReadFromImage
    }

    private struct VisionVariant {
        let cgImage: CGImage
        let orientation: CGImagePropertyOrientation
    }

    /// Builds several bitmaps Vision can succeed on: EXIF orientation, upscale, and boosted contrast.
    private static func buildVisionVariants(from image: UIImage) -> [VisionVariant] {
        var out: [VisionVariant] = []

        // 1) Raw buffer + explicit UIImage orientation (Vision ignores UIImage.orientation on `cgImage` alone).
        if let cg = image.cgImage {
            out.append(
                VisionVariant(
                    cgImage: cg,
                    orientation: cgImagePropertyOrientation(for: image.imageOrientation)
                )
            )
        }

        // 2+) Normalized “as displayed” bitmap, then derivative passes (all `.up`).
        let flat = orientationNormalizedUIImage(image)
        guard let flatCG = flat.cgImage else { return out }

        out.append(VisionVariant(cgImage: flatCG, orientation: .up))

        let minSide = min(CGFloat(flatCG.width), CGFloat(flatCG.height))
        if minSide < minUpscaleSidePixels, let big = upscaledBitmap(flat, minSidePixels: minUpscaleSidePixels),
           let bigCG = big.cgImage {
            out.append(VisionVariant(cgImage: bigCG, orientation: .up))
        }

        if let hi = highContrastMonoBitmap(flat), let hiCG = hi.cgImage {
            out.append(VisionVariant(cgImage: hiCG, orientation: .up))
        }

        if minSide < minUpscaleSidePixels,
           let big = upscaledBitmap(flat, minSidePixels: minUpscaleSidePixels),
           let hi = highContrastMonoBitmap(big),
           let hiCG = hi.cgImage {
            out.append(VisionVariant(cgImage: hiCG, orientation: .up))
        }

        return out
    }

    private static func decodeQRPayload(cgImage: CGImage, orientation: CGImagePropertyOrientation) -> String? {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]
        request.revision = preferredBarcodeRevision()

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return nil
        }

        let observations = (request.results ?? []).compactMap { $0 as? VNBarcodeObservation }
            .filter { $0.symbology == .qr }

        guard let best = observations.max(by: { $0.confidence < $1.confidence }),
              let payload = best.payloadStringValue
        else {
            return nil
        }
        return payload
    }

    private static func preferredBarcodeRevision() -> Int {
        (VNDetectBarcodesRequest.supportedRevisions as IndexSet).max() ?? 1
    }

    private static func cgImagePropertyOrientation(for ui: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch ui {
        case .up:            return .up
        case .down:          return .down
        case .left:          return .left
        case .right:         return .right
        case .upMirrored:    return .upMirrored
        case .downMirrored:  return .downMirrored
        case .leftMirrored:  return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default:   return .up
        }
    }

    /// Draws through `UIImage` so pixel data matches what the user sees (fixes non-`.up` orientations).
    private static func orientationNormalizedUIImage(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up { return image }
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    private static func upscaledBitmap(_ image: UIImage, minSidePixels: CGFloat) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        let w = CGFloat(cg.width)
        let h = CGFloat(cg.height)
        let minSide = min(w, h)
        guard minSide > 0 else { return nil }
        if minSide >= minSidePixels { return image }

        let scale = minSidePixels / minSide
        let nw = max(1, floor(w * scale))
        let nh = max(1, floor(h * scale))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: nw, height: nh), format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(x: 0, y: 0, width: nw, height: nh))
        }
    }

    private static func highContrastMonoBitmap(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        guard let filter = CIFilter(name: "CIColorControls") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(0.0, forKey: kCIInputSaturationKey)
        filter.setValue(1.35, forKey: kCIInputContrastKey)
        filter.setValue(0.03, forKey: kCIInputBrightnessKey)
        guard let output = filter.outputImage else { return nil }
        let extent = output.extent.integral
        guard extent.width > 0, extent.height > 0,
              let cg = ciContext.createCGImage(output, from: extent)
        else { return nil }
        return UIImage(cgImage: cg, scale: 1, orientation: .up)
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
