//
//  QRReadabilityAdvisor.swift
//  QRCodeMaster
//

import CoreImage
import Foundation
import UIKit

enum QRReadabilityAdvisor {
    private static let minimumQuietZoneModules: Double = 4
    struct Report: Equatable, Sendable {
        let contrastRatio: Double
        let logoCoveragePercent: Double
        let quietZoneModules: Double
        let modulePixels: Double
        let moduleCount: Int
        let densePayload: Bool
        let issues: [String]
        let riskHigh: Bool
    }

    static let densePayloadThreshold = 120
    private static let outputPoints: CGFloat = 768
    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    static func analyze(payload: String, style: QRStyleOptions, hasLogo: Bool) -> Report {
        let moduleCount = estimatedModuleCount(payload: payload, correction: style.errorCorrection) ?? 33
        let usesCardLayout = usesCardLayout(style: style)
        let qrSide = usesCardLayout ? outputPoints * 0.72 : outputPoints
        let modulePixels = max(0.1, qrSide / CGFloat(max(1, moduleCount)))
        let quietZoneModules: Double = {
            if usesCardLayout {
                let margin = (outputPoints - qrSide) / 2
                return Double(margin / modulePixels)
            }
            // Plain layout renders with a fixed quiet zone around the matrix.
            return minimumQuietZoneModules
        }()

        let contrast = contrastRatio(foreground: style.foregroundUIColor(), background: style.backgroundUIColor())
        let logoCoveragePercent = hasLogo ? max(0, min(35, style.logoMaxRelativeSize * 100)) : 0
        let densePayload = payload.count >= densePayloadThreshold

        var issues: [String] = []
        var riskHigh = false

        if contrast < 3.5 {
            issues.append("Low contrast (\(String(format: "%.2f", contrast)):1) may fail scanner detection.")
            riskHigh = true
        }
        if logoCoveragePercent > 18 {
            issues.append("Logo area is large (\(Int(logoCoveragePercent))%).")
            riskHigh = true
        } else if logoCoveragePercent > 14 {
            issues.append("Logo area is moderately high (\(Int(logoCoveragePercent))%).")
        }
        if quietZoneModules < 4 {
            issues.append("Quiet zone is below recommended 4 modules.")
            riskHigh = true
        }
        if modulePixels < 3 {
            issues.append("Modules are very small (\(String(format: "%.1f", modulePixels)) px).")
            riskHigh = true
        } else if modulePixels < 4 {
            issues.append("Module size is small (\(String(format: "%.1f", modulePixels)) px).")
        }
        if isRiskyShape(style.moduleShape) {
            issues.append("Decorative module shape can reduce readability.")
            if modulePixels < 4 || densePayload { riskHigh = true }
        }
        if isDecorativeEyeStyle(style.eyeStyle) {
            issues.append("Decorative finder-eye style can reduce compatibility on older scanners.")
            if densePayload || modulePixels < 4 { riskHigh = true }
        }
        if style.brandBackgroundId != nil || style.backgroundTemplateId != nil || style.moduleShape == .photoDots {
            issues.append("Noisy background style may reduce contrast in some scanners.")
        }
        if densePayload {
            issues.append("Dense payload detected: safer defaults are enforced.")
            riskHigh = true
        }

        return Report(
            contrastRatio: contrast,
            logoCoveragePercent: logoCoveragePercent,
            quietZoneModules: quietZoneModules,
            modulePixels: Double(modulePixels),
            moduleCount: moduleCount,
            densePayload: densePayload,
            issues: issues,
            riskHigh: riskHigh
        )
    }

    static func applyingSafeDefaults(to style: QRStyleOptions, payload: String, hasLogo: Bool) -> QRStyleOptions {
        let report = analyze(payload: payload, style: style, hasLogo: hasLogo)
        var next = style
        if report.densePayload {
            next.errorCorrection = "H"
            next.moduleShape = .square
            next.eyeStyle = .square
            next.logoMaxRelativeSize = min(next.logoMaxRelativeSize, 0.16)
            next.brandBackgroundId = nil
            next.backgroundTemplateId = nil
            next.preferReadabilityUnderlay = true
        }
        if report.riskHigh {
            if report.contrastRatio < 3.5 {
                next.foregroundHex = "#000000"
                next.backgroundHex = "#FFFFFF"
            }
            if isRiskyShape(next.moduleShape) { next.moduleShape = .square }
            if isDecorativeEyeStyle(next.eyeStyle) { next.eyeStyle = .square }
            next.logoMaxRelativeSize = min(next.logoMaxRelativeSize, 0.18)
            if next.errorCorrection == "L" || next.errorCorrection == "M" {
                next.errorCorrection = "H"
            }
            next.preferReadabilityUnderlay = true
        }
        return next
    }

    static func applyingFix(_ fix: FixAction, to style: QRStyleOptions) -> QRStyleOptions {
        var updated = style
        switch fix {
        case .increaseContrast:
            updated.foregroundHex = "#000000"
            updated.backgroundHex = "#FFFFFF"
            updated.preferReadabilityUnderlay = true
        case .reduceLogo:
            updated.logoMaxRelativeSize = min(updated.logoMaxRelativeSize, 0.16)
            updated.errorCorrection = "H"
        case .simplifyModules:
            updated.moduleShape = .square
            updated.eyeStyle = .square
            updated.preferReadabilityUnderlay = true
        case .applyAll:
            updated.foregroundHex = "#000000"
            updated.backgroundHex = "#FFFFFF"
            updated.logoMaxRelativeSize = min(updated.logoMaxRelativeSize, 0.16)
            updated.errorCorrection = "H"
            updated.moduleShape = .square
            updated.eyeStyle = .square
            updated.preferReadabilityUnderlay = true
        }
        return updated
    }

    enum FixAction: String, CaseIterable, Sendable {
        case increaseContrast
        case reduceLogo
        case simplifyModules
        case applyAll

        var title: String {
            switch self {
            case .increaseContrast: return "Increase Contrast"
            case .reduceLogo: return "Reduce Logo"
            case .simplifyModules: return "Simplify Dots"
            case .applyAll: return "Apply All & Retry"
            }
        }
    }

    private static func usesCardLayout(style: QRStyleOptions) -> Bool {
        let hasTemplate = style.backgroundTemplateId?.isEmpty == false
        let hasBrand = style.brandBackgroundId?.isEmpty == false
        return hasTemplate || hasBrand
    }

    private static func isRiskyShape(_ shape: QRStyleOptions.ModuleShape) -> Bool {
        switch shape {
        case .square, .rounded:
            return false
        default:
            return true
        }
    }

    private static func isDecorativeEyeStyle(_ eye: QRStyleOptions.EyeStyle) -> Bool {
        switch eye {
        case .square, .roundedLeaf, .circle, .squareCircle:
            return false
        default:
            return true
        }
    }

    private static func estimatedModuleCount(payload: String, correction: String) -> Int? {
        guard let ci = QRGeneratorService.makeCIQRCode(message: payload, correctionLevel: correction),
              let tuple = QRGeneratorService.moduleMatrix(from: ci, context: context) else {
            return nil
        }
        return tuple.count
    }

    private static func contrastRatio(foreground: UIColor, background: UIColor) -> Double {
        let l1 = relativeLuminance(foreground)
        let l2 = relativeLuminance(background)
        let maxL = max(l1, l2)
        let minL = min(l1, l2)
        return (maxL + 0.05) / (minL + 0.05)
    }

    private static func relativeLuminance(_ color: UIColor) -> Double {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        func map(_ c: CGFloat) -> Double {
            let x = Double(c)
            return x <= 0.03928 ? (x / 12.92) : pow((x + 0.055) / 1.055, 2.4)
        }
        let rl = map(r), gl = map(g), bl = map(b)
        return 0.2126 * rl + 0.7152 * gl + 0.0722 * bl
    }
}
