//
//  QRCreateView.swift
//  QRCodeMaster
//

import PhotosUI
import SwiftData
import SwiftUI

struct QRCreateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.featureFlags) private var features

    @State private var payloadType: QRPayloadType = .text
    @State private var textPayload = ""
    @State private var wifi = WiFiPayload(ssid: "", password: "", security: .wpa, hidden: false)
    @State private var contact = ContactPayload(fullName: "", phone: "", email: "", organization: "")
    @State private var sms = SMSPayload(phone: "", body: "")
    @State private var style = QRStyleOptions.default
    @State private var logoItem: PhotosPickerItem?
    @State private var logoImage: UIImage?
    @State private var rendered: UIImage?
    @State private var showShare = false
    @State private var saveError: String?
    @State private var showSaveError = false
    @State private var showLimitAlert = false

    private var encodedPayload: String {
        QRPayloadEncoder.encode(
            type: payloadType,
            text: textPayload,
            wifi: wifi,
            contact: contact,
            sms: sms
        )
    }

    var body: some View {
        Form {
            Section("Content") {
                Picker("Type", selection: $payloadType) {
                    ForEach(QRPayloadType.allCases) { t in
                        Text(t.title).tag(t)
                    }
                }
                switch payloadType {
                case .text, .url:
                    TextField(payloadType == .url ? "https://example.com" : "Text", text: $textPayload, axis: .vertical)
                        .lineLimit(3...8)
                case .wifi:
                    TextField("Network name (SSID)", text: $wifi.ssid)
                    SecureField("Password", text: $wifi.password)
                    Picker("Security", selection: $wifi.security) {
                        ForEach(WiFiPayload.WiFiSecurity.allCases) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                    Toggle("Hidden network", isOn: $wifi.hidden)
                case .contact:
                    TextField("Name", text: $contact.fullName)
                    TextField("Phone", text: $contact.phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $contact.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Organization", text: $contact.organization)
                case .sms:
                    TextField("Phone number", text: $sms.phone)
                        .keyboardType(.phonePad)
                    TextField("Message (optional)", text: $sms.body, axis: .vertical)
                        .lineLimit(2...6)
                }
            }

            Section("Style") {
                ColorPicker("Foreground", selection: bindingHex(\.foregroundHex, default: "#000000"))
                ColorPicker("Background", selection: bindingHex(\.backgroundHex, default: "#FFFFFF"))
                Picker("Error correction", selection: $style.errorCorrection) {
                    Text("L ~7%").tag("L")
                    Text("M ~15%").tag("M")
                    Text("Q ~25%").tag("Q")
                    Text("H ~30%").tag("H")
                }
                Picker("Module shape", selection: $style.moduleShape) {
                    Text("Square").tag(QRStyleOptions.ModuleShape.square)
                    Text("Rounded").tag(QRStyleOptions.ModuleShape.rounded)
                    Text("Dot").tag(QRStyleOptions.ModuleShape.dot)
                }
                Picker("Finder eyes", selection: $style.eyeStyle) {
                    Text("Square").tag(QRStyleOptions.EyeStyle.square)
                    Text("Rounded").tag(QRStyleOptions.EyeStyle.roundedLeaf)
                    Text("Circle").tag(QRStyleOptions.EyeStyle.circle)
                }
                Toggle("Decorative frame", isOn: Binding(
                    get: { style.frameId != nil },
                    set: { style.frameId = $0 ? "default" : nil }
                ))
                PhotosPicker(selection: $logoItem, matching: .images, photoLibrary: .shared()) {
                    Label(logoImage == nil ? "Add logo" : "Change logo", systemImage: "photo")
                }
                if logoImage != nil {
                    Button("Remove logo", role: .destructive) {
                        logoImage = nil
                        logoItem = nil
                    }
                }
            }

            Section {
                if let rendered {
                    Image(uiImage: rendered)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 220)
                        .padding(.vertical, 8)
                } else {
                    ContentUnavailableView("Preview", systemImage: "qrcode", description: Text("Enter content to generate a QR code."))
                        .frame(height: 160)
                }
            }

            Section {
                Button("Regenerate preview") {
                    regenerate()
                }
                .disabled(encodedPayload.isEmpty)

                Button("Save to Library (app)") {
                    saveToAppLibrary()
                }
                .disabled(rendered == nil)

                Button("Save to Photos") {
                    Task { await saveToPhotos() }
                }
                .disabled(rendered == nil)

                Button("Share…") {
                    showShare = true
                }
                .disabled(rendered == nil)
            }
        }
        .navigationTitle("QR code")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { regenerate() }
        .onChange(of: encodedPayload) { _, _ in regenerate() }
        .onChange(of: style) { _, _ in regenerate() }
        .onChange(of: logoImage) { _, _ in regenerate() }
        .onChange(of: logoItem) { _, new in
            Task {
                if let new, let data = try? await new.loadTransferable(type: Data.self) {
                    logoImage = UIImage(data: data)
                } else {
                    logoImage = nil
                }
            }
        }
        .sheet(isPresented: $showShare) {
            if let rendered {
                ActivityView(items: [rendered])
            }
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

    private func bindingHex(_ keyPath: WritableKeyPath<QRStyleOptions, String>, default def: String) -> Binding<Color> {
        Binding(
            get: {
                Color(uiColor: UIColor(hex: style[keyPath: keyPath]) ?? UIColor(hex: def) ?? .black)
            },
            set: { color in
                var next = style
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
                let ir = Int(round(r * 255)), ig = Int(round(g * 255)), ib = Int(round(b * 255))
                next[keyPath: keyPath] = String(format: "#%02X%02X%02X", ir, ig, ib)
                style = next
            }
        )
    }

    private func regenerate() {
        let msg = encodedPayload
        guard !msg.isEmpty else {
            rendered = nil
            return
        }
        rendered = QRStyleRenderer.render(
            message: msg,
            options: style,
            logo: logoImage,
            outputPoints: 512,
            showWatermark: features.watermarkEnabled
        )
    }

    private func saveToAppLibrary() {
        if let max = features.maxSavedItems {
            let count = (try? modelContext.fetchCount(FetchDescriptor<SavedCode>())) ?? 0
            if count >= max {
                showLimitAlert = true
                return
            }
        }
        guard let img = rendered, let data = img.pngData() else { return }
        let json = try? JSONEncoder().encode(style)
        let title = payloadType.title + " · " + Date.now.formatted(date: .abbreviated, time: .shortened)
        let item = SavedCode(
            kind: .qr,
            payload: encodedPayload,
            title: title,
            thumbnailData: data,
            source: .created,
            styleOptionsJSON: json
        )
        modelContext.insert(item)
        try? modelContext.save()
    }

    private func saveToPhotos() async {
        guard let img = rendered else { return }
        do {
            try await PhotoLibrarySaver.save(img)
        } catch {
            saveError = error.localizedDescription
            showSaveError = true
        }
    }
}
