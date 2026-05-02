//
//  ModelContainer+App.swift
//  QRCodeMaster
//

import Foundation
import SwiftData

enum AppModelContainer {
    static func make(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema([SavedCode.self, Folder.self])
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else {
            // Create Application Support before SwiftData opens the store. On some
            // simulators/devices the directory is missing briefly, which spams
            // Core Data errors and can contribute to flaky startup.
            let appSupport: URL
            do {
                appSupport = try FileManager.default.url(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )
                try FileManager.default.createDirectory(
                    at: appSupport,
                    withIntermediateDirectories: true
                )
            } catch {
                fatalError("Failed to prepare Application Support for SwiftData: \(error)")
            }
            let storeURL = appSupport.appending(path: "default.store")
            configuration = ModelConfiguration(schema: schema, url: storeURL)
        }
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
