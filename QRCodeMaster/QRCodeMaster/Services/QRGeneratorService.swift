//
//  QRGeneratorService.swift
//  QRCodeMaster
//

import CoreImage
import UIKit

enum QRGeneratorService {
    /// Raw QR `CIImage` (black on clear/extent), before styling.
    static func makeCIQRCode(message: String, correctionLevel: String) -> CIImage? {
        guard let data = message.data(using: .utf8) else { return nil }
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue(correctionLevel, forKey: "inputCorrectionLevel")
        return filter.outputImage
    }

    /// Bitmap matrix: `true` = dark module. Size `count` × `count`.
    static func moduleMatrix(from qr: CIImage, context: CIContext) -> (matrix: [[Bool]], count: Int)? {
        guard let cg = context.createCGImage(qr, from: qr.extent.integral) else { return nil }
        let w = cg.width
        let h = cg.height
        guard w == h, w > 0 else { return nil }

        let count = w
        guard let data = pixelData(from: cg) else { return nil }

        var matrix: [[Bool]] = []
        matrix.reserveCapacity(count)
        for y in 0..<count {
            var row: [Bool] = []
            row.reserveCapacity(count)
            for x in 0..<count {
                let i = (y * w + x) * 4
                let r = Double(data[i])
                let g = Double(data[i + 1])
                let b = Double(data[i + 2])
                let lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255
                row.append(lum < 0.5)
            }
            matrix.append(row)
        }
        return (matrix, count)
    }

    private static func pixelData(from cgImage: CGImage) -> [UInt8]? {
        let w = cgImage.width
        let h = cgImage.height
        let bpp = 4
        let count = w * h * bpp
        var buffer = [UInt8](repeating: 0, count: count)
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(
                data: &buffer,
                width: w,
                height: h,
                bitsPerComponent: 8,
                bytesPerRow: w * bpp,
                space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              )
        else { return nil }
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
        return buffer
    }
}
