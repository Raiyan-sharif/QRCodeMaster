//
//  BrandIconView.swift
//  QRCodeMaster
//
//  Displays an app-icon-style cell for each brand.
//  Uses custom-drawn marks (no remote logos) so the grid works offline and
//  avoids noisy URLSession / DNS failures in the console (e.g. Clearbit on
//  some networks or simulators).
//  All cells render at 90 % opacity as requested.
//

import SwiftUI

struct BrandIconView: View {
    let brand: QRBackgroundTemplateCatalog.BrandItem
    var size: CGFloat = 64

    // MARK: - Body

    var body: some View {
        ZStack {
            // Gradient background — fills the full rounded-square
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(uiColor: UIColor(hex: brand.startHex) ?? .gray),
                            Color(uiColor: UIColor(hex: brand.endHex)   ?? .black),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            fallbackMark
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .opacity(0.9)   // 90 % opacity as requested
    }

    // MARK: - Tint helper

    private var ic: Color { brand.iconIsDark ? Color.black.opacity(0.85) : .white }

    // MARK: - Offline / fallback custom drawing

    @ViewBuilder
    private var fallbackMark: some View {
        let s = size
        switch brand.id {

        // ── Letter / text marks ──────────────────────────────────────────────
        case "brand_facebook":
            letterMark("f", size: s * 0.62, design: .rounded)

        case "brand_linkedin":
            letterMark("in", size: s * 0.38)

        case "brand_pinterest":
            letterMark("P", size: s * 0.60, design: .serif)

        case "brand_x":
            letterMark("X", size: s * 0.52)

        case "brand_bitcoin":
            letterMark("₿", size: s * 0.50)

        case "brand_paypal":
            twoLetterMark("P", "P", size: s)

        case "brand_line":
            lineIcon(size: s)

        case "brand_bnb":
            letterMark("BNB", size: s * 0.22)

        // ── Instagram ────────────────────────────────────────────────────────
        case "brand_instagram":
            instagramIcon(size: s)

        // ── WhatsApp ─────────────────────────────────────────────────────────
        case "brand_whatsapp":
            sfStack("phone.fill", back: "bubble.left.fill", size: s)

        // ── YouTube ──────────────────────────────────────────────────────────
        case "brand_youtube":
            youtubeIcon(size: s)

        // ── Snapchat ─────────────────────────────────────────────────────────
        case "brand_snapchat":
            snapchatIcon(size: s)

        // ── Spotify ───────────────────────────────────────────────────────────
        case "brand_spotify":
            spotifyIcon(size: s)

        // ── TikTok ────────────────────────────────────────────────────────────
        case "brand_tiktok":
            tiktokIcon(size: s)

        // ── Telegram ──────────────────────────────────────────────────────────
        case "brand_telegram":
            Image(systemName: "paperplane.fill")
                .font(.system(size: s * 0.46, weight: .bold))
                .foregroundStyle(ic)
                .rotationEffect(.degrees(-30))

        // ── Messenger ─────────────────────────────────────────────────────────
        case "brand_messenger":
            ZStack {
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: s * 0.52, weight: .bold))
                    .foregroundStyle(ic)
                Image(systemName: "bolt.fill")
                    .font(.system(size: s * 0.22, weight: .black))
                    .foregroundStyle(Color(uiColor: UIColor(hex: brand.startHex) ?? .blue))
                    .offset(y: -s * 0.04)
            }

        // ── WeChat ────────────────────────────────────────────────────────────
        case "brand_wechat":
            HStack(spacing: -s * 0.1) {
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: s * 0.4, weight: .bold))
                    .foregroundStyle(ic)
                Image(systemName: "bubble.right.fill")
                    .font(.system(size: s * 0.32, weight: .bold))
                    .foregroundStyle(ic.opacity(0.65))
                    .offset(y: s * 0.06)
            }

        // ── Ethereum ──────────────────────────────────────────────────────────
        case "brand_ethereum":
            ethereumIcon(size: s)

        // ── Discord ───────────────────────────────────────────────────────────
        case "brand_discord":
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: s * 0.44, weight: .bold))
                .foregroundStyle(ic)

        // ── Reddit ────────────────────────────────────────────────────────────
        case "brand_reddit":
            ZStack {
                Image(systemName: "bubble.right.fill")
                    .font(.system(size: s * 0.46, weight: .bold))
                    .foregroundStyle(ic)
                HStack(spacing: s * 0.12) {
                    dot(s * 0.09, color: Color(uiColor: UIColor(hex: brand.startHex) ?? .orange))
                    dot(s * 0.09, color: Color(uiColor: UIColor(hex: brand.startHex) ?? .orange))
                }
                .offset(y: -s * 0.04)
            }

        // ── Viber ─────────────────────────────────────────────────────────────
        case "brand_viber":
            Image(systemName: "phone.fill")
                .font(.system(size: s * 0.46, weight: .bold))
                .foregroundStyle(ic)

        // ── Skype ─────────────────────────────────────────────────────────────
        case "brand_skype":
            ZStack {
                Image(systemName: "cloud.fill")
                    .font(.system(size: s * 0.52, weight: .bold))
                    .foregroundStyle(ic)
                Text("S")
                    .font(.system(size: s * 0.28, weight: .black, design: .rounded))
                    .foregroundStyle(Color(uiColor: UIColor(hex: brand.startHex) ?? .blue))
                    .offset(y: s * 0.03)
            }

        // ── Default SF Symbol fallback ────────────────────────────────────────
        default:
            Image(systemName: brand.sfSymbol)
                .font(.system(size: s * 0.44, weight: .bold))
                .foregroundStyle(ic)
        }
    }

    // MARK: - Helpers

    private func letterMark(_ text: String, size fs: CGFloat, design: Font.Design = .default) -> some View {
        Text(text)
            .font(.system(size: fs, weight: .black, design: design))
            .foregroundStyle(ic)
    }

    private func dot(_ size: CGFloat, color: Color) -> some View {
        Circle().fill(color).frame(width: size, height: size)
    }

    private func sfStack(_ front: String, back: String, size s: CGFloat) -> some View {
        ZStack {
            Image(systemName: back)
                .font(.system(size: s * 0.50, weight: .bold))
                .foregroundStyle(ic)
            Image(systemName: front)
                .font(.system(size: s * 0.22, weight: .black))
                .foregroundStyle(Color(uiColor: UIColor(hex: brand.startHex) ?? .green))
        }
    }

    // MARK: - Brand-specific fallback mini-views

    private func instagramIcon(size s: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.14, style: .continuous)
                .stroke(ic, lineWidth: s * 0.07)
                .frame(width: s * 0.5, height: s * 0.5)
            Circle()
                .stroke(ic, lineWidth: s * 0.065)
                .frame(width: s * 0.22, height: s * 0.22)
            Circle()
                .fill(ic)
                .frame(width: s * 0.08, height: s * 0.08)
                .offset(x: s * 0.15, y: -s * 0.15)
        }
    }

    private func youtubeIcon(size s: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.12)
                .fill(ic)
                .frame(width: s * 0.60, height: s * 0.42)
            Image(systemName: "play.fill")
                .font(.system(size: s * 0.24, weight: .black))
                .foregroundStyle(.red)
        }
    }

    private func snapchatIcon(size s: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(ic)
                .frame(width: s * 0.46, height: s * 0.46)
                .offset(y: -s * 0.08)
            Rectangle()
                .fill(ic)
                .frame(width: s * 0.44, height: s * 0.22)
                .offset(y: s * 0.1)
            HStack(spacing: s * 0.1) {
                Circle()
                    .fill(Color(uiColor: UIColor(hex: brand.startHex) ?? .yellow))
                    .frame(width: s * 0.09, height: s * 0.09)
                Circle()
                    .fill(Color(uiColor: UIColor(hex: brand.startHex) ?? .yellow))
                    .frame(width: s * 0.09, height: s * 0.09)
            }
            .offset(y: -s * 0.08)
        }
    }

    private func spotifyIcon(size s: CGFloat) -> some View {
        VStack(spacing: s * 0.06) {
            ForEach([s * 0.42, s * 0.52, s * 0.36], id: \.self) { w in
                Capsule()
                    .fill(ic)
                    .frame(width: w, height: s * 0.07)
            }
        }
    }

    private func tiktokIcon(size s: CGFloat) -> some View {
        ZStack {
            Image(systemName: "music.note")
                .font(.system(size: s * 0.46, weight: .bold))
                .foregroundStyle(Color(red: 0.41, green: 0.79, blue: 0.82))
                .offset(x: -s * 0.04, y: -s * 0.02)
            Image(systemName: "music.note")
                .font(.system(size: s * 0.46, weight: .bold))
                .foregroundStyle(Color(red: 0.93, green: 0.14, blue: 0.27))
                .offset(x: s * 0.04, y: s * 0.02)
            Image(systemName: "music.note")
                .font(.system(size: s * 0.46, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private func twoLetterMark(_ a: String, _ b: String, size s: CGFloat) -> some View {
        ZStack {
            Text(a)
                .font(.system(size: s * 0.52, weight: .black, design: .serif))
                .foregroundStyle(ic)
                .offset(x: -s * 0.08)
            Text(b)
                .font(.system(size: s * 0.46, weight: .black, design: .serif))
                .foregroundStyle(ic.opacity(0.55))
                .offset(x: s * 0.1, y: s * 0.08)
        }
    }

    private func lineIcon(size s: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.07)
                .fill(ic)
                .frame(width: s * 0.54, height: s * 0.44)
            Text("LINE")
                .font(.system(size: s * 0.15, weight: .black, design: .monospaced))
                .foregroundStyle(Color(uiColor: UIColor(hex: brand.startHex) ?? .green))
        }
    }

    private func ethereumIcon(size s: CGFloat) -> some View {
        ZStack {
            Image(systemName: "arrowtriangle.up.fill")
                .font(.system(size: s * 0.36, weight: .bold))
                .foregroundStyle(ic)
                .offset(y: -s * 0.08)
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: s * 0.32, weight: .bold))
                .foregroundStyle(ic.opacity(0.5))
                .offset(y: s * 0.1)
        }
    }
}
