//
//  QRCreateView.swift
//  QRCodeMaster
//

import SwiftData
import SwiftUI

struct QRCreateView: View {
    /// Pre-selected style (e.g. template chosen from TemplateHomeView).
    var initialStyle: QRStyleOptions = .default

    @State private var payloadType: QRPayloadType = .text
    @State private var textPayload = ""
    @State private var wifi    = WiFiPayload(ssid: "", password: "", security: .wpa, hidden: false)
    @State private var contact = ContactPayload(fullName: "", phone: "", email: "", organization: "")
    @State private var sms     = SMSPayload(phone: "", body: "")

    @State private var navigateToCustomize = false

    // MARK: - Computed payload

    private var encodedPayload: String {
        QRPayloadEncoder.encode(type: payloadType, text: textPayload, wifi: wifi, contact: contact, sms: sms)
    }

    private var canCreate: Bool { !encodedPayload.isEmpty }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            contentCard
                .padding(.horizontal, 20)
                .padding(.top, 12)

            // Character-count hint
            if let threshold = payloadType.textWarningThreshold {
                Text("The QR Code will be difficult to recognize when the content exceeds \(threshold) characters")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
            }

            Spacer(minLength: 12)

            typeGrid
                .padding(.bottom, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Create")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Create") { navigateToCustomize = true }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.18, green: 0.72, blue: 0.65))
                    .disabled(!canCreate)
            }
        }
        .navigationDestination(isPresented: $navigateToCustomize) {
            QRCustomizeView(
                payload: encodedPayload,
                payloadType: payloadType,
                initialStyle: initialStyle
            )
        }
    }

    // MARK: - Content card

    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(payloadType.title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, 16)

            inputFields
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
        )
    }

    @ViewBuilder
    private var inputFields: some View {
        switch payloadType {
        case .text, .url, .instagram, .facebook, .whatsapp, .youtube:
            TextEditor(text: $textPayload)
                .font(.body)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 130)
                .overlay(alignment: .topLeading) {
                    if textPayload.isEmpty {
                        Text(payloadType.inputPlaceholder)
                            .font(.body)
                            .foregroundStyle(Color(.placeholderText))
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                    }
                }
                .padding(.top, 8)

        case .wifi:
            VStack(spacing: 0) {
                inputRow(label: "Network (SSID)", binding: $wifi.ssid, placeholder: "My Network")
                Divider()
                inputRow(label: "Password", binding: $wifi.password, placeholder: "••••••••", secure: true)
                Divider()
                HStack {
                    Text("Security")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                    Spacer()
                    Picker("", selection: $wifi.security) {
                        ForEach(WiFiPayload.WiFiSecurity.allCases) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                    .labelsHidden()
                }
                .padding(.vertical, 10)
                Divider()
                Toggle("Hidden network", isOn: $wifi.hidden)
                    .font(.subheadline)
                    .padding(.vertical, 10)
            }
            .padding(.top, 4)

        case .contact:
            VStack(spacing: 0) {
                inputRow(label: "Name",         binding: $contact.fullName,    placeholder: "Full Name")
                Divider()
                inputRow(label: "Phone",        binding: $contact.phone,       placeholder: "+1 555 000 0000", keyboard: .phonePad)
                Divider()
                inputRow(label: "Email",        binding: $contact.email,       placeholder: "email@example.com", keyboard: .emailAddress)
                Divider()
                inputRow(label: "Organisation", binding: $contact.organization, placeholder: "Company")
            }
            .padding(.top, 4)

        case .sms:
            VStack(spacing: 0) {
                inputRow(label: "Phone",   binding: $sms.phone, placeholder: "+1 555 000 0000", keyboard: .phonePad)
                Divider()
                inputRow(label: "Message", binding: $sms.body,  placeholder: "Optional message")
            }
            .padding(.top, 4)
        }
    }

    private func inputRow(
        label: String,
        binding: Binding<String>,
        placeholder: String,
        secure: Bool = false,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            if secure {
                SecureField(placeholder, text: binding)
                    .font(.body)
            } else {
                TextField(placeholder, text: binding)
                    .font(.body)
                    .keyboardType(keyboard)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(keyboard == .emailAddress ? .never : .sentences)
            }
        }
        .padding(.vertical, 11)
    }

    // MARK: - Type picker grid

    private var typeGrid: some View {
        let pages: [[QRPayloadType]] = [QRPayloadType.gridPage1, QRPayloadType.gridPage2]

        return TabView {
            ForEach(pages.indices, id: \.self) { idx in
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4),
                    spacing: 10
                ) {
                    ForEach(pages[idx]) { type in
                        typeButton(type)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: 190)
    }

    private func typeButton(_ type: QRPayloadType) -> some View {
        Button { payloadType = type } label: {
            VStack(spacing: 8) {
                typeIconView(type)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(payloadType == type ? Color(red: 0.18, green: 0.72, blue: 0.65) : Color.clear, lineWidth: 2.5)
                    )
                Text(type.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func typeIconView(_ type: QRPayloadType) -> some View {
        ZStack {
            Rectangle().fill(typeGradient(for: type))
            Image(systemName: typeSFSymbol(for: type))
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white)
        }
    }

    private func typeSFSymbol(for type: QRPayloadType) -> String {
        switch type {
        case .text:      "textformat.alt"
        case .url:       "link"
        case .instagram: "camera.fill"
        case .contact:   "person.crop.rectangle.fill"
        case .facebook:  "person.2.fill"
        case .wifi:      "wifi"
        case .whatsapp:  "bubble.left.fill"
        case .youtube:   "play.rectangle.fill"
        case .sms:       "message.fill"
        }
    }

    private func typeGradient(for type: QRPayloadType) -> LinearGradient {
        let colors: [Color] = {
            switch type {
            case .text:
                return [Color(red: 0.18, green: 0.72, blue: 0.65), Color(red: 0.1, green: 0.55, blue: 0.52)]
            case .url:
                return [Color(red: 0.18, green: 0.72, blue: 0.65), Color(red: 0.1, green: 0.62, blue: 0.35)]
            case .instagram:
                return [Color(red: 0.85, green: 0.22, blue: 0.52), Color(red: 0.98, green: 0.55, blue: 0.15)]
            case .contact:
                return [Color(red: 0.18, green: 0.62, blue: 0.88), Color(red: 0.12, green: 0.45, blue: 0.75)]
            case .facebook:
                return [Color(red: 0.23, green: 0.38, blue: 0.68), Color(red: 0.18, green: 0.28, blue: 0.55)]
            case .wifi:
                return [Color(red: 0.18, green: 0.72, blue: 0.82), Color(red: 0.12, green: 0.52, blue: 0.68)]
            case .whatsapp:
                return [Color(red: 0.15, green: 0.72, blue: 0.35), Color(red: 0.08, green: 0.55, blue: 0.25)]
            case .youtube:
                return [Color(red: 0.95, green: 0.18, blue: 0.18), Color(red: 0.75, green: 0.1, blue: 0.1)]
            case .sms:
                return [Color(red: 0.45, green: 0.72, blue: 0.22), Color(red: 0.32, green: 0.55, blue: 0.12)]
            }
        }()
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

#Preview {
    NavigationStack {
        QRCreateView()
    }
    .modelContainer(AppModelContainer.make(inMemory: true))
}
