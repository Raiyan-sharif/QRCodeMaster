//
//  QRCodeMasterApp.swift
//  QRCodeMaster
//
//  Created by Raiyan Sharif on 11/4/26.
//

import SwiftData
import SwiftUI

@main
struct QRCodeMasterApp: App {
    private let subscription = FreeSubscriptionStatus()
    private let container = AppModelContainer.make(inMemory: false)

    init() {
        #if DEBUG
        EAN13Encoder.runSelfCheck()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(container)
                .environment(\.subscriptionStatus, subscription)
                .environment(\.featureFlags, FeatureFlags(provider: subscription))
        }
    }
}
