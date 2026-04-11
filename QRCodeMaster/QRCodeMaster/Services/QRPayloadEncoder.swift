//
//  QRPayloadEncoder.swift
//  QRCodeMaster
//

import Foundation

enum QRPayloadType: String, CaseIterable, Identifiable, Sendable {
    case text
    case url
    case wifi
    case contact
    case sms

    var id: String { rawValue }

    var title: String {
        switch self {
        case .text: "Text"
        case .url: "URL"
        case .wifi: "Wi‑Fi"
        case .contact: "Contact"
        case .sms: "SMS"
        }
    }
}

struct WiFiPayload: Sendable {
    var ssid: String
    var password: String
    var security: WiFiSecurity
    var hidden: Bool

    enum WiFiSecurity: CaseIterable, Identifiable, Sendable {
        case wpa
        case wep
        case nopass

        var id: String {
            switch self {
            case .wpa: "wpa"
            case .wep: "wep"
            case .nopass: "nopass"
            }
        }

        var wireType: String {
            switch self {
            case .wpa: "WPA"
            case .wep: "WEP"
            case .nopass: "nopass"
            }
        }

        var displayName: String {
            switch self {
            case .wpa: "WPA/WPA2"
            case .wep: "WEP"
            case .nopass: "None"
            }
        }
    }

    func encodedString() -> String {
        let esc = { (s: String) in
            s.replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: ";", with: "\\;")
                .replacingOccurrences(of: ",", with: "\\,")
                .replacingOccurrences(of: ":", with: "\\:")
        }
        let t = security.wireType
        return "WIFI:T:\(t);S:\(esc(ssid));P:\(esc(password));H:\(hidden ? "true" : "false");;"
    }
}

struct ContactPayload: Sendable {
    var fullName: String
    var phone: String
    var email: String
    var organization: String

    func encodedString() -> String {
        var lines: [String] = ["BEGIN:VCARD", "VERSION:3.0"]
        if !fullName.isEmpty { lines.append("FN:\(fullName)") }
        if !phone.isEmpty { lines.append("TEL:\(phone)") }
        if !email.isEmpty { lines.append("EMAIL:\(email)") }
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

enum QRPayloadEncoder {
    static func encode(
        type: QRPayloadType,
        text: String,
        wifi: WiFiPayload,
        contact: ContactPayload,
        sms: SMSPayload
    ) -> String {
        switch type {
        case .text:
            return text
        case .url:
            let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.isEmpty { return "" }
            if t.lowercased().hasPrefix("http://") || t.lowercased().hasPrefix("https://") { return t }
            return "https://\(t)"
        case .wifi:
            return wifi.encodedString()
        case .contact:
            return contact.encodedString()
        case .sms:
            return sms.encodedString()
        }
    }
}
