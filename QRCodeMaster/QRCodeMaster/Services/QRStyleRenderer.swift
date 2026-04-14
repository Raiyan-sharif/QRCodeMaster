//
//  QRStyleRenderer.swift
//  QRCodeMaster
//

import CoreGraphics
import CoreImage
import UIKit

enum QRStyleRenderer {
    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    /// Share of the export square used by the QR matrix when a template is active.
    private static let templateQRRelativeSide: CGFloat = 0.72

    // MARK: - Public

    static func render(
        message: String,
        options: QRStyleOptions,
        logo: UIImage?,
        outputPoints: CGFloat = 512,
        showWatermark: Bool
    ) -> UIImage? {
        // Extract the module matrix at NATIVE QR resolution (1 pixel per module).
        // DO NOT scale before matrix extraction — scaling makes count = outputPoints
        // instead of the real module count, which breaks the finder-region guard
        // and causes eye styles to be ignored entirely.
        guard
            let ci = QRGeneratorService.makeCIQRCode(message: message, correctionLevel: options.errorCorrection),
            let tuple = QRGeneratorService.moduleMatrix(from: ci, context: context)
        else { return nil }

        let matrix = tuple.matrix
        let n = tuple.count
        guard n > 0 else { return nil }

        let fg = options.foregroundUIColor()
        let bg = options.backgroundUIColor()
        let templateId = options.backgroundTemplateId
        let hasTemplate = templateId.map { !$0.isEmpty && $0.lowercased() != "none" } ?? false

        let size = CGSize(width: outputPoints, height: outputPoints)
        let bounds = CGRect(origin: .zero, size: size)

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }

        // Background / template
        if hasTemplate, let tpl = QRBackgroundTemplateCatalog.renderBackground(id: templateId, size: size) {
            tpl.draw(in: bounds)
        } else {
            ctx.setFillColor(bg.cgColor)
            ctx.fill(bounds)
        }

        // QR placement rect and module scale.
        // For non-template rendering we add a 2-module quiet zone on every side so that
        // finder patterns never touch the canvas edge and never visually merge with
        // adjacent dark timing/data modules.
        let moduleScale: CGFloat
        let qrRect: CGRect          // actual QR module area (logo centering, etc.)
        let matrixOrigin: CGPoint   // top-left pixel of module [0,0]

        if hasTemplate {
            let side = min(bounds.width, bounds.height) * Self.templateQRRelativeSide
            qrRect       = CGRect(x: bounds.midX - side / 2, y: bounds.midY - side / 2,
                                  width: side, height: side)
            moduleScale  = side / CGFloat(n)
            matrixOrigin = qrRect.origin
        } else {
            let quietZone   = 2                                    // modules of white border each side
            moduleScale     = outputPoints / CGFloat(n + quietZone * 2)
            let qrOffset    = CGFloat(quietZone) * moduleScale
            qrRect          = CGRect(x: qrOffset, y: qrOffset,
                                     width: CGFloat(n) * moduleScale,
                                     height: CGFloat(n) * moduleScale)
            matrixOrigin    = qrRect.origin
        }

        let logoBackdrop = hasTemplate ? UIColor.white.withAlphaComponent(0.9) : bg

        // Draw data modules — skip the three 7×7 finder regions entirely.
        for r in 0..<n {
            for c in 0..<n {
                guard matrix[r][c] else { continue }
                guard !Self.isFinderRegion(row: r, col: c, count: n) else { continue }
                let rect = CGRect(
                    x: matrixOrigin.x + CGFloat(c) * moduleScale,
                    y: matrixOrigin.y + CGFloat(r) * moduleScale,
                    width: moduleScale,
                    height: moduleScale
                )
                drawDataModule(in: rect, context: ctx, color: fg, shape: options.moduleShape)
            }
        }

        // Draw three complete finder-eye patterns as units.
        let finderOrigins = [
            CGPoint(x: matrixOrigin.x,                                y: matrixOrigin.y),                                // TL
            CGPoint(x: matrixOrigin.x + CGFloat(n - 7) * moduleScale, y: matrixOrigin.y),                                // TR
            CGPoint(x: matrixOrigin.x,                                y: matrixOrigin.y + CGFloat(n - 7) * moduleScale), // BL
        ]
        for origin in finderOrigins {
            drawFinderPattern(at: origin, moduleScale: moduleScale,
                              context: ctx, fg: fg, eye: options.eyeStyle)
        }

        // Logo overlay
        if let logo {
            compositeLogo(logo, maxRelative: options.logoMaxRelativeSize, placementRect: qrRect, context: ctx, background: logoBackdrop)
        }

        // Watermark
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

        let framed = applyFrameIfNeeded(to: ui, frameId: options.frameId, fg: fg)
        return applyCaption(to: framed, options: options)
    }

    // MARK: - Module drawing

    private static func drawDataModule(in rect: CGRect, context ctx: CGContext, color: UIColor, shape: QRStyleOptions.ModuleShape) {
        ctx.setFillColor(color.cgColor)
        switch shape {
        case .square:
            ctx.fill(rect)
        case .rounded:
            let path = UIBezierPath(roundedRect: rect.insetBy(dx: rect.width * 0.05, dy: rect.height * 0.05),
                                    cornerRadius: rect.width * 0.35).cgPath
            ctx.addPath(path); ctx.fillPath()
        case .dot:
            let d = min(rect.width, rect.height) * 0.78
            ctx.fillEllipse(in: CGRect(x: rect.midX - d / 2, y: rect.midY - d / 2, width: d, height: d))
        case .diamond:
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let half = min(rect.width, rect.height) * 0.42
            let path = CGMutablePath()
            path.move(to: CGPoint(x: center.x, y: center.y - half))
            path.addLine(to: CGPoint(x: center.x + half, y: center.y))
            path.addLine(to: CGPoint(x: center.x, y: center.y + half))
            path.addLine(to: CGPoint(x: center.x - half, y: center.y))
            path.closeSubpath()
            ctx.addPath(path); ctx.fillPath()
        }
    }

    // MARK: - Finder eye (complete unit, not module-by-module)

    /// Draws one complete 7×7 finder pattern as a styled unit.
    /// The void ring is rendered as a transparent hole (even-odd path) so whatever
    /// background — solid colour or template image — shows through naturally.
    /// `origin` is the top-left corner of the 7×7 block in canvas coordinates.
    private static func drawFinderPattern(
        at origin: CGPoint,
        moduleScale: CGFloat,
        context ctx: CGContext,
        fg: UIColor,
        eye: QRStyleOptions.EyeStyle
    ) {
        let size7  = moduleScale * 7
        let size5  = moduleScale * 5
        let size3  = moduleScale * 3
        let inset1 = moduleScale
        let inset2 = moduleScale * 2

        let outer  = CGRect(x: origin.x,          y: origin.y,          width: size7, height: size7)
        let middle = CGRect(x: origin.x + inset1, y: origin.y + inset1, width: size5, height: size5)
        let inner  = CGRect(x: origin.x + inset2, y: origin.y + inset2, width: size3, height: size3)

        switch eye {
        case .square:
            // Ring = outer rect with rectangular hole punched through (even-odd fill)
            fillRing(ctx, outer: outer, void: middle, outerRadius: 0, voidRadius: 0, color: fg)
            fill(ctx, rect: inner, color: fg, radius: 0)

        case .roundedLeaf:
            let outerR  = size7 * 0.25
            let middleR = max(0, outerR - moduleScale)
            let innerR  = size3 * 0.35
            fillRing(ctx, outer: outer, void: middle, outerRadius: outerR, voidRadius: middleR, color: fg)
            fill(ctx, rect: inner, color: fg, radius: innerR)

        case .circle:
            // Elliptical ring
            fillEllipseRing(ctx, outer: outer, void: middle, color: fg)
            fillEllipse(ctx, rect: inner, color: fg)

        case .squareCircle:
            fillRing(ctx, outer: outer, void: middle, outerRadius: 0, voidRadius: 0, color: fg)
            fillEllipse(ctx, rect: inner, color: fg)
        }
    }

    /// Draws a filled ring by subtracting the void shape from the outer shape using
    /// the even-odd winding rule, leaving the void area completely unpainted so the
    /// background (solid colour or template) shows through without any white layer.
    private static func fillRing(
        _ ctx: CGContext,
        outer: CGRect, void: CGRect,
        outerRadius: CGFloat, voidRadius: CGFloat,
        color: UIColor
    ) {
        let outerPath = outerRadius > 0
            ? UIBezierPath(roundedRect: outer, cornerRadius: outerRadius)
            : UIBezierPath(rect: outer)
        let voidPath = voidRadius > 0
            ? UIBezierPath(roundedRect: void, cornerRadius: voidRadius)
            : UIBezierPath(rect: void)
        outerPath.append(voidPath)
        outerPath.usesEvenOddFillRule = true

        ctx.saveGState()
        ctx.setFillColor(color.cgColor)
        ctx.addPath(outerPath.cgPath)
        ctx.fillPath(using: .evenOdd)
        ctx.restoreGState()
    }

    /// Same as `fillRing` but for elliptical (circular) finder styles.
    private static func fillEllipseRing(
        _ ctx: CGContext,
        outer: CGRect, void: CGRect,
        color: UIColor
    ) {
        let outerPath = UIBezierPath(ovalIn: outer)
        let voidPath  = UIBezierPath(ovalIn: void)
        outerPath.append(voidPath)
        outerPath.usesEvenOddFillRule = true

        ctx.saveGState()
        ctx.setFillColor(color.cgColor)
        ctx.addPath(outerPath.cgPath)
        ctx.fillPath(using: .evenOdd)
        ctx.restoreGState()
    }

    // MARK: - Finder geometry helpers

    private static func isFinderRegion(row: Int, col: Int, count: Int) -> Bool {
        (row < 7 && col < 7) || (row < 7 && col >= count - 7) || (row >= count - 7 && col < 7)
    }

    // MARK: - Low-level draw helpers

    private static func fill(_ ctx: CGContext, rect: CGRect, color: UIColor, radius: CGFloat) {
        ctx.setFillColor(color.cgColor)
        if radius > 0 {
            let path = UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath
            ctx.addPath(path)
            ctx.fillPath()
        } else {
            ctx.fill(rect)
        }
    }

    private static func fillEllipse(_ ctx: CGContext, rect: CGRect, color: UIColor) {
        ctx.setFillColor(color.cgColor)
        ctx.fillEllipse(in: rect)
    }

    // MARK: - Logo

    private static func compositeLogo(
        _ logo: UIImage,
        maxRelative: Double,
        placementRect: CGRect,
        context ctx: CGContext,
        background: UIColor
    ) {
        let size = placementRect.size
        let maxSide = min(size.width, size.height) * CGFloat(max(0.08, min(0.35, maxRelative)))
        let lw = logo.size.width; let lh = logo.size.height
        guard lw > 0, lh > 0 else { return }
        let aspect = lw / lh
        let box: CGSize = aspect >= 1
            ? CGSize(width: maxSide, height: maxSide / aspect)
            : CGSize(width: maxSide * aspect, height: maxSide)
        let origin = CGPoint(x: placementRect.midX - box.width / 2, y: placementRect.midY - box.height / 2)
        let logoRect = CGRect(origin: origin, size: box)
        let pad = maxSide * 0.12
        let bgRect = logoRect.insetBy(dx: -pad, dy: -pad)

        ctx.setFillColor(background.cgColor)
        ctx.setStrokeColor(UIColor.black.withAlphaComponent(0.08).cgColor)
        ctx.setLineWidth(max(1, maxSide * 0.02))
        let path = UIBezierPath(roundedRect: bgRect, cornerRadius: maxSide * 0.12).cgPath
        ctx.addPath(path); ctx.fillPath()
        ctx.addPath(path); ctx.strokePath()
        logo.draw(in: logoRect)
    }

    // MARK: - Frame

    private static func applyFrameIfNeeded(to image: UIImage, frameId: String?, fg: UIColor) -> UIImage {
        guard let frameId, !frameId.isEmpty else { return image }
        let pad: CGFloat = 28
        let sz = CGSize(width: image.size.width + pad * 2, height: image.size.height + pad * 2)
        UIGraphicsBeginImageContextWithOptions(sz, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        guard let c = UIGraphicsGetCurrentContext() else { return image }
        c.setFillColor(UIColor.secondarySystemBackground.cgColor); c.fill(CGRect(origin: .zero, size: sz))
        let border = UIBezierPath(roundedRect: CGRect(x: 8, y: 8, width: sz.width - 16, height: sz.height - 16), cornerRadius: 16)
        c.setStrokeColor(fg.withAlphaComponent(0.25).cgColor); c.setLineWidth(4)
        c.addPath(border.cgPath); c.strokePath()
        image.draw(at: CGPoint(x: pad, y: pad))
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }

    // MARK: - Caption

    private static func applyCaption(to image: UIImage, options: QRStyleOptions) -> UIImage {
        let caption = options.captionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !caption.isEmpty else { return image }

        let font = UIFont.systemFont(ofSize: max(14, image.size.width * 0.05), weight: .medium)
        let captionColor = UIColor(hex: options.captionColorHex) ?? .black
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: captionColor]
        let textSize = (caption as NSString).size(withAttributes: attrs)
        let vPad: CGFloat = max(10, image.size.height * 0.025)
        let textAreaH = textSize.height + vPad * 2

        let totalSize = CGSize(width: image.size.width, height: image.size.height + textAreaH)
        UIGraphicsBeginImageContextWithOptions(totalSize, false, image.scale)
        defer { UIGraphicsEndImageContext() }

        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: totalSize))
        image.draw(at: .zero)

        let tx = (image.size.width - textSize.width) / 2
        let ty = image.size.height + vPad
        (caption as NSString).draw(at: CGPoint(x: tx, y: ty), withAttributes: attrs)

        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }

}
