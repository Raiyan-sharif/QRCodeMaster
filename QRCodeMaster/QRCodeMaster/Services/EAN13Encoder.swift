//
//  EAN13Encoder.swift
//  QRCodeMaster
//

import CoreGraphics
import UIKit

/// EAN-13 (12 digits + check, or 13 digits) bar pattern → raster image.
enum EAN13Encoder {
    /// Returns `nil` if digits invalid or checksum wrong.
    static func image(
        digits: String,
        height: CGFloat = 120,
        maxWidth: CGFloat = 400,
        barColor: UIColor = .black,
        background: UIColor = .white
    ) -> UIImage? {
        let normalized = digits.filter(\.isNumber)
        guard normalized.count == 12 || normalized.count == 13 else { return nil }
        let twelve: String
        let check: Int
        if normalized.count == 13 {
            twelve = String(normalized.prefix(12))
            check = Int(String(normalized.last!))!
            guard computeCheckDigit(twelve) == check else { return nil }
        } else {
            twelve = normalized
            check = computeCheckDigit(twelve)
        }

        let full = twelve + String(check)
        guard let pattern = barPattern(bodyWithCheck: full), pattern.count == 95 else { return nil }

        let moduleCount = CGFloat(pattern.count)
        let moduleW = min(maxWidth / moduleCount, maxWidth / 95)
        let width = moduleW * moduleCount
        let size = CGSize(width: width, height: height)

        UIGraphicsBeginImageContextWithOptions(size, true, 0)
        defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }

        ctx.setFillColor(background.cgColor)
        ctx.fill(CGRect(origin: .zero, size: size))

        ctx.setFillColor(barColor.cgColor)
        var x: CGFloat = 0
        for bit in pattern {
            if bit == 1 {
                ctx.fill(CGRect(x: x, y: 0, width: moduleW, height: height * 0.88))
            }
            x += moduleW
        }

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    /// 95 modules (1 = black bar column).
    static func barPattern(bodyWithCheck: String) -> [Int]? {
        let s = bodyWithCheck.filter(\.isNumber)
        guard s.count == 13 else { return nil }
        guard let first = Int(String(s.first!)), (0...9).contains(first) else { return nil }
        let leftSix = s.dropFirst().prefix(6)
        let rightSix = s.dropFirst(7).prefix(6)

        let leftParity = parityMap[first]

        var bits: [Int] = []
        bits.append(contentsOf: [1, 0, 1])

        for (i, ch) in leftSix.enumerated() {
            guard let d = Int(String(ch)), (0...9).contains(d) else { return nil }
            let row = leftParity[i] == "L" ? L[d] : G[d]
            bits.append(contentsOf: row)
        }

        bits.append(contentsOf: [0, 1, 0, 1, 0])

        for ch in rightSix {
            guard let d = Int(String(ch)), (0...9).contains(d) else { return nil }
            bits.append(contentsOf: R[d])
        }

        bits.append(contentsOf: [1, 0, 1])
        guard bits.count == 95 else { return nil }
        return bits
    }

    static func computeCheckDigit(_ twelve: String) -> Int {
        let d = twelve.filter(\.isNumber)
        guard d.count == 12 else { return 0 }
        var sum = 0
        for (i, ch) in d.enumerated() {
            let n = Int(String(ch))!
            sum += (i % 2 == 0) ? n : n * 3
        }
        return (10 - (sum % 10)) % 10
    }

#if DEBUG
    static func runSelfCheck() {
        assert(computeCheckDigit("590123412345") == 7)
        let p = barPattern(bodyWithCheck: "5901234123457")
        assert(p?.count == 95)
    }
#endif

    // MARK: - Parity (first digit → L/G for left six)

    private static let parityMap: [[String]] = [
        ["L", "L", "L", "L", "L", "L"],
        ["L", "L", "G", "L", "G", "G"],
        ["L", "L", "G", "G", "L", "G"],
        ["L", "L", "G", "G", "G", "L"],
        ["L", "G", "L", "L", "G", "G"],
        ["L", "G", "G", "L", "L", "G"],
        ["L", "G", "G", "G", "L", "L"],
        ["L", "G", "L", "G", "L", "G"],
        ["L", "G", "L", "G", "G", "L"],
        ["L", "G", "G", "L", "G", "L"],
    ]

    /// GS1 digit encodings (Wikipedia / ISO/IEC 15420), 7 modules each.
    private static let L: [[Int]] = [
        [0, 0, 0, 1, 1, 0, 1],
        [0, 0, 1, 1, 0, 0, 1],
        [0, 0, 1, 0, 0, 1, 1],
        [0, 1, 1, 1, 1, 0, 1],
        [0, 1, 0, 0, 0, 1, 1],
        [0, 1, 1, 0, 0, 0, 1],
        [0, 1, 0, 1, 1, 1, 1],
        [0, 1, 1, 1, 0, 1, 1],
        [0, 1, 1, 0, 1, 1, 1],
        [0, 0, 0, 1, 0, 1, 1],
    ]

    private static let G: [[Int]] = [
        [0, 1, 0, 0, 1, 1, 1],
        [0, 1, 1, 0, 0, 1, 1],
        [0, 0, 1, 1, 0, 1, 1],
        [0, 1, 0, 0, 0, 0, 1],
        [0, 0, 1, 1, 1, 0, 1],
        [0, 1, 1, 1, 0, 0, 1],
        [0, 0, 0, 0, 1, 0, 1],
        [0, 0, 1, 0, 0, 0, 1],
        [0, 0, 0, 1, 0, 0, 1],
        [0, 0, 1, 0, 1, 1, 1],
    ]

    private static let R: [[Int]] = [
        [1, 1, 1, 0, 0, 1, 0],
        [1, 1, 0, 0, 1, 1, 0],
        [1, 1, 0, 1, 1, 0, 0],
        [1, 0, 0, 0, 0, 1, 0],
        [1, 0, 1, 1, 1, 0, 0],
        [1, 0, 0, 1, 1, 1, 0],
        [1, 0, 0, 0, 1, 1, 0],
        [1, 1, 1, 1, 0, 1, 0],
        [1, 0, 1, 0, 0, 1, 0],
        [1, 1, 0, 1, 0, 1, 0],
    ]
}
