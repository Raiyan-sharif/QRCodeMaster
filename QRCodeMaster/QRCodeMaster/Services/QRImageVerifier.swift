//
//  QRImageVerifier.swift
//  QRCodeMaster
//

import CoreImage
import UIKit
import Vision

/// Decodes a **rendered** QR bitmap with Vision and compares the payload to what we intended to encode.
/// Uses several vision passes (orientation, upscale, high-contrast mono, Core Image detector, crops)
/// because styled QRs often fail a single raw `CGImage` decode even when real scanners can read them.
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
    private static let minUpscaleSidePixels: CGFloat = 1600

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

        let expected = expectedPayload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !expected.isEmpty else {
            return .failed("Expected payload is empty.")
        }

        let variants = buildVisionVariants(from: image)
        guard !variants.isEmpty else {
            return .failed("Image has no bitmap data.")
        }

        var mismatch: String?

        for variant in variants {
            let payloads = decodeAllQRPayloads(cgImage: variant.cgImage, orientation: variant.orientation)
            for decoded in payloads {
                let trimmed = decoded.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }
                if payloadsEquivalent(trimmed, expected) {
                    return .validMatchesContent
                }
                mismatch = trimmed
            }
        }

        if let mismatch {
            return .readablePayloadMismatch(found: mismatch)
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
        var seenKeys = Set<String>()

        func append(_ cg: CGImage, _ orientation: CGImagePropertyOrientation) {
            let key = "\(cg.width)x\(cg.height)-\(orientation.rawValue)"
            guard seenKeys.insert(key).inserted else { return }
            out.append(VisionVariant(cgImage: cg, orientation: orientation))
        }

        if let cg = image.cgImage {
            append(cg, cgImagePropertyOrientation(for: image.imageOrientation))
        }

        let flat = orientationNormalizedUIImage(image)
        guard let flatCG = flat.cgImage else { return out }

        append(flatCG, .up)

        let minSide = min(CGFloat(flatCG.width), CGFloat(flatCG.height))

        if let big = upscaledBitmap(flat, minSidePixels: minUpscaleSidePixels), let bigCG = big.cgImage {
            append(bigCG, .up)
        }

        for mono in [highContrastMonoBitmap(flat), sharpenedMonoBitmap(flat)] {
            if let mono, let cg = mono.cgImage {
                append(cg, .up)
            }
        }

        if minSide < minUpscaleSidePixels,
           let big = upscaledBitmap(flat, minSidePixels: minUpscaleSidePixels) {
            for mono in [highContrastMonoBitmap(big), sharpenedMonoBitmap(big)] {
                if let mono, let cg = mono.cgImage {
                    append(cg, .up)
                }
            }
        }

        // Core Image QR detector + optional crop-to-code retries.
        for crop in coreImageCroppedVariants(from: flat) {
            if let cg = crop.cgImage {
                append(cg, .up)
            }
        }

        return out
    }

    private static func decodeAllQRPayloads(
        cgImage: CGImage,
        orientation: CGImagePropertyOrientation
    ) -> [String] {
        var results: [String] = []

        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]
        request.revision = preferredBarcodeRevision()

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        if (try? handler.perform([request])) != nil {
            let observations = (request.results ?? []).compactMap { $0 as? VNBarcodeObservation }
                .filter { $0.symbology == .qr }
                .sorted { $0.confidence > $1.confidence }
            for obs in observations {
                if let payload = obs.payloadStringValue {
                    results.append(payload)
                }
            }
        }

        let ciImage = CIImage(cgImage: cgImage)
        let detector = CIDetector(
            ofType: CIDetectorTypeQRCode,
            context: ciContext,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        )
        let features = detector?.features(in: ciImage) as? [CIQRCodeFeature] ?? []
        for feature in features {
            if let message = feature.messageString {
                results.append(message)
            }
        }

        return results
    }

    private static func coreImageCroppedVariants(from image: UIImage) -> [UIImage] {
        guard let ciImage = CIImage(image: image) else { return [] }
        let detector = CIDetector(
            ofType: CIDetectorTypeQRCode,
            context: ciContext,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        )
        guard let features = detector?.features(in: ciImage) as? [CIQRCodeFeature], !features.isEmpty else {
            return []
        }

        var crops: [UIImage] = []
        let extent = ciImage.extent
        for feature in features {
            guard let crop = croppedImage(from: image, feature: feature, extent: extent) else { continue }
            crops.append(crop)
            if let padded = paddedCrop(crop, paddingFraction: 0.08) {
                crops.append(padded)
            }
        }
        return crops
    }

    private static func croppedImage(
        from image: UIImage,
        feature: CIQRCodeFeature,
        extent: CGRect
    ) -> UIImage? {
        let points = [feature.topLeft, feature.topRight, feature.bottomRight, feature.bottomLeft]
        let xs = points.map(\.x)
        let ys = points.map(\.y)
        guard let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max() else {
            return nil
        }

        // CIImage space is bottom-left origin; UIImage drawing uses top-left.
        let crop = CGRect(
            x: minX,
            y: extent.height - maxY,
            width: maxX - minX,
            height: maxY - minY
        ).integral

        guard crop.width > 8, crop.height > 8, let cg = image.cgImage,
              let sliced = cg.cropping(to: crop)
        else { return nil }

        return UIImage(cgImage: sliced, scale: 1, orientation: .up)
    }

    private static func paddedCrop(_ image: UIImage, paddingFraction: CGFloat) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        let w = CGFloat(cg.width)
        let h = CGFloat(cg.height)
        let padX = w * paddingFraction
        let padY = h * paddingFraction
        let crop = CGRect(x: -padX, y: -padY, width: w + padX * 2, height: h + padY * 2)
            .integral
        let canvas = CGSize(width: crop.width, height: crop.height)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: canvas, format: format).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: canvas))
            image.draw(in: CGRect(x: padX, y: padY, width: w, height: h))
        }
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
        if image.imageOrientation == .up, image.scale == 1 { return image }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: image.size))
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
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: nw, height: nh), format: format)
        return renderer.image { _ in
            UIColor.white.setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: nw, height: nh))
            image.draw(in: CGRect(x: 0, y: 0, width: nw, height: nh))
        }
    }

    private static func highContrastMonoBitmap(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        guard let filter = CIFilter(name: "CIColorControls") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(0.0, forKey: kCIInputSaturationKey)
        filter.setValue(1.55, forKey: kCIInputContrastKey)
        filter.setValue(0.05, forKey: kCIInputBrightnessKey)
        return bitmap(from: filter.outputImage)
    }

    private static func sharpenedMonoBitmap(_ image: UIImage) -> UIImage? {
        guard var ciImage = CIImage(image: image) else { return nil }
        if let controls = CIFilter(name: "CIColorControls") {
            controls.setValue(ciImage, forKey: kCIInputImageKey)
            controls.setValue(0.0, forKey: kCIInputSaturationKey)
            controls.setValue(1.25, forKey: kCIInputContrastKey)
            ciImage = controls.outputImage ?? ciImage
        }
        if let sharpen = CIFilter(name: "CISharpenLuminance") {
            sharpen.setValue(ciImage, forKey: kCIInputImageKey)
            sharpen.setValue(0.8, forKey: kCIInputSharpnessKey)
            ciImage = sharpen.outputImage ?? ciImage
        }
        return bitmap(from: ciImage)
    }

    private static func bitmap(from ciImage: CIImage?) -> UIImage? {
        guard let ciImage else { return nil }
        let extent = ciImage.extent.integral
        guard extent.width > 0, extent.height > 0,
              let cg = ciContext.createCGImage(ciImage, from: extent)
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
