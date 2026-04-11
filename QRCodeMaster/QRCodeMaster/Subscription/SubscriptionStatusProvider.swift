//
//  SubscriptionStatusProvider.swift
//  QRCodeMaster
//

import Foundation

/// Future StoreKit-backed implementation can replace `FreeSubscriptionStatus`.
protocol SubscriptionStatusProvider: Sendable {
    var isPremium: Bool { get }
    var maxSavedItems: Int? { get }
}

/// Default: unlimited, all features on; swap when IAP ships.
struct FreeSubscriptionStatus: SubscriptionStatusProvider, Sendable {
    var isPremium: Bool { true }
    var maxSavedItems: Int? { nil }
}
