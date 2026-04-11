//
//  BarcodeCreateView.swift
//  QRCodeMaster
//

import SwiftData
import SwiftUI

struct BarcodeCreateView: View {
    @Environment(\.modelContext) private var modelContext

    enum Kind: String, CaseIterable, Identifiable {
        case code128
        case ean13
        case upca

        var id: String { rawValue }

        var title: String {
            switch self {
            case .code128: "Code 128"
            case .ean13: "EAN-13"
            case .upca: "UPC-A"
            }
        }
    }

    @State private var kind: Kind = .code128
    @State private var text = ""
    @State private var digits = ""
    @State private var rendered: UIImage?
    @State private var showShare = false
    @State private var saveError: String?
    @State private var showSaveError = false
    @State private var showLimitAlert = false

    @Environment(\.featureFlags) private var features

    var body: some View {
        Form {
            Section("Type") {
                Picker("Symbology", selection: $kind) {
                    ForEach(Kind.allCases) { k in
                        Text(k.title).tag(k)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Payload") {
                switch kind {
                case .code128:
                    TextField("Any ASCII text", text: $text, axis: .vertical)
                        .lineLimit(2...8)
                case .ean13:
                    TextField("12 or 13 digits", text: $digits)
                        .keyboardType(.numberPad)
                case .upca:
                    TextField("11 or 12 digits", text: $digits)
                        .keyboardType(.numberPad)
                }
            }

            Section {
                if let rendered {
                    Image(uiImage: rendered)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 160)
                } else {
                    ContentUnavailableView("Preview", systemImage: "barcode", description: Text("Enter a valid payload."))
                        .frame(height: 120)
                }
            }

            Section {
                Button("Update preview") { regenerate() }
                Button("Save to Library (app)") { saveApp() }
                    .disabled(rendered == nil)
                Button("Save to Photos") { Task { await savePhotos() } }
                    .disabled(rendered == nil)
                Button("Share…") { showShare = true }
                    .disabled(rendered == nil)
            }
        }
        .navigationTitle("Barcode")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { regenerate() }
        .onChange(of: kind) { _, _ in regenerate() }
        .onChange(of: text) { _, _ in regenerate() }
        .onChange(of: digits) { _, _ in regenerate() }
        .sheet(isPresented: $showShare) {
            if let rendered { ActivityView(items: [rendered]) }
        }
        .alert("Could not save", isPresented: $showSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveError ?? "")
        }
        .alert("Save limit reached", isPresented: $showLimitAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Upgrade to save more items.")
        }
    }

    private func regenerate() {
        switch kind {
        case .code128:
            rendered = BarcodeGeneratorService.code128(text)
        case .ean13:
            rendered = EAN13Encoder.image(digits: digits)
        case .upca:
            rendered = BarcodeGeneratorService.upcA(digits: digits)
        }
    }

    private var storedPayload: String {
        switch kind {
        case .code128: return text
        case .ean13, .upca: return digits.filter(\.isNumber)
        }
    }

    private var symbology: String {
        switch kind {
        case .code128: return "code128"
        case .ean13: return "ean13"
        case .upca: return "upca"
        }
    }

    private func saveApp() {
        if let max = features.maxSavedItems {
            let count = (try? modelContext.fetchCount(FetchDescriptor<SavedCode>())) ?? 0
            if count >= max {
                showLimitAlert = true
                return
            }
        }
        guard let img = rendered, let data = img.pngData() else { return }
        let title = kind.title + " · " + Date.now.formatted(date: .abbreviated, time: .shortened)
        let item = SavedCode(
            kind: .barcode,
            payload: storedPayload,
            title: title,
            thumbnailData: data,
            source: .created,
            barcodeSymbology: symbology
        )
        modelContext.insert(item)
        try? modelContext.save()
    }

    private func savePhotos() async {
        guard let img = rendered else { return }
        do {
            try await PhotoLibrarySaver.save(img)
        } catch {
            saveError = error.localizedDescription
            showSaveError = true
        }
    }
}
