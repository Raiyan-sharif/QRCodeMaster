//
//  QRBackgroundTemplateCatalog.swift
//  QRCodeMaster
//

import CoreGraphics
import UIKit

/// Built-in decorative backgrounds for QR export (generated at render time — no bundled bitmaps required).
enum QRBackgroundTemplateCatalog {
    struct Item: Identifiable, Hashable, Sendable {
        let id: String
        let title: String
    }

    /// Brand-themed background template shown in the Color › Background picker.
    struct BrandItem: Identifiable, Hashable, Sendable {
        let id: String          // used as backgroundTemplateId
        let name: String
        let sfSymbol: String    // SF Symbol for the preview icon
        let startHex: String    // gradient top-left colour
        let endHex: String      // gradient bottom-right colour
        var iconIsDark: Bool = false // true when background is light (Snapchat yellow)
    }

    static let items: [Item] = [
        Item(id: "none",     title: "None"),
        Item(id: "sunset",   title: "Sunset"),
        Item(id: "ocean",    title: "Ocean"),
        Item(id: "forest",   title: "Forest"),
        Item(id: "paper",    title: "Paper"),
        Item(id: "grid",     title: "Soft grid"),
        Item(id: "dots",     title: "Dots"),
        Item(id: "midnight", title: "Midnight"),
        Item(id: "aurora",   title: "Aurora"),
    ]

    /// Brand-image backgrounds shown in Color › Background › Image section.
    static let brandItems: [BrandItem] = [
        .init(id: "brand_instagram", name: "Instagram",  sfSymbol: "camera.fill",                   startHex: "#f09433", endHex: "#bc1888"),
        .init(id: "brand_whatsapp",  name: "WhatsApp",   sfSymbol: "bubble.left.fill",              startHex: "#25D366", endHex: "#075E54"),
        .init(id: "brand_facebook",  name: "Facebook",   sfSymbol: "person.2.fill",                 startHex: "#3b5998", endHex: "#1d3461"),
        .init(id: "brand_pinterest", name: "Pinterest",  sfSymbol: "pin.fill",                      startHex: "#E60023", endHex: "#8c0015"),
        .init(id: "brand_viber",     name: "Viber",      sfSymbol: "phone.fill",                    startHex: "#7360f2", endHex: "#4a26ab"),
        .init(id: "brand_snapchat",  name: "Snapchat",   sfSymbol: "camera.viewfinder",             startHex: "#FFFC00", endHex: "#FFD600", iconIsDark: true),
        .init(id: "brand_skype",     name: "Skype",      sfSymbol: "video.fill",                    startHex: "#00aff0", endHex: "#0079c1"),
        .init(id: "brand_spotify",   name: "Spotify",    sfSymbol: "music.note.list",               startHex: "#1DB954", endHex: "#0d7a34"),
        .init(id: "brand_youtube",   name: "YouTube",    sfSymbol: "play.rectangle.fill",           startHex: "#FF0000", endHex: "#cc0000"),
        .init(id: "brand_paypal",    name: "PayPal",     sfSymbol: "creditcard.fill",               startHex: "#009cde", endHex: "#003087"),
        .init(id: "brand_tiktok",    name: "TikTok",     sfSymbol: "music.note",                    startHex: "#010101", endHex: "#2b2b2b"),
        .init(id: "brand_line",      name: "LINE",       sfSymbol: "bubble.left.fill",              startHex: "#00C300", endHex: "#009000"),
        .init(id: "brand_linkedin",  name: "LinkedIn",   sfSymbol: "briefcase.fill",                startHex: "#0077B5", endHex: "#004471"),
        .init(id: "brand_wechat",    name: "WeChat",     sfSymbol: "ellipsis.bubble.fill",          startHex: "#07C160", endHex: "#059046"),
        .init(id: "brand_x",         name: "X",          sfSymbol: "xmark.circle.fill",             startHex: "#14171A", endHex: "#000000"),
        .init(id: "brand_bitcoin",   name: "Bitcoin",    sfSymbol: "bitcoinsign.circle.fill",       startHex: "#F7931A", endHex: "#c7680a"),
        .init(id: "brand_ethereum",  name: "Ethereum",   sfSymbol: "diamond.fill",                  startHex: "#627EEA", endHex: "#3C5BD6"),
        .init(id: "brand_bnb",       name: "BNB",        sfSymbol: "seal.fill",                     startHex: "#F3BA2F", endHex: "#c49610", iconIsDark: true),
        .init(id: "brand_telegram",  name: "Telegram",   sfSymbol: "paperplane.fill",               startHex: "#2AABEE", endHex: "#007ABB"),
        .init(id: "brand_messenger", name: "Messenger",  sfSymbol: "message.badge.filled.fill",     startHex: "#00B2FF", endHex: "#006AFF"),
        .init(id: "brand_discord",   name: "Discord",    sfSymbol: "gamecontroller.fill",           startHex: "#5865F2", endHex: "#3943c0"),
        .init(id: "brand_reddit",    name: "Reddit",     sfSymbol: "bubble.right.fill",             startHex: "#FF4500", endHex: "#cc3300"),
    ]

    /// `nil` or `"none"` means no template layer.
    static func renderBackground(id: String?, size: CGSize) -> UIImage? {
        let sid = (id ?? "none").lowercased()
        guard sid != "none", size.width > 1, size.height > 1 else { return nil }

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }

        let bounds = CGRect(origin: .zero, size: size)

        switch sid {
        case "sunset":
            drawLinearGradient(
                ctx,
                in: bounds,
                colors: [
                    UIColor(red: 1, green: 0.45, blue: 0.35, alpha: 1),
                    UIColor(red: 0.85, green: 0.35, blue: 0.55, alpha: 1),
                    UIColor(red: 0.45, green: 0.25, blue: 0.55, alpha: 1),
                ],
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height)
            )
        case "ocean":
            drawLinearGradient(
                ctx,
                in: bounds,
                colors: [
                    UIColor(red: 0.2, green: 0.55, blue: 0.85, alpha: 1),
                    UIColor(red: 0.15, green: 0.35, blue: 0.55, alpha: 1),
                    UIColor(red: 0.1, green: 0.25, blue: 0.4, alpha: 1),
                ],
                start: CGPoint(x: size.width * 0.2, y: 0),
                end: CGPoint(x: size.width * 0.8, y: size.height)
            )
        case "forest":
            drawLinearGradient(
                ctx,
                in: bounds,
                colors: [
                    UIColor(red: 0.2, green: 0.45, blue: 0.32, alpha: 1),
                    UIColor(red: 0.12, green: 0.28, blue: 0.22, alpha: 1),
                ],
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width * 0.6, y: size.height)
            )
        case "paper":
            ctx.setFillColor(UIColor(red: 0.97, green: 0.96, blue: 0.93, alpha: 1).cgColor)
            ctx.fill(bounds)
            ctx.setStrokeColor(UIColor(white: 0, alpha: 0.06).cgColor)
            ctx.setLineWidth(1)
            var y: CGFloat = 0
            while y < size.height {
                ctx.move(to: CGPoint(x: 0, y: y))
                ctx.addLine(to: CGPoint(x: size.width, y: y))
                y += 6
            }
            ctx.strokePath()
        case "grid":
            ctx.setFillColor(UIColor(red: 0.94, green: 0.96, blue: 1, alpha: 1).cgColor)
            ctx.fill(bounds)
            ctx.setStrokeColor(UIColor(red: 0.75, green: 0.82, blue: 0.95, alpha: 1).cgColor)
            ctx.setLineWidth(1)
            let step: CGFloat = max(14, min(size.width, size.height) / 24)
            var x: CGFloat = 0
            while x < size.width {
                ctx.move(to: CGPoint(x: x, y: 0))
                ctx.addLine(to: CGPoint(x: x, y: size.height))
                x += step
            }
            var yy: CGFloat = 0
            while yy < size.height {
                ctx.move(to: CGPoint(x: 0, y: yy))
                ctx.addLine(to: CGPoint(x: size.width, y: yy))
                yy += step
            }
            ctx.strokePath()
        case "dots":
            ctx.setFillColor(UIColor(red: 0.98, green: 0.98, blue: 1, alpha: 1).cgColor)
            ctx.fill(bounds)
            let step: CGFloat = max(10, min(size.width, size.height) / 28)
            ctx.setFillColor(UIColor(red: 0.55, green: 0.65, blue: 0.9, alpha: 0.35).cgColor)
            var py: CGFloat = step * 0.5
            var row = 0
            while py < size.height {
                var px = (row % 2 == 0 ? step * 0.5 : step) - step * 0.25
                while px < size.width {
                    ctx.fillEllipse(in: CGRect(x: px, y: py, width: step * 0.45, height: step * 0.45))
                    px += step * 2
                }
                row += 1
                py += step * 0.9
            }
        case "midnight":
            drawRadialGradient(
                ctx,
                in: bounds,
                colors: [
                    UIColor(red: 0.15, green: 0.2, blue: 0.45, alpha: 1),
                    UIColor(red: 0.05, green: 0.06, blue: 0.15, alpha: 1),
                ],
                center: CGPoint(x: size.width * 0.5, y: size.height * 0.35),
                startRadius: 0,
                endRadius: max(size.width, size.height) * 0.75
            )
            ctx.setFillColor(UIColor.white.withAlphaComponent(0.35).cgColor)
            for i in 0..<48 {
                let sx = size.width * (0.05 + CGFloat((i * 47) % 90) / 100)
                let sy = size.height * (0.05 + CGFloat((i * 31) % 90) / 100)
                let r = 0.6 + CGFloat(i % 5) * 0.18
                ctx.fillEllipse(in: CGRect(x: sx, y: sy, width: r, height: r))
            }
        case "aurora":
            drawLinearGradient(
                ctx,
                in: bounds,
                colors: [
                    UIColor(red: 0.2, green: 0.85, blue: 0.65, alpha: 1),
                    UIColor(red: 0.25, green: 0.45, blue: 0.95, alpha: 1),
                    UIColor(red: 0.55, green: 0.3, blue: 0.85, alpha: 1),
                ],
                start: CGPoint(x: 0, y: size.height),
                end: CGPoint(x: size.width, y: 0)
            )
        default:
            // Brand gradient templates
            if let brand = brandItems.first(where: { $0.id == sid }),
               let c1 = UIColor(hex: brand.startHex),
               let c2 = UIColor(hex: brand.endHex) {
                drawLinearGradient(
                    ctx,
                    in: bounds,
                    colors: [c1, c2],
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: size.width, y: size.height)
                )
            } else {
                return nil
            }
        }

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    /// Small preview for the template picker.
    static func previewImage(id: String, length: CGFloat = 72) -> UIImage? {
        guard id != "none" else { return nil }
        return renderBackground(id: id, size: CGSize(width: length, height: length))
    }

    private static func drawLinearGradient(
        _ ctx: CGContext,
        in rect: CGRect,
        colors: [UIColor],
        start: CGPoint,
        end: CGPoint
    ) {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let g = CGGradient(
                colorsSpace: space,
                colors: colors.map(\.cgColor) as CFArray,
                locations: (0..<colors.count).map { CGFloat($0) / CGFloat(max(colors.count - 1, 1)) }
              )
        else {
            ctx.setFillColor(colors[0].cgColor)
            ctx.fill(rect)
            return
        }
        ctx.saveGState()
        ctx.addRect(rect)
        ctx.clip()
        ctx.drawLinearGradient(g, start: start, end: end, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        ctx.restoreGState()
    }

    private static func drawRadialGradient(
        _ ctx: CGContext,
        in rect: CGRect,
        colors: [UIColor],
        center: CGPoint,
        startRadius: CGFloat,
        endRadius: CGFloat
    ) {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let g = CGGradient(colorsSpace: space, colors: colors.map(\.cgColor) as CFArray, locations: [0, 1])
        else {
            ctx.setFillColor(colors[0].cgColor)
            ctx.fill(rect)
            return
        }
        ctx.saveGState()
        ctx.addRect(rect)
        ctx.clip()
        ctx.drawRadialGradient(
            g,
            startCenter: center,
            startRadius: startRadius,
            endCenter: center,
            endRadius: endRadius,
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        )
        ctx.restoreGState()
    }
}
