//
//  QRPayloadEncoder.swift
//  QRCodeMaster
//

import Foundation

enum QRPayloadType: String, CaseIterable, Identifiable, Sendable {
    case text
    case url          // Website
    case instagram
    case contact
    case facebook
    case wifi
    case whatsapp
    case youtube
    case sms

    var id: String { rawValue }

    var title: String {
        switch self {
        case .text:      "Text"
        case .url:       "Website"
        case .wifi:      "Wi‑Fi"
        case .contact:   "Contact"
        case .sms:       "SMS"
        case .instagram: "Instagram"
        case .facebook:  "Facebook"
        case .whatsapp:  "WhatsApp"
        case .youtube:   "YouTube"
        }
    }

    var inputPlaceholder: String {
        switch self {
        case .text:      "Enter the text here"
        case .url:       "https://example.com"
        case .wifi:      "Network name (SSID)"
        case .contact:   "Full name"
        case .sms:       "Phone number"
        case .instagram: "@username"
        case .facebook:  "profile or page name"
        case .whatsapp:  "+1 555 123 4567"
        case .youtube:   "@channelname"
        }
    }

    var textWarningThreshold: Int? {
        switch self {
        case .text: 150
        default:    nil
        }
    }

    /// Types using a single text field (vs structured sub-fields).
    var usesSimpleInput: Bool {
        switch self {
        case .wifi, .contact, .sms: false
        default:                    true
        }
    }

    /// First two pages of 8 types for the type-picker grid.
    static let gridPage1: [QRPayloadType] = [.text, .url, .instagram, .contact, .facebook, .wifi, .whatsapp, .youtube]
    static let gridPage2: [QRPayloadType] = [.sms]
}

// MARK: - Structured payloads

struct WiFiPayload: Sendable {
    var ssid: String
    var password: String
    var security: WiFiSecurity
    var hidden: Bool

    enum WiFiSecurity: CaseIterable, Identifiable, Sendable {
        case wpa, wep, nopass

        var id: String {
            switch self {
            case .wpa:    "wpa"
            case .wep:    "wep"
            case .nopass: "nopass"
            }
        }

        var wireType: String {
            switch self {
            case .wpa:    "WPA"
            case .wep:    "WEP"
            case .nopass: "nopass"
            }
        }

        var displayName: String {
            switch self {
            case .wpa:    "WPA/WPA2"
            case .wep:    "WEP"
            case .nopass: "None"
            }
        }
    }

    func encodedString() -> String {
        let esc = { (s: String) in
            s.replacingOccurrences(of: "\\", with: "\\\\")
             .replacingOccurrences(of: ";",  with: "\\;")
             .replacingOccurrences(of: ",",  with: "\\,")
             .replacingOccurrences(of: ":",  with: "\\:")
        }
        return "WIFI:T:\(security.wireType);S:\(esc(ssid));P:\(esc(password));H:\(hidden ? "true" : "false");;"
    }
}

struct ContactPayload: Sendable {
    var fullName: String
    var phone: String
    var email: String
    var organization: String

    func encodedString() -> String {
        var lines: [String] = ["BEGIN:VCARD", "VERSION:3.0"]
        if !fullName.isEmpty     { lines.append("FN:\(fullName)") }
        if !phone.isEmpty        { lines.append("TEL:\(phone)") }
        if !email.isEmpty        { lines.append("EMAIL:\(email)") }
        if !organization.isEmpty { lines.append("ORG:\(organization)") }
        lines.append("END:VCARD")
        return lines.joined(separator: "\n")
    }
}

struct SMSPayload: Sendable {
    var phone: String
    var body: String

    func encodedString() -> String {
        let digits = phone.filter(\.isNumber)
        guard !digits.isEmpty else { return "" }
        var s = "sms:\(digits)"
        if !body.isEmpty {
            var allowed = CharacterSet.urlQueryAllowed
            allowed.remove(charactersIn: "+&")
            let q = body.addingPercentEncoding(withAllowedCharacters: allowed) ?? body
            s += "?body=\(q)"
        }
        return s
    }
}

// MARK: - Encoder

enum QRPayloadEncoder {
    static func encode(
        type: QRPayloadType,
        text: String,
        wifi: WiFiPayload,
        contact: ContactPayload,
        sms: SMSPayload
    ) -> String {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        switch type {
        case .text:
            return text
        case .url:
            if t.isEmpty { return "" }
            if t.lowercased().hasPrefix("http://") || t.lowercased().hasPrefix("https://") { return t }
            return "https://\(t)"
        case .wifi:
            return wifi.encodedString()
        case .contact:
            return contact.encodedString()
        case .sms:
            return sms.encodedString()
        case .instagram:
            if t.isEmpty { return "" }
            let username = t.hasPrefix("@") ? String(t.dropFirst()) : t
            return "https://instagram.com/\(username)"
        case .facebook:
            if t.isEmpty { return "" }
            return "https://facebook.com/\(t)"
        case .whatsapp:
            let digits = t.filter(\.isNumber)
            return digits.isEmpty ? "" : "https://wa.me/\(digits)"
        case .youtube:
            if t.isEmpty { return "" }
            let ch = t.hasPrefix("@") ? t : "@\(t)"
            return "https://youtube.com/\(ch)"
        }
    }
}
