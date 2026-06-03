//
//  QRRenderPipeline.swift
//  QRCodeMaster
//

import UIKit

/// Renders export bitmaps and escalates styling until an in-app decode check passes (or max tier is reached).
enum QRRenderPipeline {

    struct Result: Sendable {
        let image: UIImage?
        let verification: QRImageVerifier.Outcome
        let usedMaximumReliability: Bool
    }

    static func renderVerified(
        message: String,
        options: QRStyleOptions,
        logo: UIImage?,
        outputPoints: CGFloat = 1024,
        showWatermark: Bool
    ) async -> Result {
        let hasLogo = logo != nil
        let safe = QRReadabilityAdvisor.applyingSafeDefaults(to: options, payload: message, hasLogo: hasLogo)
        let maximum = QRReadabilityAdvisor.applyingMaximumReliability(to: options, hasLogo: hasLogo)

        var tiers: [(QRStyleOptions, Bool)] = [(safe, false)]
        if maximum != safe {
            tiers.append((maximum, true))
        }

        var lastImage: UIImage?
        var lastOutcome: QRImageVerifier.Outcome = .couldNotReadFromImage
        var usedMax = false

        for (tierOptions, isMax) in tiers {
            guard let image = QRStyleRenderer.render(
                message: message,
                options: tierOptions,
                logo: logo,
                outputPoints: outputPoints,
                showWatermark: showWatermark,
                intent: .export
            ) else { continue }

            lastImage = image
            let outcome = await QRImageVerifier.verify(image: image, expectedPayload: message)
            lastOutcome = outcome
            usedMax = isMax

            switch outcome {
            case .validMatchesContent, .readablePayloadMismatch:
                return Result(image: image, verification: outcome, usedMaximumReliability: isMax)
            case .couldNotReadFromImage, .failed, .idle, .verifying:
                continue
            }
        }

        return Result(image: lastImage, verification: lastOutcome, usedMaximumReliability: usedMax)
    }
}
