//
//  LibraryView.swift
//  QRCodeMaster
//

import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Folder.createdAt, order: .forward) private var folders: [Folder]
    @Query(sort: \SavedCode.createdAt, order: .reverse) private var allItems: [SavedCode]

    @State private var search = ""
    @State private var selectedFolder: Folder?
    @State private var newFolderName = ""
    @State private var showNewFolder = false

    private var filtered: [SavedCode] {
        let inFolder: [SavedCode] = {
            guard let sel = selectedFolder else { return allItems }
            return allItems.filter { $0.folder?.persistentModelID == sel.persistentModelID }
        }()

        let q = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return inFolder }

        return inFolder.filter { item in
            item.payload.localizedCaseInsensitiveContains(q)
                || (item.title ?? "").localizedCaseInsensitiveContains(q)
                || (item.barcodeSymbology ?? "").localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        List {
            if !folders.isEmpty {
                Section("Folders") {
                    Button {
                        selectedFolder = nil
                    } label: {
                        HStack {
                            Text("All items")
                            Spacer()
                            if selectedFolder == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    ForEach(folders) { f in
                        Button {
                            selectedFolder = f
                        } label: {
                            HStack {
                                Text(f.name)
                                Spacer()
                                if selectedFolder?.persistentModelID == f.persistentModelID {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }

            Section {
                ForEach(filtered) { item in
                    NavigationLink {
                        CodeDetailView(item: item)
                    } label: {
                        LibraryRow(item: item)
                    }
                }
                .onDelete(perform: deleteItems)
            }
        }
        .searchable(text: $search, prompt: "Search payload or title")
        .navigationTitle("Drafts")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    newFolderName = ""
                    showNewFolder = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                }
            }
        }
        .alert("New folder", isPresented: $showNewFolder) {
            TextField("Name", text: $newFolderName)
            Button("Create") { createFolder() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Organize saved codes into folders.")
        }
    }

    private func createFolder() {
        let name = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        modelContext.insert(Folder(name: name))
        try? modelContext.save()
    }

    private func deleteItems(at offsets: IndexSet) {
        let snapshot = filtered
        for index in offsets {
            guard snapshot.indices.contains(index) else { continue }
            deleteItem(snapshot[index])
        }
    }

    private func deleteItem(_ item: SavedCode) {
        modelContext.delete(item)
        try? modelContext.save()
    }
}

private struct LibraryRow: View {
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
            if item.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
            }
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
        LibraryView()
    }
    .modelContainer(AppModelContainer.make(inMemory: true))
}
