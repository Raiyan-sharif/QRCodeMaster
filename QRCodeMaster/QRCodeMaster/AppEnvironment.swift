//
//  AppEnvironment.swift
//  QRCodeMaster
//

import SwiftUI

private struct SubscriptionStatusKey: EnvironmentKey {
    static let defaultValue: any SubscriptionStatusProvider = FreeSubscriptionStatus()
}

private struct FeatureFlagsKey: EnvironmentKey {
    static let defaultValue: FeatureFlags = FeatureFlags(provider: FreeSubscriptionStatus())
}

extension EnvironmentValues {
    var subscriptionStatus: any SubscriptionStatusProvider {
        get { self[SubscriptionStatusKey.self] }
        set { self[SubscriptionStatusKey.self] = newValue }
    }

    var featureFlags: FeatureFlags {
        get { self[FeatureFlagsKey.self] }
        set { self[FeatureFlagsKey.self] = newValue }
    }
}
