//
//  QRStyleRenderer.swift
//  QRCodeMaster
//

import CoreGraphics
import CoreImage
import UIKit

enum QRStyleRenderer {
    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    static func render(
        message: String,
        options: QRStyleOptions,
        logo: UIImage?,
        outputPoints: CGFloat = 512,
        showWatermark: Bool
    ) -> UIImage? {
        guard let ci = QRGeneratorService.makeCIQRCode(message: message, correctionLevel: options.errorCorrection),
              let scaled = scale(ci, toPixelWidth: Int(outputPoints)),
              let tuple = QRGeneratorService.moduleMatrix(from: scaled, context: context)
        else { return nil }

        let matrix = tuple.matrix
        let n = tuple.count
        guard n > 0 else { return nil }

        let fg = options.foregroundUIColor()
        let bg = options.backgroundUIColor()

        let scale = outputPoints / CGFloat(n)
        let size = CGSize(width: outputPoints, height: outputPoints)

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }

        ctx.setFillColor(bg.cgColor)
        ctx.fill(CGRect(origin: .zero, size: size))

        for r in 0..<n {
            for c in 0..<n {
                guard matrix[r][c] else { continue }
                let rect = CGRect(x: CGFloat(c) * scale, y: CGFloat(r) * scale, width: scale, height: scale)
                let inFinder = Self.isFinderRegion(row: r, col: c, count: n)
                if inFinder {
                    drawFinderModule(in: rect, context: ctx, color: fg, eye: options.eyeStyle, module: options.moduleShape)
                } else {
                    drawDataModule(in: rect, context: ctx, color: fg, shape: options.moduleShape)
                }
            }
        }

        if let logo {
            compositeLogo(logo, maxRelative: options.logoMaxRelativeSize, in: size, context: ctx, background: bg)
        }

        if showWatermark {
            let text = "QRCodeMaster" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: max(10, outputPoints * 0.028), weight: .medium),
                .foregroundColor: fg.withAlphaComponent(0.35),
            ]
            let tsize = text.size(withAttributes: attrs)
            text.draw(
                at: CGPoint(x: (outputPoints - tsize.width) / 2, y: outputPoints - tsize.height - outputPoints * 0.02),
                withAttributes: attrs
            )
        }

        guard let composed = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else { return nil }
        let ui = UIImage(cgImage: composed, scale: UIScreen.main.scale, orientation: .up)

        return applyFrameIfNeeded(to: ui, frameId: options.frameId, fg: fg)
    }

    private static func scale(_ image: CIImage, toPixelWidth width: Int) -> CIImage? {
        let e = image.extent.integral
        guard e.width > 0 else { return nil }
        let s = CGFloat(width) / e.width
        return image.transformed(by: CGAffineTransform(scaleX: s, y: s))
    }

    private static func isFinderRegion(row: Int, col: Int, count: Int) -> Bool {
        (row < 7 && col < 7) || (row < 7 && col >= count - 7) || (row >= count - 7 && col < 7)
    }

    private static func drawDataModule(in rect: CGRect, context ctx: CGContext, color: UIColor, shape: QRStyleOptions.ModuleShape) {
        ctx.setFillColor(color.cgColor)
        switch shape {
        case .square:
            ctx.fill(rect)
        case .rounded:
            let r = rect.width * 0.35
            let path = UIBezierPath(roundedRect: rect.insetBy(dx: rect.width * 0.05, dy: rect.height * 0.05), cornerRadius: r).cgPath
            ctx.addPath(path)
            ctx.fillPath()
        case .dot:
            let d = min(rect.width, rect.height) * 0.78
            let o = CGRect(
                x: rect.midX - d / 2,
                y: rect.midY - d / 2,
                width: d,
                height: d
            )
            ctx.fillEllipse(in: o)
        }
    }

    private static func drawFinderModule(
        in rect: CGRect,
        context ctx: CGContext,
        color: UIColor,
        eye: QRStyleOptions.EyeStyle,
        module: QRStyleOptions.ModuleShape
    ) {
        switch eye {
        case .square:
            drawDataModule(in: rect, context: ctx, color: color, shape: module)
        case .roundedLeaf:
            ctx.setFillColor(color.cgColor)
            let inset = rect.insetBy(dx: rect.width * 0.06, dy: rect.height * 0.06)
            let path = UIBezierPath(roundedRect: inset, cornerRadius: rect.width * 0.42).cgPath
            ctx.addPath(path)
            ctx.fillPath()
        case .circle:
            ctx.setFillColor(color.cgColor)
            let d = min(rect.width, rect.height) * 0.88
            let o = CGRect(x: rect.midX - d / 2, y: rect.midY - d / 2, width: d, height: d)
            ctx.fillEllipse(in: o)
        }
    }

    private static func compositeLogo(
        _ logo: UIImage,
        maxRelative: Double,
        in size: CGSize,
        context ctx: CGContext,
        background: UIColor
    ) {
        let maxSide = min(size.width, size.height) * CGFloat(max(0.08, min(0.35, maxRelative)))
        let lw = logo.size.width
        let lh = logo.size.height
        guard lw > 0, lh > 0 else { return }
        let aspect = lw / lh
        let box: CGSize = aspect >= 1
            ? CGSize(width: maxSide, height: maxSide / aspect)
            : CGSize(width: maxSide * aspect, height: maxSide)

        let origin = CGPoint(x: (size.width - box.width) / 2, y: (size.height - box.height) / 2)
        let logoRect = CGRect(origin: origin, size: box)
        let pad = maxSide * 0.12
        let bgRect = logoRect.insetBy(dx: -pad, dy: -pad)

        ctx.setFillColor(background.cgColor)
        ctx.setStrokeColor(UIColor.black.withAlphaComponent(0.08).cgColor)
        ctx.setLineWidth(max(1, maxSide * 0.02))
        let path = UIBezierPath(roundedRect: bgRect, cornerRadius: maxSide * 0.12).cgPath
        ctx.addPath(path)
        ctx.fillPath()
        ctx.addPath(path)
        ctx.strokePath()

        logo.draw(in: logoRect)
    }

    private static func applyFrameIfNeeded(to image: UIImage, frameId: String?, fg: UIColor) -> UIImage {
        guard let frameId, !frameId.isEmpty else { return image }
        let pad: CGFloat = 28
        let sz = CGSize(width: image.size.width + pad * 2, height: image.size.height + pad * 2)
        UIGraphicsBeginImageContextWithOptions(sz, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        guard let c = UIGraphicsGetCurrentContext() else { return image }

        c.setFillColor(UIColor.secondarySystemBackground.cgColor)
        c.fill(CGRect(origin: .zero, size: sz))

        let border = UIBezierPath(roundedRect: CGRect(x: 8, y: 8, width: sz.width - 16, height: sz.height - 16), cornerRadius: 16)
        c.setStrokeColor(fg.withAlphaComponent(0.25).cgColor)
        c.setLineWidth(4)
        c.addPath(border.cgPath)
        c.strokePath()

        image.draw(at: CGPoint(x: pad, y: pad))
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
}
