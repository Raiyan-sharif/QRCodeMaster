//
//  QRCreateView.swift
//  QRCodeMaster
//

import SwiftData
import SwiftUI

struct QRCreateView: View {
    var initialStyle: QRStyleOptions = .default

    @State private var payloadType: QRPayloadType = .text
    @State private var textPayload = ""
    @State private var wifi     = WiFiPayload()
    @State private var contact  = ContactPayload()
    @State private var sms      = SMSPayload()
    @State private var email    = EmailPayload()
    @State private var spotify  = SpotifyPayload()
    @State private var cal      = CalendarPayload()

    @State private var selectedCountry: CountryDialCode = .deviceDefault
    @State private var showCountryPicker = false
    @State private var navigateToCustomize = false

    // MARK: - Computed payload

    private var encodedPayload: String {
        // For phone-based types, prepend the selected country's dial code
        var resolvedText = textPayload
        switch payloadType {
        case .whatsapp, .line, .viber, .phone:
            let digits = textPayload.filter(\.isNumber)
            if !digits.isEmpty {
                resolvedText = selectedCountry.dialCode + digits
            }
        default:
            break
        }
        return QRPayloadEncoder.encode(
            type: payloadType, text: resolvedText,
            wifi: wifi, contact: contact, sms: sms,
            email: email, spotify: spotify, calendar: cal
        )
    }

    private var canCreate: Bool { !encodedPayload.isEmpty }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            contentCard
                .padding(.horizontal, 20)
                .padding(.top, 12)

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
            QRCustomizeView(payload: encodedPayload, payloadType: payloadType, initialStyle: initialStyle)
        }
    }

    // MARK: - Content card

    private var contentCard: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(payloadType.title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 8)

                Divider().padding(.horizontal, 16)

                inputFields
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxHeight: 260)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
        )
    }

    // MARK: - Input fields

    @ViewBuilder
    private var inputFields: some View {
        switch payloadType {

        // ── Simple text editor ──────────────────────────────────────────
        case .text:
            simpleEditor(placeholder: payloadType.inputPlaceholder)

        // ── Website (URL with shortcut prefixes) ────────────────────────
        case .url:
            VStack(alignment: .leading, spacing: 0) {
                simpleEditor(placeholder: payloadType.inputPlaceholder, keyboard: .URL)
                HStack(spacing: 8) {
                    ForEach(["https://", "http://", "www.", ".com"], id: \.self) { prefix in
                        Button {
                            if prefix == ".com" {
                                textPayload += ".com"
                            } else if !textPayload.lowercased().hasPrefix(prefix.lowercased()) {
                                textPayload = prefix + textPayload.trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                        } label: {
                            Text(prefix)
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.secondarySystemFill), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 6)
                .padding(.bottom, 4)
            }

        // ── Phone-number-based social ────────────────────────────────────
        case .whatsapp, .line, .viber:
            phoneInputView

        // ── Simple phone ─────────────────────────────────────────────────
        case .phone:
            simpleEditor(placeholder: payloadType.inputPlaceholder, keyboard: .phonePad)

        // ── Simple single-line types ─────────────────────────────────────
        case .instagram, .facebook, .youtube, .threads, .truthsocial,
             .pinterest, .snapchat, .x, .telegram, .tiktok,
             .discord, .review, .paypal, .linkedin, .reddit,
             .skype, .messenger, .wechat, .crypto:
            simpleEditor(placeholder: payloadType.inputPlaceholder)

        // ── Wi-Fi ────────────────────────────────────────────────────────
        case .wifi:
            VStack(spacing: 0) {
                inputRow(label: "Wi-Fi Name", binding: $wifi.ssid, placeholder: "My Network")
                Divider()
                Toggle(isOn: $wifi.hidden.not()) {}
                    .labelsHidden()
                HStack {
                    Text("Password Needed")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { wifi.security != .nopass },
                        set: { wifi.security = $0 ? .wpa : .nopass }
                    ))
                    .labelsHidden()
                }
                .padding(.vertical, 10)
                if wifi.security != .nopass {
                    Divider()
                    inputRow(label: "Password", binding: $wifi.password, placeholder: "Password", secure: true)
                }
            }
            .padding(.top, 4)

        // ── Contact (vCard) ──────────────────────────────────────────────
        case .contact:
            VStack(spacing: 0) {
                inputRow(label: "*Name(Required)", binding: $contact.fullName, placeholder: "Ada", required: true)
                Divider()
                inputRow(label: "*Phone Number(Required)", binding: $contact.phone, placeholder: "+123456789", keyboard: .phonePad, required: true)
                Divider()
                inputRow(label: "Fax Number", binding: $contact.fax, placeholder: "", keyboard: .phonePad)
                Divider()
                inputRow(label: "E-mail", binding: $contact.email, placeholder: "", keyboard: .emailAddress)
                Divider()
                inputRow(label: "Company", binding: $contact.company, placeholder: "")
                Divider()
                inputRow(label: "Job Title", binding: $contact.jobTitle, placeholder: "")
                Divider()
                inputRow(label: "Address", binding: $contact.address, placeholder: "")
                Divider()
                inputRow(label: "Website", binding: $contact.website, placeholder: "", keyboard: .URL)
                Divider()
                inputRow(label: "Memo", binding: $contact.memo, placeholder: "Please fill in more information")
            }
            .padding(.top, 4)

        // ── SMS ──────────────────────────────────────────────────────────
        case .sms:
            VStack(spacing: 0) {
                inputRow(label: "Recipient", binding: $sms.phone, placeholder: "Please fill in the recipient", keyboard: .phonePad)
                Divider()
                inputRow(label: "Message", binding: $sms.body, placeholder: "Please fill in the content")
            }
            .padding(.top, 4)

        // ── E-mail ───────────────────────────────────────────────────────
        case .email:
            VStack(alignment: .leading, spacing: 0) {
                TextField("e.g. example@mail.com", text: $email.address)
                    .font(.body)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                Divider()
                Text("Content")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                TextEditor(text: $email.body)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 60)
                    .overlay(alignment: .topLeading) {
                        if email.body.isEmpty {
                            Text("Please input email content")
                                .font(.body)
                                .foregroundStyle(Color(.placeholderText))
                                .padding(.top, 8)
                                .allowsHitTesting(false)
                        }
                    }
            }

        // ── Spotify ──────────────────────────────────────────────────────
        case .spotify:
            VStack(spacing: 0) {
                inputRow(label: "Artist", binding: $spotify.artist, placeholder: "Please fill in the artist's name")
                Divider()
                inputRow(label: "Song", binding: $spotify.song, placeholder: "Please fill in the song title")
            }
            .padding(.top, 4)

        // ── Calendar ─────────────────────────────────────────────────────
        case .calendar:
            VStack(spacing: 0) {
                inputRow(label: "Title", binding: $cal.title, placeholder: "")
                Divider()
                inputRow(label: "Location", binding: $cal.location, placeholder: "")
                Divider()
                DatePicker("Start", selection: $cal.startDate, displayedComponents: [.date, .hourAndMinute])
                    .font(.subheadline)
                    .padding(.vertical, 8)
                Divider()
                DatePicker("End", selection: $cal.endDate, in: cal.startDate..., displayedComponents: [.date, .hourAndMinute])
                    .font(.subheadline)
                    .padding(.vertical, 8)
                Divider()
                inputRow(label: "Description", binding: $cal.eventDescription, placeholder: "Please fill in more information")
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Reusable sub-views

    @ViewBuilder
    private func simpleEditor(placeholder: String, keyboard: UIKeyboardType = .default) -> some View {
        TextEditor(text: $textPayload)
            .font(.body)
            .keyboardType(keyboard)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .scrollContentBackground(.hidden)
            .frame(minHeight: 110)
            .overlay(alignment: .topLeading) {
                if textPayload.isEmpty {
                    Text(placeholder)
                        .font(.body)
                        .foregroundStyle(Color(.placeholderText))
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }
            }
            .padding(.top, 8)
    }

    private var phoneInputView: some View {
        HStack(spacing: 10) {
            // Tappable country code pill
            Button { showCountryPicker = true } label: {
                HStack(spacing: 5) {
                    Text(selectedCountry.flag)
                        .font(.title3)
                    Text(selectedCountry.dialCode)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showCountryPicker) {
                CountryPickerSheet(selected: $selectedCountry)
            }

            TextField("Phone Number", text: $textPayload)
                .keyboardType(.phonePad)
                .font(.body)
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private func inputRow(
        label: String,
        binding: Binding<String>,
        placeholder: String,
        secure: Bool = false,
        keyboard: UIKeyboardType = .default,
        required: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minWidth: 80, alignment: .leading)
            if secure {
                SecureField(placeholder.isEmpty ? label : placeholder, text: binding)
                    .font(.body)
            } else {
                TextField(placeholder.isEmpty ? label : placeholder, text: binding)
                    .font(.body)
                    .keyboardType(keyboard)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(keyboard == .emailAddress || keyboard == .URL ? .never : .sentences)
            }
        }
        .padding(.vertical, 11)
    }

    // MARK: - Type grid (4 pages)

    private var typeGrid: some View {
        let pages: [[QRPayloadType]] = [
            QRPayloadType.gridPage1,
            QRPayloadType.gridPage2,
            QRPayloadType.gridPage3,
            QRPayloadType.gridPage4,
        ]

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
        .frame(height: 195)
    }

    private func typeButton(_ type: QRPayloadType) -> some View {
        Button {
            payloadType = type
            textPayload = ""
            selectedCountry = .deviceDefault
        } label: {
            VStack(spacing: 6) {
                typeIconView(type)
                    .frame(width: 54, height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(payloadType == type ? Color(red: 0.18, green: 0.72, blue: 0.65) : Color.clear, lineWidth: 2.5)
                    )
                Text(type.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(payloadType == type ? Color(red: 0.18, green: 0.72, blue: 0.65) : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func typeIconView(_ type: QRPayloadType) -> some View {
        ZStack {
            Rectangle().fill(typeGradient(for: type))
            Image(systemName: typeSFSymbol(for: type))
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
        }
    }

    private func typeSFSymbol(for type: QRPayloadType) -> String {
        switch type {
        case .text:        "textformat.alt"
        case .url:         "link"
        case .instagram:   "camera.fill"
        case .contact:     "person.crop.rectangle.fill"
        case .facebook:    "person.2.fill"
        case .wifi:        "wifi"
        case .whatsapp:    "bubble.left.fill"
        case .youtube:     "play.rectangle.fill"
        case .email:       "envelope.fill"
        case .review:      "star.bubble.fill"
        case .threads:     "at"
        case .discord:     "gamecontroller.fill"
        case .sms:         "message.fill"
        case .tiktok:      "music.note"
        case .line:        "phone.bubble.fill"
        case .phone:       "phone.fill"
        case .truthsocial: "bubble.left.and.text.bubble.right.fill"
        case .spotify:     "music.note.list"
        case .paypal:      "creditcard.fill"
        case .linkedin:    "briefcase.fill"
        case .calendar:    "calendar"
        case .crypto:      "bitcoinsign.circle.fill"
        case .reddit:      "bubble.right.fill"
        case .skype:       "video.fill"
        case .messenger:   "message.badge.filled.fill"
        case .pinterest:   "pin.fill"
        case .viber:       "phone.arrow.up.right.fill"
        case .wechat:      "ellipsis.bubble.fill"
        case .x:           "xmark.circle.fill"
        case .telegram:    "paperplane.fill"
        case .snapchat:    "camera.viewfinder"
        }
    }

    private func typeGradient(for type: QRPayloadType) -> LinearGradient {
        func grad(_ a: Color, _ b: Color) -> LinearGradient {
            LinearGradient(colors: [a, b], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        switch type {
        case .text:        return grad(.init(red: 0.18, green: 0.72, blue: 0.65), .init(red: 0.1,  green: 0.55, blue: 0.52))
        case .url:         return grad(.init(red: 0.18, green: 0.72, blue: 0.65), .init(red: 0.1,  green: 0.62, blue: 0.35))
        case .instagram:   return grad(.init(red: 0.85, green: 0.22, blue: 0.52), .init(red: 0.98, green: 0.55, blue: 0.15))
        case .contact:     return grad(.init(red: 0.18, green: 0.62, blue: 0.88), .init(red: 0.12, green: 0.45, blue: 0.75))
        case .facebook:    return grad(.init(red: 0.23, green: 0.38, blue: 0.68), .init(red: 0.18, green: 0.28, blue: 0.55))
        case .wifi:        return grad(.init(red: 0.18, green: 0.72, blue: 0.82), .init(red: 0.12, green: 0.52, blue: 0.68))
        case .whatsapp:    return grad(.init(red: 0.15, green: 0.72, blue: 0.35), .init(red: 0.08, green: 0.55, blue: 0.25))
        case .youtube:     return grad(.init(red: 0.95, green: 0.18, blue: 0.18), .init(red: 0.75, green: 0.1,  blue: 0.1))
        case .email:       return grad(.init(red: 0.15, green: 0.62, blue: 0.38), .init(red: 0.08, green: 0.48, blue: 0.28))
        case .review:      return grad(.init(red: 0.95, green: 0.72, blue: 0.1),  .init(red: 0.88, green: 0.55, blue: 0.05))
        case .threads:     return grad(.init(red: 0.1,  green: 0.1,  blue: 0.1),  .init(red: 0.25, green: 0.25, blue: 0.25))
        case .discord:     return grad(.init(red: 0.34, green: 0.38, blue: 0.88), .init(red: 0.22, green: 0.25, blue: 0.72))
        case .sms:         return grad(.init(red: 0.45, green: 0.72, blue: 0.22), .init(red: 0.32, green: 0.55, blue: 0.12))
        case .tiktok:      return grad(.init(red: 0.05, green: 0.05, blue: 0.05), .init(red: 0.2,  green: 0.2,  blue: 0.2))
        case .line:        return grad(.init(red: 0.08, green: 0.72, blue: 0.35), .init(red: 0.05, green: 0.55, blue: 0.25))
        case .phone:       return grad(.init(red: 0.18, green: 0.52, blue: 0.88), .init(red: 0.12, green: 0.38, blue: 0.72))
        case .truthsocial: return grad(.init(red: 0.92, green: 0.28, blue: 0.18), .init(red: 0.72, green: 0.15, blue: 0.08))
        case .spotify:     return grad(.init(red: 0.1,  green: 0.62, blue: 0.22), .init(red: 0.05, green: 0.45, blue: 0.15))
        case .paypal:      return grad(.init(red: 0.1,  green: 0.38, blue: 0.72), .init(red: 0.05, green: 0.25, blue: 0.55))
        case .linkedin:    return grad(.init(red: 0.12, green: 0.35, blue: 0.65), .init(red: 0.05, green: 0.22, blue: 0.48))
        case .calendar:    return grad(.init(red: 0.92, green: 0.22, blue: 0.22), .init(red: 0.72, green: 0.12, blue: 0.12))
        case .crypto:      return grad(.init(red: 0.95, green: 0.58, blue: 0.1),  .init(red: 0.82, green: 0.42, blue: 0.05))
        case .reddit:      return grad(.init(red: 0.95, green: 0.35, blue: 0.1),  .init(red: 0.82, green: 0.22, blue: 0.05))
        case .skype:       return grad(.init(red: 0.15, green: 0.55, blue: 0.88), .init(red: 0.08, green: 0.38, blue: 0.72))
        case .messenger:   return grad(.init(red: 0.25, green: 0.48, blue: 0.95), .init(red: 0.52, green: 0.18, blue: 0.88))
        case .pinterest:   return grad(.init(red: 0.85, green: 0.12, blue: 0.18), .init(red: 0.68, green: 0.05, blue: 0.12))
        case .viber:       return grad(.init(red: 0.52, green: 0.22, blue: 0.82), .init(red: 0.38, green: 0.12, blue: 0.65))
        case .wechat:      return grad(.init(red: 0.12, green: 0.72, blue: 0.28), .init(red: 0.05, green: 0.55, blue: 0.18))
        case .x:           return grad(.init(red: 0.08, green: 0.08, blue: 0.08), .init(red: 0.22, green: 0.22, blue: 0.22))
        case .telegram:    return grad(.init(red: 0.15, green: 0.62, blue: 0.92), .init(red: 0.08, green: 0.45, blue: 0.78))
        case .snapchat:    return grad(.init(red: 0.98, green: 0.88, blue: 0.05), .init(red: 0.88, green: 0.72, blue: 0.0))
        }
    }
}

// MARK: - Bool helper

private extension Binding where Value == Bool {
    func not() -> Binding<Bool> {
        Binding<Bool>(get: { !self.wrappedValue }, set: { self.wrappedValue = !$0 })
    }
}

#Preview {
    NavigationStack {
        QRCreateView()
    }
    .modelContainer(AppModelContainer.make(inMemory: true))
}
