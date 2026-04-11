//
//  Folder.swift
//  QRCodeMaster
//

import Foundation
import SwiftData

@Model
final class Folder {
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \SavedCode.folder)
    var items: [SavedCode]

    init(name: String, createdAt: Date = .now) {
        self.name = name
        self.createdAt = createdAt
        self.items = []
    }
}
