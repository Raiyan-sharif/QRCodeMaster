//
//  CodeDetailView.swift
//  QRCodeMaster
//

import SwiftData
import SwiftUI

struct CodeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Folder.createdAt, order: .forward) private var folders: [Folder]

    @Bindable var item: SavedCode

    @State private var showSharePayload = false
    @State private var showShareImage = false
    @State private var showRename = false
    @State private var editTitle = ""

    var body: some View {
        List {
            if let d = item.thumbnailData, let img = UIImage(data: d) {
                Section {
                    Image(uiImage: img)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 280)
                }
            }

            Section("Payload") {
                Text(item.payload)
                    .font(.body)
                    .textSelection(.enabled)
            }

            Section("Details") {
                Toggle("Favorite", isOn: $item.isFavorite)
                Picker("Folder", selection: $item.folder) {
                    Text("None").tag(nil as Folder?)
                    ForEach(folders) { f in
                        Text(f.name).tag(f as Folder?)
                    }
                }
                Text("Created \(item.createdAt.formatted(date: .long, time: .shortened))")
                    .foregroundStyle(.secondary)
                if let sym = item.barcodeSymbology {
                    Text("Symbology: \(sym)")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button("Share text") { showSharePayload = true }
                if item.thumbnailData != nil {
                    Button("Share image") { showShareImage = true }
                }
            }
        }
        .navigationTitle(item.title ?? "Code")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Rename") {
                    editTitle = item.title ?? ""
                    showRename = true
                }
            }
        }
        .alert("Rename", isPresented: $showRename) {
            TextField("Title", text: $editTitle)
            Button("Save") {
                let t = editTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                item.title = t.isEmpty ? nil : t
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showSharePayload) {
            ActivityView(items: [item.payload])
        }
        .sheet(isPresented: $showShareImage) {
            if let d = item.thumbnailData, let img = UIImage(data: d) {
                ActivityView(items: [img])
            }
        }
    }
}
