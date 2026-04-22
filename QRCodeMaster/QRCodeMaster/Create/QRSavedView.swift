//
//  QRSavedView.swift
//  QRCodeMaster
//

import SwiftData
import SwiftUI

/// Post-save confirmation shown after the user taps Save in QRCustomizeView.
/// The SavedCode was already inserted by QRCustomizeView; this screen provides actions on the exported image.
struct QRSavedView: View {
    let image: UIImage
    let payload: String
    let payloadType: QRPayloadType
    let styleOptions: QRStyleOptions

    @Environment(\.subscriptionStatus) private var subscription

    @State private var showShare = false
    @State private var showSavedToPhotos = false
    @State private var isFavorite = false
    @State private var showComingSoon = false
    @State private var savePhotoError: String?
    @State private var showPhotoError = false
    @State private var verificationOutcome: QRImageVerifier.Outcome = .idle

    private let teal = Color(red: 0.18, green: 0.72, blue: 0.65)

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // QR preview card
                previewCard

                // Caption
                if !styleOptions.captionText.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text(styleOptions.captionText)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                verifySection

                // Action buttons
                HStack(spacing: 20) {
                    actionCircle(title: "Share", systemImage: "square.and.arrow.up") {
                        showShare = true
                    }
                    actionCircle(title: "Favourite", systemImage: isFavorite ? "heart.fill" : "heart") {
                        isFavorite.toggle()
                    }
                    actionCircle(title: "Save Photo", systemImage: "photo.badge.plus") {
                        Task { await saveToPhotos() }
                    }
                    actionCircle(title: "Widget", systemImage: "square.dashed") {
                        showComingSoon = true
                    }
                }

                // VIP upsell card
                if !subscription.isPremium {
                    vipBanner
                }

                Spacer(minLength: 32)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("QR Code Saved")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShare) {
            ActivityView(items: [image])
        }
        .alert("Saved to Photos", isPresented: $showSavedToPhotos) {
            Button("OK", role: .cancel) {}
        }
        .alert("Could not save", isPresented: $showPhotoError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(savePhotoError ?? "")
        }
        .alert("Coming soon", isPresented: $showComingSoon) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Widget support will be available in a future update.")
        }
    }

    // MARK: - Verify QR

    private var verifySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                Task { await verifyTapped() }
            } label: {
                HStack(spacing: 8) {
                    if verificationOutcome == .verifying {
                        ProgressView()
                            .tint(teal)
                    } else {
                        Image(systemName: "qrcode.viewfinder")
                    }
                    Text(verificationOutcome == .verifying ? "Verifying…" : "Verify QR Code")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(teal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 18)
                .background(teal.opacity(0.12), in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(verificationOutcome == .verifying)

            if verificationOutcome != .idle && verificationOutcome != .verifying {
                verificationResultBanner
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: verificationOutcome)
    }

    @MainActor
    private func verifyTapped() async {
        verificationOutcome = .verifying
        let result = await QRImageVerifier.verify(image: image, expectedPayload: payload)
        verificationOutcome = result
    }

    @ViewBuilder
    private var verificationResultBanner: some View {
        switch verificationOutcome {
        case .idle, .verifying:
            EmptyView()

        case .validMatchesContent:
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Valid QR code")
                        .font(.subheadline.weight(.semibold))
                    Text("The image decodes successfully and matches your saved content.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

        case .readablePayloadMismatch(let found):
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Readable, but different text")
                        .font(.subheadline.weight(.semibold))
                    Text("Vision decoded a QR, but the string does not match what you saved.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(found)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.primary)
                        .lineLimit(6)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

        case .couldNotReadFromImage:
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.red.opacity(0.85))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Could not read this image")
                        .font(.subheadline.weight(.semibold))
                    Text("No QR code was detected. Heavy styling or low contrast can block scanners; try a simpler template or higher error correction.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

        case .failed(let message):
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Verification failed")
                        .font(.subheadline.weight(.semibold))
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: - QR preview card

    private var previewCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.07), radius: 14, x: 0, y: 6)

            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .padding(20)
        }
        .frame(maxWidth: 300, maxHeight: 300)
    }

    // MARK: - Action circle

    private func actionCircle(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(teal)
                        .frame(width: 58, height: 58)
                        .shadow(color: teal.opacity(0.4), radius: 8, x: 0, y: 4)
                    Image(systemName: systemImage)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white)
                }
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    // MARK: - VIP banner

    private var vipBanner: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Unlimited Access to All\nFantastic Features")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    ForEach(["rectangle.grid.2x2.fill", "r.circle.fill", "paintpalette.fill", "textformat"], id: \.self) { sym in
                        Image(systemName: sym)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
            }

            Spacer(minLength: 0)

            VStack(spacing: 2) {
                Text("60%")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(Color(red: 0.18, green: 0.72, blue: 0.65))
                Text("SAVE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(red: 0.18, green: 0.72, blue: 0.65))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.12, green: 0.62, blue: 0.42), Color(red: 0.08, green: 0.52, blue: 0.52)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: Color(red: 0.1, green: 0.45, blue: 0.4).opacity(0.3), radius: 10, x: 0, y: 5)

        // Get Now button below
        .overlay(alignment: .bottom) {
            EmptyView()
        }

        // Stacked Get Now button
        .padding(.bottom, 48)
        .overlay(alignment: .bottom) {
            Button {
                // IAP placeholder
            } label: {
                VStack(spacing: 2) {
                    Text("Get Now")
                        .font(.headline.weight(.semibold))
                    Text("Limited Time  23:32:51")
                        .font(.caption2)
                        .opacity(0.8)
                }
                .foregroundStyle(Color(red: 0.12, green: 0.62, blue: 0.42))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Save to Photos

    private func saveToPhotos() async {
        do {
            try await PhotoLibrarySaver.save(image)
            showSavedToPhotos = true
        } catch {
            savePhotoError = error.localizedDescription
            showPhotoError = true
        }
    }
}

#Preview {
    let img = QRStyleRenderer.render(
        message: "https://apple.com",
        options: .default,
        logo: nil,
        outputPoints: 256,
        showWatermark: false
    ) ?? UIImage(systemName: "qrcode")!

    return NavigationStack {
        QRSavedView(image: img, payload: "https://apple.com", payloadType: .url, styleOptions: .default)
    }
    .modelContainer(AppModelContainer.make(inMemory: true))
    .environment(\.subscriptionStatus, FreeSubscriptionStatus())
}
