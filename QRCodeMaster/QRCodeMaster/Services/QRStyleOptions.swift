//
//  QRStyleOptions.swift
//  QRCodeMaster
//

import CoreGraphics
import UIKit

struct QRStyleOptions: Codable, Equatable, Sendable {
    var foregroundHex: String
    var backgroundHex: String
    /// One of L, M, Q, H
    var errorCorrection: String
    var moduleShape: ModuleShape
    var eyeStyle: EyeStyle
    var frameId: String?
    /// Built-in decorative template (sunset, ocean, …) — fills the full canvas.
    var backgroundTemplateId: String?
    /// Brand colour background (brand_instagram, brand_whatsapp, …) — fills the QR area only.
    /// Independent of `backgroundTemplateId` so both can be active at the same time.
    var brandBackgroundId: String?
    /// Max fraction of QR width for logo (0…0.35)
    var logoMaxRelativeSize: Double
    /// Optional text label drawn below the QR in the exported image.
    var captionText: String
    var captionColorHex: String
    /// JPEG data for `ModuleShape.photoDots` — each dark module draws a clipped slice of this image (aspect-fill over the full QR).
    var moduleDotPatternJPEG: Data?

    enum ModuleShape: String, Codable, CaseIterable, Sendable {
        case square
        case rounded
        case dot
        /// N×N circle grids per module (halftone-style), distinct from single `dot`.
        case dots2x2
        case dots       // 3×3 — raw value `dots` keeps older saved JSON working
        case dots4x4
        case dots5x5
        case dots3x2    // 3×2 micro-grid per module
        case dotsPlus   // five overlapping circles (plus)
        case diamond    // rotated square
        /// Photo texture clipped to a circular dot per module (requires `moduleDotPatternJPEG`).
        case photoDots

        var displayName: String {
            switch self {
            case .square:    "Square"
            case .rounded:   "Rounded"
            case .dot:       "Dot"
            case .dots2x2:   "2×2 Dots"
            case .dots:      "3×3 Dots"
            case .dots4x4:   "4×4 Dots"
            case .dots5x5:   "5×5 Dots"
            case .dots3x2:   "3×2 Dots"
            case .dotsPlus:   "Plus Dots"
            case .diamond:   "Diamond"
            case .photoDots: "Photo dots"
            }
        }
    }

    enum EyeStyle: String, Codable, CaseIterable, Sendable {
        // ── Original 4 ────────────────────────────────────────────────────────
        case square             // square outer  + square inner
        case roundedLeaf        // rounded outer + rounded inner
        case circle             // circle outer  + circle inner
        case squareCircle       // square outer  + circle inner
        // ── 8 New styles ──────────────────────────────────────────────────────
        case circleSquare       // circle outer  + square inner
        case squareDiamond      // square outer  + diamond inner
        case diamond            // diamond outer + diamond inner
        case roundedCircle      // rounded outer + circle inner
        case squareRounded      // square outer  + heavily-rounded rect inner
        case circleRound        // circle outer  + rounded-square inner
        case concentric         // double circle rings, no filled centre
        case roundedDiamond     // rounded outer + diamond inner

        var displayName: String {
            switch self {
            case .square:         "Square"
            case .roundedLeaf:    "Rounded"
            case .circle:         "Circle"
            case .squareCircle:   "Sq+Circle"
            case .circleSquare:   "Circ+Sq"
            case .squareDiamond:  "Sq+Diamond"
            case .diamond:        "Diamond"
            case .roundedCircle:  "Rnd+Circle"
            case .squareRounded:  "Sq+Round"
            case .circleRound:    "Circ+Round"
            case .concentric:     "Concentric"
            case .roundedDiamond: "Rnd+Diamond"
            }
        }
    }

    // MARK: - Memberwise init (keeps default values)

    init(
        foregroundHex: String = "#000000",
        backgroundHex: String = "#FFFFFF",
        errorCorrection: String = "M",
        moduleShape: ModuleShape = .square,
        eyeStyle: EyeStyle = .square,
        frameId: String? = nil,
        backgroundTemplateId: String? = nil,
        brandBackgroundId: String? = nil,
        logoMaxRelativeSize: Double = 0.22,
        captionText: String = "",
        captionColorHex: String = "#000000",
        moduleDotPatternJPEG: Data? = nil
    ) {
        self.foregroundHex = foregroundHex
        self.backgroundHex = backgroundHex
        self.errorCorrection = errorCorrection
        self.moduleShape = moduleShape
        self.eyeStyle = eyeStyle
        self.frameId = frameId
        self.backgroundTemplateId = backgroundTemplateId
        self.brandBackgroundId = brandBackgroundId
        self.logoMaxRelativeSize = logoMaxRelativeSize
        self.captionText = captionText
        self.captionColorHex = captionColorHex
        self.moduleDotPatternJPEG = moduleDotPatternJPEG
    }

    static let `default` = QRStyleOptions()

    func foregroundUIColor() -> UIColor { UIColor(hex: foregroundHex) ?? .black }
    func backgroundUIColor() -> UIColor { UIColor(hex: backgroundHex) ?? .white }

    // MARK: - Codable (manual, backward-compat: unknown/missing keys fall back to defaults)

    private enum CodingKeys: String, CodingKey {
        case foregroundHex, backgroundHex, errorCorrection, moduleShape, eyeStyle
        case frameId, backgroundTemplateId, brandBackgroundId, logoMaxRelativeSize
        case captionText, captionColorHex, moduleDotPatternJPEG
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        foregroundHex        = (try? c.decode(String.self,      forKey: .foregroundHex))       ?? "#000000"
        backgroundHex        = (try? c.decode(String.self,      forKey: .backgroundHex))       ?? "#FFFFFF"
        errorCorrection      = (try? c.decode(String.self,      forKey: .errorCorrection))     ?? "M"
        moduleShape          = (try? c.decode(ModuleShape.self, forKey: .moduleShape))         ?? .square
        eyeStyle             = (try? c.decode(EyeStyle.self,    forKey: .eyeStyle))            ?? .square
        frameId              = try? c.decode(String.self,       forKey: .frameId)
        backgroundTemplateId = try? c.decode(String.self,       forKey: .backgroundTemplateId)
        brandBackgroundId    = try? c.decode(String.self,       forKey: .brandBackgroundId)
        logoMaxRelativeSize  = (try? c.decode(Double.self,      forKey: .logoMaxRelativeSize)) ?? 0.22
        captionText          = (try? c.decode(String.self,      forKey: .captionText))         ?? ""
        captionColorHex      = (try? c.decode(String.self,      forKey: .captionColorHex))     ?? "#000000"
        moduleDotPatternJPEG = try? c.decode(Data.self,         forKey: .moduleDotPatternJPEG)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(foregroundHex,        forKey: .foregroundHex)
        try c.encode(backgroundHex,        forKey: .backgroundHex)
        try c.encode(errorCorrection,      forKey: .errorCorrection)
        try c.encode(moduleShape,          forKey: .moduleShape)
        try c.encode(eyeStyle,             forKey: .eyeStyle)
        try c.encodeIfPresent(frameId,              forKey: .frameId)
        try c.encodeIfPresent(backgroundTemplateId,  forKey: .backgroundTemplateId)
        try c.encodeIfPresent(brandBackgroundId,     forKey: .brandBackgroundId)
        try c.encode(logoMaxRelativeSize,  forKey: .logoMaxRelativeSize)
        try c.encode(captionText,          forKey: .captionText)
        try c.encode(captionColorHex,      forKey: .captionColorHex)
        try c.encodeIfPresent(moduleDotPatternJPEG, forKey: .moduleDotPatternJPEG)
    }
}

// MARK: - UIColor hex helper

extension UIColor {
    convenience init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6 || s.count == 8 else { return nil }
        var value: UInt64 = 0
        guard Scanner(string: s).scanHexInt64(&value) else { return nil }
        let a, r, g, b: CGFloat
        if s.count == 8 {
            a = CGFloat((value & 0xFF00_0000) >> 24) / 255
            r = CGFloat((value & 0x00FF_0000) >> 16) / 255
            g = CGFloat((value & 0x0000_FF00) >> 8) / 255
            b = CGFloat( value & 0x0000_00FF) / 255
        } else {
            a = 1
            r = CGFloat((value & 0xFF00_00) >> 16) / 255
            g = CGFloat((value & 0x00FF_00) >> 8) / 255
            b = CGFloat( value & 0x0000_FF) / 255
        }
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
