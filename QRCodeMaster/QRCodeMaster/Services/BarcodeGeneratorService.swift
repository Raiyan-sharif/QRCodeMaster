//
//  BarcodeGeneratorService.swift
//  QRCodeMaster
//

import CoreImage
import UIKit

enum BarcodeGeneratorService {
    private static let ciContext = CIContext(options: nil)

    static func code128(
        _ text: String,
        maxWidth: CGFloat = 400,
        height: CGFloat = 120,
        barColor: UIColor = .black,
        background: UIColor = .white
    ) -> UIImage? {
        guard let data = text.data(using: .utf8),
              let filter = CIFilter(name: "CICode128BarcodeGenerator")
        else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue(12.0, forKey: "inputQuietSpace")
        guard let out = filter.outputImage else { return nil }

        let scaleX = maxWidth / out.extent.width
        let scaled = out.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleX))
        guard let cg = ciContext.createCGImage(scaled, from: scaled.extent.integral) else { return nil }

        let img = UIImage(cgImage: cg)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: maxWidth, height: height), true, 0)
        defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        ctx.setFillColor(background.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: maxWidth, height: height))
        img.draw(in: CGRect(x: 0, y: 0, width: maxWidth, height: height * 0.82))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    /// UPC-A (11 digits + auto check, or 12 with verify) — drawn as EAN-13 with leading 0.
    static func upcA(
        digits: String,
        maxWidth: CGFloat = 400,
        height: CGFloat = 120,
        barColor: UIColor = .black,
        background: UIColor = .white
    ) -> UIImage? {
        let n = digits.filter(\.isNumber)
        guard n.count == 11 || n.count == 12 else { return nil }
        let body11: String
        if n.count == 12 {
            body11 = String(n.prefix(11))
            guard let last = Int(String(n.last!)), last == EAN13Encoder.computeCheckDigit(body11) else { return nil }
        } else {
            body11 = n
        }
        let check = EAN13Encoder.computeCheckDigit(body11)
        let ean13 = "0" + body11 + String(check)
        return EAN13Encoder.image(digits: ean13, height: height, maxWidth: maxWidth, barColor: barColor, background: background)
    }
}
