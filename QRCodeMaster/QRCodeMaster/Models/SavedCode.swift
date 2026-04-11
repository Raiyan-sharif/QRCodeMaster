//
//  SavedCode.swift
//  QRCodeMaster
//

import Foundation
import SwiftData

enum SavedCodeKind: String, Codable, CaseIterable, Sendable {
    case qr
    case barcode
}

enum SavedCodeSource: String, Codable, CaseIterable, Sendable {
    case created
    case scanned
}

@Model
final class SavedCode {
    var kindRaw: String
    var payload: String
    var title: String?
    var createdAt: Date
    var isFavorite: Bool
    @Attribute(.externalStorage)
    var thumbnailData: Data?
    var sourceRaw: String
    var barcodeSymbology: String?
    var styleOptionsJSON: Data?
    var folder: Folder?

    init(
        kind: SavedCodeKind,
        payload: String,
        title: String? = nil,
        createdAt: Date = .now,
        isFavorite: Bool = false,
        thumbnailData: Data? = nil,
        source: SavedCodeSource,
        barcodeSymbology: String? = nil,
        styleOptionsJSON: Data? = nil,
        folder: Folder? = nil
    ) {
        self.kindRaw = kind.rawValue
        self.payload = payload
        self.title = title
        self.createdAt = createdAt
        self.isFavorite = isFavorite
        self.thumbnailData = thumbnailData
        self.sourceRaw = source.rawValue
        self.barcodeSymbology = barcodeSymbology
        self.styleOptionsJSON = styleOptionsJSON
        self.folder = folder
    }
}

extension SavedCode {
    var resolvedKind: SavedCodeKind {
        SavedCodeKind(rawValue: kindRaw) ?? .qr
    }

    var resolvedSource: SavedCodeSource {
        SavedCodeSource(rawValue: sourceRaw) ?? .created
    }
}
