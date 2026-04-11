//
//  ModelContainer+App.swift
//  QRCodeMaster
//

import SwiftData

enum AppModelContainer {
    static func make(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema([SavedCode.self, Folder.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
