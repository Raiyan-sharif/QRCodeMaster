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
        // Decorative template (sunset, ocean…) — full-canvas. Independent of brand background.
        let templateId  = options.backgroundTemplateId
        let hasTemplate = templateId.map { !$0.isEmpty && $0.lowercased() != "none" } ?? false
        // Brand colour background (brand_instagram…) — QR area only. Can coexist with decorative template.
        let brandId     = options.brandBackgroundId
        let hasBrand    = brandId.map { !$0.isEmpty && $0.lowercased() != "none" } ?? false

        let size = CGSize(width: outputPoints, height: outputPoints)
        let bounds = CGRect(origin: .zero, size: size)

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }

        // QR placement rect and module scale — computed before background drawing so we can
        // constrain the template gradient to the QR rect rather than the whole canvas.
        let moduleScale: CGFloat
        let qrRect: CGRect          // actual QR module area (logo centering, etc.)
        let matrixOrigin: CGPoint   // top-left pixel of module [0,0]

        // Use the inset "card" layout whenever either a decorative template or a brand
        // background is active — both benefit from the centred 72 % rect.
        let usesCardLayout = hasTemplate || hasBrand
        if usesCardLayout {
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

        // ── Step 1: Full-canvas background ──────────────────────────────────────
        // Priority: decorative template > white (if brand active) > solid bg colour
        if hasTemplate,
           let tpl = QRBackgroundTemplateCatalog.renderBackground(id: templateId, size: size) {
            tpl.draw(in: bounds)
        } else if hasBrand {
            // No template — use clean white so the brand card stands out on a neutral canvas.
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fill(bounds)
        } else {
            ctx.setFillColor(bg.cgColor)
            ctx.fill(bounds)
        }

        // ── Step 2: Brand icon — inner QR card area only ─────────────────────────
        // Renders exactly what is shown in the Color panel cell:
        //   • gradient fills the card background
        //   • brand logo mark drawn centred at ~25 % opacity so it shows through the QR gaps
        // Modules are painted on top of this in the user's chosen foreground colour.
        if hasBrand,
           let brand = QRBackgroundTemplateCatalog.brandItems.first(where: { $0.id == brandId }),
           let c1 = UIColor(hex: brand.startHex),
           let c2 = UIColor(hex: brand.endHex),
           let space = CGColorSpace(name: CGColorSpace.sRGB),
           let gradient = CGGradient(
               colorsSpace: space,
               colors: [c1.cgColor, c2.cgColor] as CFArray,
               locations: [0.0, 1.0]
           ) {
            ctx.saveGState()
            // Clip everything in this step to the rounded card rect
            let cardClip = UIBezierPath(roundedRect: qrRect, cornerRadius: qrRect.width * 0.05)
            ctx.addPath(cardClip.cgPath)
            ctx.clip()

            // 1 — gradient background
            ctx.drawLinearGradient(
                gradient,
                start: qrRect.origin,
                end: CGPoint(x: qrRect.maxX, y: qrRect.maxY),
                options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
            )

            // 2 — brand logo mark centred in the card at ~22 % opacity
            //     Uses the same SF Symbol the Color-panel cell shows.
            let iconPt  = qrRect.width * 0.55          // point size for the symbol
            let symConf = UIImage.SymbolConfiguration(pointSize: iconPt, weight: .bold)
            if let sym = UIImage(systemName: brand.sfSymbol, withConfiguration: symConf)?
                .withTintColor(.white, renderingMode: .alwaysOriginal) {
                // Scale to fill ~55 % of the card
                let iw = qrRect.width  * 0.55
                let ih = qrRect.height * 0.55
                let ir = CGRect(x: qrRect.midX - iw / 2,
                                y: qrRect.midY - ih / 2,
                                width: iw, height: ih)
                sym.draw(in: ir, blendMode: .normal, alpha: 0.22)
            }

            ctx.restoreGState()
        }

        let logoBackdrop: UIColor = usesCardLayout ? UIColor.white.withAlphaComponent(0.9) : bg

        // ── Draw data modules — skip the three 7×7 finder regions entirely ───────
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

        // ── Draw three complete finder-eye patterns as units ──────────────────────
        let finderOrigins = [
            CGPoint(x: matrixOrigin.x,                                y: matrixOrigin.y),
            CGPoint(x: matrixOrigin.x + CGFloat(n - 7) * moduleScale, y: matrixOrigin.y),
            CGPoint(x: matrixOrigin.x,                                y: matrixOrigin.y + CGFloat(n - 7) * moduleScale),
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

        // ── Original 4 ────────────────────────────────────────────────────────
        case .square:
            fillRing(ctx, outer: outer, void: middle, outerRadius: 0, voidRadius: 0, color: fg)
            fill(ctx, rect: inner, color: fg, radius: 0)

        case .roundedLeaf:
            let outerR  = size7 * 0.25
            let middleR = max(0, outerR - moduleScale)
            let innerR  = size3 * 0.35
            fillRing(ctx, outer: outer, void: middle, outerRadius: outerR, voidRadius: middleR, color: fg)
            fill(ctx, rect: inner, color: fg, radius: innerR)

        case .circle:
            fillEllipseRing(ctx, outer: outer, void: middle, color: fg)
            fillEllipse(ctx, rect: inner, color: fg)

        case .squareCircle:
            fillRing(ctx, outer: outer, void: middle, outerRadius: 0, voidRadius: 0, color: fg)
            fillEllipse(ctx, rect: inner, color: fg)

        // ── 8 New styles ──────────────────────────────────────────────────────
        case .circleSquare:
            // Circle outer ring + square inner fill
            fillEllipseRing(ctx, outer: outer, void: middle, color: fg)
            fill(ctx, rect: inner, color: fg, radius: 0)

        case .squareDiamond:
            // Square outer ring + diamond (45° rotated square) inner fill
            fillRing(ctx, outer: outer, void: middle, outerRadius: 0, voidRadius: 0, color: fg)
            fillDiamond(ctx, rect: inner, color: fg)

        case .diamond:
            // Diamond outer ring + diamond inner fill
            fillDiamondRing(ctx, outer: outer, void: middle, color: fg)
            fillDiamond(ctx, rect: inner, color: fg)

        case .roundedCircle:
            // Rounded outer ring + circle inner fill
            let outerR = size7 * 0.28
            let midR   = max(0, outerR - moduleScale)
            fillRing(ctx, outer: outer, void: middle, outerRadius: outerR, voidRadius: midR, color: fg)
            fillEllipse(ctx, rect: inner, color: fg)

        case .squareRounded:
            // Square outer ring + heavily rounded inner (pill-like)
            fillRing(ctx, outer: outer, void: middle, outerRadius: 0, voidRadius: 0, color: fg)
            fill(ctx, rect: inner, color: fg, radius: size3 * 0.45)

        case .circleRound:
            // Circle outer ring + rounded-square inner
            fillEllipseRing(ctx, outer: outer, void: middle, color: fg)
            fill(ctx, rect: inner, color: fg, radius: size3 * 0.28)

        case .concentric:
            // Two concentric circle rings — no filled centre
            fillEllipseRing(ctx, outer: outer, void: middle, color: fg)
            // Inner ring: draw the 3×3 inner rect as a ring with a small void
            let innerVoid = inner.insetBy(dx: moduleScale * 0.5, dy: moduleScale * 0.5)
            fillEllipseRing(ctx, outer: inner, void: innerVoid, color: fg)

        case .roundedDiamond:
            // Rounded outer ring + diamond inner fill
            let outerR2 = size7 * 0.28
            let midR2   = max(0, outerR2 - moduleScale)
            fillRing(ctx, outer: outer, void: middle, outerRadius: outerR2, voidRadius: midR2, color: fg)
            fillDiamond(ctx, rect: inner, color: fg)
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

    // MARK: - Diamond helpers

    /// Returns a UIBezierPath diamond (axis-aligned rhombus) that fits inside `rect`.
    private static func diamondBezierPath(rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to:    CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.close()
        return path
    }

    /// Fills a solid diamond shape.
    private static func fillDiamond(_ ctx: CGContext, rect: CGRect, color: UIColor) {
        ctx.saveGState()
        ctx.setFillColor(color.cgColor)
        ctx.addPath(diamondBezierPath(rect: rect).cgPath)
        ctx.fillPath()
        ctx.restoreGState()
    }

    /// Fills a diamond ring (outer diamond minus inner diamond void, even-odd).
    private static func fillDiamondRing(_ ctx: CGContext, outer: CGRect, void voidRect: CGRect, color: UIColor) {
        let outerPath = diamondBezierPath(rect: outer)
        let voidPath  = diamondBezierPath(rect: voidRect)
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
