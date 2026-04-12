//
//  LibraryFilteredView.swift
//  QRCodeMaster
//

import SwiftData
import SwiftUI

/// Single-purpose list for Settings / Mine menu (created vs scanned vs favorites).
struct LibraryFilteredView: View {
    enum Filter {
        case created
        case scanned
        case favorites
    }

    let filter: Filter

    @Query(sort: \SavedCode.createdAt, order: .reverse) private var allItems: [SavedCode]

    private var items: [SavedCode] {
        switch filter {
        case .created:
            return allItems.filter { $0.resolvedSource == .created }
        case .scanned:
            return allItems.filter { $0.resolvedSource == .scanned }
        case .favorites:
            return allItems.filter { $0.isFavorite }
        }
    }

    var body: some View {
        Group {
            if items.isEmpty {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: emptySymbol,
                    description: Text(emptyDescription)
                )
            } else {
                List {
                    ForEach(items) { item in
                        NavigationLink {
                            CodeDetailView(item: item)
                        } label: {
                            LibraryFilteredRow(item: item)
                        }
                    }
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var navigationTitle: String {
        switch filter {
        case .created: return "Create History"
        case .scanned: return "Scan History"
        case .favorites: return "Favorite Templates"
        }
    }

    private var emptyTitle: String {
        switch filter {
        case .created: return "No created codes"
        case .scanned: return "No scans yet"
        case .favorites: return "No favorites"
        }
    }

    private var emptySymbol: String {
        switch filter {
        case .created: return "clock"
        case .scanned: return "viewfinder"
        case .favorites: return "heart"
        }
    }

    private var emptyDescription: String {
        switch filter {
        case .created: return "Codes you generate appear here."
        case .scanned: return "Point the scanner at a code to save it."
        case .favorites: return "Star items in your library to see them here."
        }
    }
}

private struct LibraryFilteredRow: View {
    let item: SavedCode

    var body: some View {
        HStack(spacing: 12) {
            if let d = item.thumbnailData, let img = UIImage(data: d) {
                Image(uiImage: img)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .cornerRadius(6)
            } else {
                Image(systemName: item.resolvedKind == .qr ? "qrcode" : "barcode")
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(displayTitle)
                    .font(.body.weight(.medium))
                    .lineLimit(2)
                Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    private var displayTitle: String {
        if let t = item.title, !t.isEmpty { return t }
        let p = item.payload
        if p.count <= 60 { return p }
        return String(p.prefix(60)) + "…"
    }
}

#Preview {
    NavigationStack {
        LibraryFilteredView(filter: .created)
    }
    .modelContainer(AppModelContainer.make(inMemory: true))
}
