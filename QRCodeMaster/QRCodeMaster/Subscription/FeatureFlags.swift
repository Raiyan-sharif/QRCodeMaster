//
//  FeatureFlags.swift
//  QRCodeMaster
//

import Foundation

struct FeatureFlags: Sendable {
    let provider: any SubscriptionStatusProvider

    var premiumFramesUnlocked: Bool { provider.isPremium }
    var watermarkEnabled: Bool { !provider.isPremium }
    var maxSavedItems: Int? { provider.maxSavedItems }
}
