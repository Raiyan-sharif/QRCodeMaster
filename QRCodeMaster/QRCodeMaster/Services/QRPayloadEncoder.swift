//
//  QRPayloadEncoder.swift
//  QRCodeMaster
//

import Foundation

// MARK: - Type enum

enum QRPayloadType: String, CaseIterable, Identifiable, Sendable {
    // Page 1
    case text, url, instagram, contact, facebook, wifi, whatsapp, youtube
    // Page 2
    case email, review, threads, discord, sms, tiktok, line, phone
    // Page 3
    case truthsocial, spotify, paypal, linkedin, calendar, crypto, reddit, skype
    // Page 4
    case messenger, pinterest, viber, wechat, x, telegram, snapchat

    var id: String { rawValue }

    var title: String {
        switch self {
        case .text:        "Text"
        case .url:         "Website"
        case .instagram:   "Instagram"
        case .contact:     "Contact"
        case .facebook:    "Facebook"
        case .wifi:        "Wi-Fi"
        case .whatsapp:    "WhatsApp"
        case .youtube:     "YouTube"
        case .email:       "E-mail"
        case .review:      "Review"
        case .threads:     "Threads"
        case .discord:     "Discord"
        case .sms:         "SMS"
        case .tiktok:      "TikTok"
        case .line:        "Line"
        case .phone:       "Phone"
        case .truthsocial: "Truth Social"
        case .spotify:     "Spotify"
        case .paypal:      "PayPal"
        case .linkedin:    "LinkedIn"
        case .calendar:    "Calendar"
        case .crypto:      "Crypto"
        case .reddit:      "Reddit"
        case .skype:       "Skype"
        case .messenger:   "Messenger"
        case .pinterest:   "Pinterest"
        case .viber:       "Viber"
        case .wechat:      "WeChat"
        case .x:           "X"
        case .telegram:    "Telegram"
        case .snapchat:    "Snapchat"
        }
    }

    var inputPlaceholder: String {
        switch self {
        case .text:        "Enter the text here"
        case .url:         "e.g. https://www.example.com/"
        case .instagram:   "Enter your username (e.g. john)"
        case .contact:     "Full name"
        case .facebook:    "Enter your Facebook ID (e.g. john.123)"
        case .wifi:        "Network name (SSID)"
        case .whatsapp:    "Phone Number"
        case .youtube:     "Please enter a channel ID (e.g. @john123)"
        case .email:       "e.g. example@mail.com"
        case .review:      "Enter the Google review link"
        case .threads:     "Enter the username after @ (e.g. john12)"
        case .discord:     "Enter the Discord personal/group link (e.g. https://discord.gg/example)"
        case .sms:         "Phone number"
        case .tiktok:      "Please fill in the TikTok profile link"
        case .line:        "Phone Number"
        case .phone:       "Please fill in the phone number"
        case .truthsocial: "Enter the username after @ (e.g. john12)"
        case .spotify:     "Artist name"
        case .paypal:      "Please fill in the PayPal.Me or username"
        case .linkedin:    "Please fill in the LinkedIn profile link"
        case .calendar:    "Event title"
        case .crypto:      "Please fill in the Crypto address"
        case .reddit:      "Please fill in the Reddit post link"
        case .skype:       "Please fill in the profile link"
        case .messenger:   "Please fill in the profile link"
        case .pinterest:   "Please fill in the username"
        case .viber:       "Phone Number"
        case .wechat:      "Please fill in the profile link"
        case .x:           "Enter the username after @ (e.g. elonmusk)"
        case .telegram:    "Please fill in your Telegram ID"
        case .snapchat:    "Please fill in the username"
        }
    }

    var textWarningThreshold: Int? {
        switch self {
        case .text: 150
        default:    nil
        }
    }

    var usesSimpleInput: Bool {
        switch self {
        case .wifi, .contact, .sms, .email, .spotify, .calendar: false
        default: true
        }
    }

    static let gridPage1: [QRPayloadType] = [.text, .url, .instagram, .contact, .facebook, .wifi, .whatsapp, .youtube]
    static let gridPage2: [QRPayloadType] = [.email, .review, .threads, .discord, .sms, .tiktok, .line, .phone]
    static let gridPage3: [QRPayloadType] = [.truthsocial, .spotify, .paypal, .linkedin, .calendar, .crypto, .reddit, .skype]
    static let gridPage4: [QRPayloadType] = [.messenger, .pinterest, .viber, .wechat, .x, .telegram, .snapchat]
}

// MARK: - Structured payloads

struct WiFiPayload: Sendable {
    var ssid: String = ""
    var password: String = ""
    var security: WiFiSecurity = .wpa
    var hidden: Bool = false

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
    var fullName: String = ""
    var phone: String = ""
    var fax: String = ""
    var email: String = ""
    var company: String = ""
    var jobTitle: String = ""
    var address: String = ""
    var website: String = ""
    var memo: String = ""

    func encodedString() -> String {
        var lines = ["BEGIN:VCARD", "VERSION:3.0"]
        if !fullName.isEmpty { lines.append("FN:\(fullName)") }
        if !phone.isEmpty    { lines.append("TEL;TYPE=CELL:\(phone)") }
        if !fax.isEmpty      { lines.append("TEL;TYPE=FAX:\(fax)") }
        if !email.isEmpty    { lines.append("EMAIL:\(email)") }
        if !company.isEmpty  { lines.append("ORG:\(company)") }
        if !jobTitle.isEmpty { lines.append("TITLE:\(jobTitle)") }
        if !address.isEmpty  { lines.append("ADR:;;\(address);;;;") }
        if !website.isEmpty  { lines.append("URL:\(website)") }
        if !memo.isEmpty     { lines.append("NOTE:\(memo)") }
        lines.append("END:VCARD")
        return lines.joined(separator: "\n")
    }
}

struct SMSPayload: Sendable {
    var phone: String = ""
    var body: String = ""

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

struct EmailPayload: Sendable {
    var address: String = ""
    var body: String = ""

    func encodedString() -> String {
        guard !address.isEmpty else { return "" }
        var s = "mailto:\(address)"
        if !body.isEmpty {
            let q = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? body
            s += "?body=\(q)"
        }
        return s
    }
}

struct SpotifyPayload: Sendable {
    var artist: String = ""
    var song: String = ""

    func encodedString() -> String {
        let query = [artist, song].filter { !$0.isEmpty }.joined(separator: " ")
        guard !query.isEmpty else { return "" }
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return "https://open.spotify.com/search/\(encoded)"
    }
}

struct CalendarPayload: Sendable {
    var title: String = ""
    var location: String = ""
    var startDate: Date = Date()
    var endDate: Date = Date().addingTimeInterval(3600)
    var eventDescription: String = ""

    private static let fmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    func encodedString() -> String {
        guard !title.isEmpty else { return "" }
        var lines = [
            "BEGIN:VCALENDAR",
            "VERSION:2.0",
            "BEGIN:VEVENT",
            "SUMMARY:\(title)",
        ]
        if !location.isEmpty    { lines.append("LOCATION:\(location)") }
        lines.append("DTSTART:\(Self.fmt.string(from: startDate))")
        lines.append("DTEND:\(Self.fmt.string(from: endDate))")
        if !eventDescription.isEmpty { lines.append("DESCRIPTION:\(eventDescription)") }
        lines.append("END:VEVENT")
        lines.append("END:VCALENDAR")
        return lines.joined(separator: "\n")
    }
}

// MARK: - Encoder

enum QRPayloadEncoder {
    static func encode(
        type: QRPayloadType,
        text: String,
        wifi: WiFiPayload,
        contact: ContactPayload,
        sms: SMSPayload,
        email: EmailPayload,
        spotify: SpotifyPayload,
        calendar: CalendarPayload
    ) -> String {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)

        switch type {

        // Plain text
        case .text:
            return text

        // URL / Website
        case .url:
            guard !t.isEmpty else { return "" }
            if t.lowercased().hasPrefix("http://") || t.lowercased().hasPrefix("https://") { return t }
            return "https://\(t)"

        // Structured
        case .wifi:     return wifi.encodedString()
        case .contact:  return contact.encodedString()
        case .sms:      return sms.encodedString()
        case .email:    return email.encodedString()
        case .spotify:  return spotify.encodedString()
        case .calendar: return calendar.encodedString()

        // Social — username-based
        case .instagram:
            guard !t.isEmpty else { return "" }
            let u = t.hasPrefix("@") ? String(t.dropFirst()) : t
            return "https://instagram.com/\(u)"

        case .facebook:
            guard !t.isEmpty else { return "" }
            return "https://facebook.com/\(t)"

        case .youtube:
            guard !t.isEmpty else { return "" }
            return "https://youtube.com/\(t.hasPrefix("@") ? t : "@\(t)")"

        case .threads:
            guard !t.isEmpty else { return "" }
            let u = t.hasPrefix("@") ? String(t.dropFirst()) : t
            return "https://threads.net/@\(u)"

        case .truthsocial:
            guard !t.isEmpty else { return "" }
            let u = t.hasPrefix("@") ? String(t.dropFirst()) : t
            return "https://truthsocial.com/@\(u)"

        case .pinterest:
            guard !t.isEmpty else { return "" }
            return "https://pinterest.com/\(t)"

        case .snapchat:
            guard !t.isEmpty else { return "" }
            return "https://snapchat.com/add/\(t)"

        case .x:
            guard !t.isEmpty else { return "" }
            let u = t.hasPrefix("@") ? String(t.dropFirst()) : t
            return "https://x.com/\(u)"

        case .telegram:
            guard !t.isEmpty else { return "" }
            let u = t.hasPrefix("@") ? String(t.dropFirst()) : t
            return "https://t.me/\(u)"

        case .tiktok:
            guard !t.isEmpty else { return "" }
            if t.lowercased().hasPrefix("http") { return t }
            let u = t.hasPrefix("@") ? t : "@\(t)"
            return "https://tiktok.com/\(u)"

        // Social — phone-based
        case .whatsapp:
            let d = t.filter(\.isNumber)
            return d.isEmpty ? "" : "https://wa.me/\(d)"

        case .line:
            let d = t.filter(\.isNumber)
            return d.isEmpty ? "" : "https://line.me/ti/p/+\(d)"

        case .viber:
            let d = t.filter(\.isNumber)
            return d.isEmpty ? "" : "viber://chat?number=%2B\(d)"

        case .phone:
            let d = t.filter { $0.isNumber || $0 == "+" }
            return d.isEmpty ? "" : "tel:\(d)"

        // Social — direct links
        case .discord:
            guard !t.isEmpty else { return "" }
            if t.lowercased().hasPrefix("http") { return t }
            return "https://discord.gg/\(t)"

        case .review:
            guard !t.isEmpty else { return "" }
            return t.lowercased().hasPrefix("http") ? t : "https://\(t)"

        case .paypal:
            guard !t.isEmpty else { return "" }
            if t.lowercased().hasPrefix("http") { return t }
            return "https://paypal.me/\(t)"

        case .linkedin:
            guard !t.isEmpty else { return "" }
            return t.lowercased().hasPrefix("http") ? t : "https://linkedin.com/in/\(t)"

        case .reddit:
            guard !t.isEmpty else { return "" }
            return t.lowercased().hasPrefix("http") ? t : "https://reddit.com/\(t)"

        case .skype:
            guard !t.isEmpty else { return "" }
            return t.lowercased().hasPrefix("http") ? t : "skype:\(t)?chat"

        case .messenger:
            guard !t.isEmpty else { return "" }
            return t.lowercased().hasPrefix("http") ? t : "https://m.me/\(t)"

        case .wechat:
            guard !t.isEmpty else { return "" }
            return t

        case .crypto:
            return t

        }
    }
}
