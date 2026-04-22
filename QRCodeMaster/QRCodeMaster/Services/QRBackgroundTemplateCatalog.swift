//
//  QRBackgroundTemplateCatalog.swift
//  QRCodeMaster
//

import CoreGraphics
import UIKit

/// Built-in decorative backgrounds for QR export (generated at render time — no bundled bitmaps required).
enum QRBackgroundTemplateCatalog {

    /// Gallery filter tabs — each template belongs to **exactly one** category (no repeats across tabs).
    enum GalleryCategory: String, CaseIterable, Identifiable, Hashable, Sendable {
        case hot, social, love, vcard, business, wifi

        var id: String { rawValue }

        var title: String {
            switch self {
            case .hot:      "Hot"
            case .social:   "Social"
            case .love:     "Love"
            case .vcard:    "Vcard"
            case .business: "Business"
            case .wifi:     "Wifi"
            }
        }
    }

    /// One decorative template + its single gallery category.
    struct CatalogEntry: Identifiable, Hashable, Sendable {
        let id: String
        let title: String
        let category: GalleryCategory
    }

    struct Item: Identifiable, Hashable, Sendable {
        let id: String
        let title: String
    }

    /// Every non-`none` template appears in **one** category only (partitioned across `GalleryCategory`).
    static let allTemplates: [CatalogEntry] = [
        // Hot
        .init(id: "sunset",       title: "Sunset",       category: .hot),
        .init(id: "neon_party",   title: "Neon Party",   category: .hot),
        .init(id: "golden_hour",  title: "Golden Hour",  category: .hot),
        .init(id: "cherry_pop",   title: "Cherry Pop",   category: .hot),
        .init(id: "prism_glow",   title: "Prism Glow",   category: .hot),
        // Social
        .init(id: "ocean",        title: "Ocean",        category: .social),
        .init(id: "grid",         title: "Soft grid",   category: .social),
        .init(id: "story_ring",   title: "Story Ring",   category: .social),
        .init(id: "hashtag_field", title: "Hashtag",     category: .social),
        .init(id: "feed_coral",   title: "Feed Coral",   category: .social),
        // Love
        .init(id: "aurora",       title: "Aurora",       category: .love),
        .init(id: "coral_blush",  title: "Coral Blush",  category: .love),
        .init(id: "rose_gold",    title: "Rose Gold",    category: .love),
        .init(id: "forest",       title: "Forest",       category: .love),
        // Vcard
        .init(id: "paper",        title: "Paper",        category: .vcard),
        .init(id: "dots",         title: "Dots",        category: .vcard),
        .init(id: "contact_card", title: "Contact Card", category: .vcard),
        .init(id: "id_strip",     title: "ID Strip",     category: .vcard),
        // Business
        .init(id: "midnight",     title: "Midnight",     category: .business),
        .init(id: "slate_corporate", title: "Slate",    category: .business),
        .init(id: "mint_ledgers", title: "Mint Ledger", category: .business),
        .init(id: "carbon_fiber", title: "Carbon",      category: .business),
        .init(id: "espresso",     title: "Espresso",    category: .business),
        // Wifi
        .init(id: "wifi_waves",   title: "Wifi Waves",   category: .wifi),
        .init(id: "hotspot_green", title: "Hotspot",    category: .wifi),
        .init(id: "spectrum_scan", title: "Spectrum",   category: .wifi),
        .init(id: "signal_mesh",  title: "Signal Mesh",  category: .wifi),
    ]

    static func templates(in category: GalleryCategory) -> [CatalogEntry] {
        allTemplates.filter { $0.category == category }
    }

    /// Picker list: None + every catalog template (Customize horizontal strip).
    static var items: [Item] {
        [Item(id: "none", title: "None")]
            + allTemplates.map { Item(id: $0.id, title: $0.title) }
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

        // ── Hot ─────────────────────────────────────────────────────────────
        case "neon_party":
            drawLinearGradient(
                ctx, in: bounds,
                colors: [
                    UIColor(red: 0.05, green: 0.02, blue: 0.12, alpha: 1),
                    UIColor(red: 0.55, green: 0.05, blue: 0.45, alpha: 1),
                    UIColor(red: 0.0, green: 0.85, blue: 0.9, alpha: 1),
                ],
                start: .zero,
                end: CGPoint(x: size.width, y: size.height)
            )
        case "golden_hour":
            drawLinearGradient(
                ctx, in: bounds,
                colors: [
                    UIColor(red: 1, green: 0.95, blue: 0.65, alpha: 1),
                    UIColor(red: 1, green: 0.65, blue: 0.25, alpha: 1),
                    UIColor(red: 0.85, green: 0.35, blue: 0.08, alpha: 1),
                ],
                start: CGPoint(x: 0, y: size.height * 0.2),
                end: CGPoint(x: size.width, y: size.height)
            )
        case "cherry_pop":
            drawLinearGradient(
                ctx, in: bounds,
                colors: [
                    UIColor(red: 1, green: 0.45, blue: 0.45, alpha: 1),
                    UIColor(red: 0.75, green: 0.08, blue: 0.15, alpha: 1),
                ],
                start: CGPoint(x: size.width, y: 0),
                end: CGPoint(x: 0, y: size.height)
            )
        case "prism_glow":
            drawLinearGradient(
                ctx, in: bounds,
                colors: [
                    UIColor(red: 0.95, green: 0.2, blue: 0.45, alpha: 1),
                    UIColor(red: 0.45, green: 0.25, blue: 0.95, alpha: 1),
                    UIColor(red: 0.2, green: 0.85, blue: 0.95, alpha: 1),
                    UIColor(red: 0.4, green: 0.95, blue: 0.45, alpha: 1),
                    UIColor(red: 1, green: 0.85, blue: 0.2, alpha: 1),
                ],
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height)
            )

        // ── Social ──────────────────────────────────────────────────────────
        case "story_ring":
            ctx.setFillColor(UIColor(red: 0.93, green: 0.88, blue: 0.98, alpha: 1).cgColor)
            ctx.fill(bounds)
            let cx = size.width * 0.5, cy = size.height * 0.45
            ctx.setStrokeColor(UIColor(white: 1, alpha: 0.45).cgColor)
            ctx.setLineWidth(max(2, min(size.width, size.height) * 0.012))
            for i in 1...6 {
                let rr = CGFloat(i) * min(size.width, size.height) * 0.09
                ctx.addEllipse(in: CGRect(x: cx - rr, y: cy - rr, width: rr * 2, height: rr * 2))
                ctx.strokePath()
            }
        case "hashtag_field":
            ctx.setFillColor(UIColor(red: 0.09, green: 0.11, blue: 0.2, alpha: 1).cgColor)
            ctx.fill(bounds)
            ctx.setStrokeColor(UIColor(white: 1, alpha: 0.12).cgColor)
            ctx.setLineWidth(1)
            let gstep = max(18, min(size.width, size.height) / 20)
            var gx: CGFloat = 0
            while gx < size.width {
                ctx.move(to: CGPoint(x: gx, y: 0))
                ctx.addLine(to: CGPoint(x: gx, y: size.height))
                gx += gstep
            }
            var gy: CGFloat = 0
            while gy < size.height {
                ctx.move(to: CGPoint(x: 0, y: gy))
                ctx.addLine(to: CGPoint(x: size.width, y: gy))
                gy += gstep
            }
            ctx.strokePath()
            ctx.setStrokeColor(UIColor(white: 1, alpha: 0.18).cgColor)
            ctx.setLineWidth(2)
            let hs = min(size.width, size.height) * 0.22
            var hx = gstep
            while hx < size.width - gstep {
                var hy = gstep
                while hy < size.height - gstep {
                    drawHashTag(ctx, center: CGPoint(x: hx, y: hy), size: hs * 0.35)
                    hy += gstep * 3
                }
                hx += gstep * 3
            }
        case "feed_coral":
            drawLinearGradient(
                ctx, in: bounds,
                colors: [
                    UIColor(red: 0.96, green: 0.52, blue: 0.18, alpha: 1),
                    UIColor(red: 0.86, green: 0.16, blue: 0.48, alpha: 1),
                    UIColor(red: 0.45, green: 0.15, blue: 0.65, alpha: 1),
                ],
                start: CGPoint(x: 0, y: size.height),
                end: CGPoint(x: size.width, y: 0)
            )

        // ── Love ────────────────────────────────────────────────────────────
        case "coral_blush":
            drawLinearGradient(
                ctx, in: bounds,
                colors: [
                    UIColor(red: 1, green: 0.8, blue: 0.82, alpha: 1),
                    UIColor(red: 1, green: 0.55, blue: 0.65, alpha: 1),
                    UIColor(red: 0.95, green: 0.45, blue: 0.72, alpha: 1),
                ],
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height)
            )
        case "rose_gold":
            drawLinearGradient(
                ctx, in: bounds,
                colors: [
                    UIColor(red: 1, green: 0.96, blue: 0.94, alpha: 1),
                    UIColor(red: 0.88, green: 0.72, blue: 0.72, alpha: 1),
                    UIColor(red: 0.79, green: 0.62, blue: 0.38, alpha: 1),
                ],
                start: CGPoint(x: 0, y: size.height),
                end: CGPoint(x: size.width, y: 0)
            )

        // ── Vcard ───────────────────────────────────────────────────────────
        case "contact_card":
            ctx.setFillColor(UIColor(red: 0.98, green: 0.98, blue: 0.97, alpha: 1).cgColor)
            ctx.fill(bounds)
            ctx.setStrokeColor(UIColor(white: 0, alpha: 0.08).cgColor)
            ctx.setLineWidth(1)
            let cw = size.width / 3.2, ch = size.height / 2.8
            var cy: CGFloat = size.height * 0.12
            while cy + ch < size.height * 0.92 {
                var cx: CGFloat = size.width * 0.08
                while cx + cw < size.width * 0.92 {
                    let r = CGRect(x: cx, y: cy, width: cw, height: ch)
                    ctx.addPath(UIBezierPath(roundedRect: r.insetBy(dx: 4, dy: 4), cornerRadius: 8).cgPath)
                    cx += cw + 8
                }
                cy += ch + 10
            }
            ctx.strokePath()
        case "id_strip":
            let bands: [UIColor] = [
                UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1),
                UIColor(red: 0.88, green: 0.89, blue: 0.92, alpha: 1),
                UIColor(red: 0.92, green: 0.93, blue: 0.95, alpha: 1),
            ]
            let bh = size.height / CGFloat(bands.count)
            for (i, col) in bands.enumerated() {
                ctx.setFillColor(col.cgColor)
                ctx.fill(CGRect(x: 0, y: CGFloat(i) * bh, width: size.width, height: bh))
            }
            ctx.setStrokeColor(UIColor(white: 0, alpha: 0.06).cgColor)
            ctx.setLineWidth(1)
            ctx.move(to: CGPoint(x: 0, y: bh))
            ctx.addLine(to: CGPoint(x: size.width, y: bh))
            ctx.move(to: CGPoint(x: 0, y: bh * 2))
            ctx.addLine(to: CGPoint(x: size.width, y: bh * 2))
            ctx.strokePath()

        // ── Business ───────────────────────────────────────────────────────
        case "slate_corporate":
            drawLinearGradient(
                ctx, in: bounds,
                colors: [
                    UIColor(red: 0.45, green: 0.52, blue: 0.62, alpha: 1),
                    UIColor(red: 0.12, green: 0.16, blue: 0.23, alpha: 1),
                ],
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height)
            )
        case "mint_ledgers":
            ctx.setFillColor(UIColor(red: 0.94, green: 0.99, blue: 0.96, alpha: 1).cgColor)
            ctx.fill(bounds)
            ctx.setStrokeColor(UIColor(red: 0.55, green: 0.88, blue: 0.68, alpha: 0.45).cgColor)
            ctx.setLineWidth(1)
            var vx: CGFloat = 16
            while vx < size.width {
                ctx.move(to: CGPoint(x: vx, y: 0))
                ctx.addLine(to: CGPoint(x: vx, y: size.height))
                vx += 22
            }
            ctx.strokePath()
        case "carbon_fiber":
            ctx.setFillColor(UIColor(red: 0.06, green: 0.06, blue: 0.07, alpha: 1).cgColor)
            ctx.fill(bounds)
            ctx.setStrokeColor(UIColor(white: 1, alpha: 0.06).cgColor)
            ctx.setLineWidth(1)
            let spacing: CGFloat = 10
            var d: CGFloat = -size.height
            while d < size.width + size.height {
                ctx.move(to: CGPoint(x: d, y: 0))
                ctx.addLine(to: CGPoint(x: d + size.height * 1.2, y: size.height))
                d += spacing
            }
            d = -size.height
            while d < size.width + size.height {
                ctx.move(to: CGPoint(x: d + 5, y: 0))
                ctx.addLine(to: CGPoint(x: d + 5 + size.height * 1.2, y: size.height))
                d += spacing
            }
            ctx.strokePath()
        case "espresso":
            drawRadialGradient(
                ctx, in: bounds,
                colors: [
                    UIColor(red: 0.45, green: 0.28, blue: 0.18, alpha: 1),
                    UIColor(red: 0.08, green: 0.04, blue: 0.03, alpha: 1),
                ],
                center: CGPoint(x: size.width * 0.5, y: size.height * 0.25),
                startRadius: 0,
                endRadius: max(size.width, size.height) * 0.85
            )

        // ── Wifi ────────────────────────────────────────────────────────────
        case "wifi_waves":
            ctx.setFillColor(UIColor(red: 0.88, green: 0.97, blue: 0.98, alpha: 1).cgColor)
            ctx.fill(bounds)
            let ox = size.width * 0.12
            let oy = size.height * 0.88
            ctx.setStrokeColor(UIColor(red: 0.0, green: 0.55, blue: 0.58, alpha: 0.55).cgColor)
            ctx.setLineWidth(max(3, min(size.width, size.height) * 0.018))
            ctx.setLineCap(.round)
            for i in 1...5 {
                let span = CGFloat(i) * min(size.width, size.height) * 0.14
                let path = UIBezierPath(
                    arcCenter: CGPoint(x: ox, y: oy),
                    radius: span,
                    startAngle: .pi * 1.1,
                    endAngle: .pi * 1.9,
                    clockwise: true
                )
                ctx.addPath(path.cgPath)
                ctx.strokePath()
            }
        case "hotspot_green":
            drawLinearGradient(
                ctx, in: bounds,
                colors: [
                    UIColor(red: 0.45, green: 0.95, blue: 0.55, alpha: 1),
                    UIColor(red: 0.05, green: 0.35, blue: 0.18, alpha: 1),
                ],
                start: CGPoint(x: size.width * 0.2, y: 0),
                end: CGPoint(x: size.width * 0.8, y: size.height)
            )
        case "spectrum_scan":
            ctx.setFillColor(UIColor(red: 0.12, green: 0.1, blue: 0.22, alpha: 1).cgColor)
            ctx.fill(bounds)
            let band = max(3, size.height / 40)
            var yy: CGFloat = 0
            var hue: CGFloat = 0
            while yy < size.height {
                ctx.setFillColor(UIColor(hue: hue, saturation: 0.55, brightness: 0.85, alpha: 0.35).cgColor)
                ctx.fill(CGRect(x: 0, y: yy, width: size.width, height: band))
                yy += band * 1.2
                hue += 0.07
                if hue > 1 { hue -= 1 }
            }
        case "signal_mesh":
            ctx.setFillColor(UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1).cgColor)
            ctx.fill(bounds)
            let step = max(28, min(size.width, size.height) / 10)
            ctx.setFillColor(UIColor(red: 0.3, green: 0.85, blue: 0.95, alpha: 0.4).cgColor)
            var py: CGFloat = step * 0.35
            var row = 0
            while py < size.height {
                var px = (row % 2 == 0 ? step * 0.2 : step * 0.65)
                while px < size.width {
                    ctx.fillEllipse(in: CGRect(x: px - 3.5, y: py - 3.5, width: 7, height: 7))
                    px += step
                }
                row += 1
                py += step * 0.55
            }

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

    /// Lightweight “#” mark for `hashtag_field`.
    private static func drawHashTag(_ ctx: CGContext, center c: CGPoint, size s: CGFloat) {
        let h = s * 0.45
        ctx.saveGState()
        ctx.setLineWidth(max(1, s * 0.12))
        ctx.setLineCap(.round)
        ctx.move(to: CGPoint(x: c.x - h, y: c.y - h))
        ctx.addLine(to: CGPoint(x: c.x + h, y: c.y + h))
        ctx.move(to: CGPoint(x: c.x + h, y: c.y - h))
        ctx.addLine(to: CGPoint(x: c.x - h, y: c.y + h))
        ctx.move(to: CGPoint(x: c.x - h, y: c.y))
        ctx.addLine(to: CGPoint(x: c.x + h, y: c.y))
        ctx.move(to: CGPoint(x: c.x, y: c.y - h))
        ctx.addLine(to: CGPoint(x: c.x, y: c.y + h))
        ctx.strokePath()
        ctx.restoreGState()
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
