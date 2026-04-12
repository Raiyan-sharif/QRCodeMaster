//
//  MineView.swift
//  QRCodeMaster
//

import StoreKit
import SwiftData
import SwiftUI

/// Settings / profile screen (reference: “Mine” with VIP card and menu).
struct MineView: View {
    @Environment(\.subscriptionStatus) private var subscription
    @Environment(\.requestReview) private var requestReview
    @Environment(\.dismiss) private var dismiss

    @State private var showShareSheet = false
    @State private var showSyncComingSoon = false

    private let cardCorner: CGFloat = 20
    private let mineTeal = Color(red: 0.18, green: 0.72, blue: 0.65)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                vipCard
                    .padding(.horizontal, 20)

                menuCard
                    .padding(.horizontal, 20)
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Mine")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityView(items: shareItems)
        }
        .alert("Sync", isPresented: $showSyncComingSoon) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Cloud sync is not available in this version yet.")
        }
    }

    private var shareItems: [Any] {
        let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "QRCodeMaster"
        return ["Check out \(name) — create and scan QR codes."]
    }

    // MARK: - VIP

    private var vipCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .foregroundStyle(.yellow)
                Text("Join VIP - All Access")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
            }

            HStack(spacing: 12) {
                vipFeatureBubble(title: "Template", systemImage: "doc.text.image")
                vipFeatureBubble(title: "Logo", systemImage: "r.circle.fill")
                vipFeatureBubble(title: "Color", systemImage: "paintpalette.fill")
                vipFeatureBubble(title: "Text", systemImage: "textformat")
            }

            Button {
                // IAP placeholder — FreeSubscriptionStatus is already “premium” in dev.
            } label: {
                Text(subscription.isPremium ? "You're subscribed" : "Join Now")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [mineTeal, Color(red: 0.1, green: 0.55, blue: 0.5)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white)
                    )
            }
            .buttonStyle(.plain)
            .disabled(subscription.isPremium)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.62, blue: 0.42),
                            Color(red: 0.08, green: 0.52, blue: 0.52),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: Color(red: 0.1, green: 0.45, blue: 0.4).opacity(0.35), radius: 12, x: 0, y: 6)
    }

    private func vipFeatureBubble(title: String, systemImage: String) -> some View {
        VStack(spacing: 6) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(mineTeal)
                    .frame(width: 44, height: 44)
                if !subscription.isPremium {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(Circle().fill(Color.orange))
                        .offset(x: 4, y: 4)
                }
            }
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.95))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Menu

    private var menuCard: some View {
        VStack(spacing: 0) {
            NavigationLink {
                LibraryFilteredView(filter: .created)
            } label: {
                menuRowLabel(
                    title: "Create History",
                    systemImage: "clock.fill",
                    showNotificationDot: hasCreatedItems
                )
            }

            rowDivider

            NavigationLink {
                LibraryFilteredView(filter: .scanned)
            } label: {
                menuRowLabel(title: "Scan History", systemImage: "square.grid.2x2.fill")
            }

            rowDivider

            NavigationLink {
                LibraryFilteredView(filter: .favorites)
            } label: {
                menuRowLabel(title: "Favorite Templates", systemImage: "heart.fill")
            }

            rowDivider

            Button {
                showSyncComingSoon = true
            } label: {
                menuRowLabel(title: "Sync", systemImage: "arrow.triangle.2.circlepath.icloud.fill")
            }

            rowDivider

            Button {
                requestReview()
            } label: {
                menuRowLabel(title: "Rate", systemImage: "star.fill")
            }

            rowDivider

            Button {
                showShareSheet = true
            } label: {
                menuRowLabel(title: "Share app", systemImage: "square.and.arrow.up.fill")
            }

            rowDivider

            Link(destination: feedbackMailURL) {
                menuRowLabel(title: "Feedback", systemImage: "envelope.fill")
            }
            .tint(.primary)
        }
        .background(
            RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var rowDivider: some View {
        Divider()
            .padding(.leading, 56)
    }

    @Query(filter: #Predicate<SavedCode> { $0.sourceRaw == "created" }) private var createdCodes: [SavedCode]

    private var hasCreatedItems: Bool {
        !createdCodes.isEmpty
    }

    private var feedbackMailURL: URL {
        let subject = "QRCodeMaster Feedback"
        let encoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "mailto:?subject=\(encoded)")!
    }

    private func menuRowLabel(title: String, systemImage: String, showNotificationDot: Bool = false) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(mineTeal, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)

            if showNotificationDot {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        MineView()
    }
    .modelContainer(AppModelContainer.make(inMemory: true))
    .environment(\.subscriptionStatus, FreeSubscriptionStatus())
}
