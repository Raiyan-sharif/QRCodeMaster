//
//  QRStyleOptions.swift
//  QRCodeMaster
//

import CoreGraphics
import SwiftUI
import UIKit

struct QRStyleOptions: Codable, Equatable, Sendable {
    var foregroundHex: String
    var backgroundHex: String
    /// One of L, M, Q, H
    var errorCorrection: String
    var moduleShape: ModuleShape
    var eyeStyle: EyeStyle
    var frameId: String?
    /// Built-in template id from `QRBackgroundTemplateCatalog`, or `nil` / `"none"` for a flat background.
    var backgroundTemplateId: String?
    /// Max fraction of QR width for logo (0...0.35)
    var logoMaxRelativeSize: Double

    enum ModuleShape: String, Codable, CaseIterable, Sendable {
        case square
        case rounded
        case dot
    }

    enum EyeStyle: String, Codable, CaseIterable, Sendable {
        case square
        case roundedLeaf
        case circle
    }

    static let `default` = QRStyleOptions(
        foregroundHex: "#000000",
        backgroundHex: "#FFFFFF",
        errorCorrection: "M",
        moduleShape: .square,
        eyeStyle: .square,
        frameId: nil,
        backgroundTemplateId: nil,
        logoMaxRelativeSize: 0.22
    )

    func foregroundUIColor() -> UIColor { UIColor(hex: foregroundHex) ?? .black }
    func backgroundUIColor() -> UIColor { UIColor(hex: backgroundHex) ?? .white }
}

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
            b = CGFloat(value & 0x0000_00FF) / 255
        } else {
            a = 1
            r = CGFloat((value & 0xFF00_00) >> 16) / 255
            g = CGFloat((value & 0x00FF_00) >> 8) / 255
            b = CGFloat(value & 0x0000_FF) / 255
        }
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
