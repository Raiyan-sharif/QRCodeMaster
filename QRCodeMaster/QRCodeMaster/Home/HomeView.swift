//
//  HomeView.swift
//  QRCodeMaster
//

import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: Int
    @State private var showSettings = false
    @State private var showComingSoon: String?
    @State private var showMoreActions = false

    private let cardCorner: CGFloat = 20
    private let gridSpacing: CGFloat = 12

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                primaryCards
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                featureSection
                    .padding(.horizontal, 20)
                    .padding(.top, 28)

                trendingSection
                    .padding(.top, 28)
                    .padding(.bottom, 32)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                MineView()
            }
        }
        .alert("Coming soon", isPresented: Binding(
            get: { showComingSoon != nil },
            set: { if !$0 { showComingSoon = nil } }
        )) {
            Button("OK", role: .cancel) { showComingSoon = nil }
        } message: {
            Text(showComingSoon ?? "")
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Home")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Spacer()

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 1, green: 0.45, blue: 0.55), Color(red: 0.95, green: 0.35, blue: 0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            )
        }
    }

    private var primaryCards: some View {
        HStack(spacing: 14) {
            NavigationLink {
                QRCreateView()
            } label: {
                primaryCard(
                    title: "Create Qr Code",
                    icon: "qrcode",
                    gradient: [
                        Color(red: 0.2, green: 0.55, blue: 0.95),
                        Color(red: 0.15, green: 0.75, blue: 0.82),
                    ]
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                BarcodeCreateView()
            } label: {
                primaryCard(
                    title: "Create Bar Code",
                    icon: "barcode.viewfinder",
                    gradient: [
                        Color(red: 0.95, green: 0.35, blue: 0.55),
                        Color(red: 0.75, green: 0.25, blue: 0.85),
                    ]
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func primaryCard(title: String, icon: String, gradient: [Color]) -> some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 0)
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                    .fill(
                        LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing)
                    )
            )
            .shadow(color: gradient[0].opacity(0.35), radius: 12, x: 0, y: 6)

            Image(systemName: icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.white.opacity(0.95))
                .padding(14)
        }
    }

    private var featureSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Quick actions")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: 4),
                spacing: gridSpacing
            ) {
                gridButton(title: "Template", systemImage: "square.grid.2x2") {
                    selectedTab = 1
                }
                gridButton(title: "Batch Scan", systemImage: "viewfinder.rectangular") {
                    showComingSoon = "Batch scanning will be available in a future update."
                }
                gridButton(title: "Create Gif", systemImage: "photo.on.rectangle.angled") {
                    showComingSoon = "Animated QR export is planned for a future release."
                }
                gridButton(title: showMoreActions ? "Less" : "More", systemImage: showMoreActions ? "chevron.up" : "chevron.down") {
                    withAnimation(.spring(response: 0.35)) {
                        showMoreActions.toggle()
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.accentColor.opacity(showMoreActions ? 0.9 : 0), lineWidth: 2.5)
                )

                if showMoreActions {
                    NavigationLink {
                        QRCreateView()
                    } label: {
                        gridCell(title: "Create\nVcard", systemImage: "person.text.rectangle")
                    }
                    .buttonStyle(.plain)

                    gridButton(title: "Decorate", systemImage: "sparkles.rectangle.stack") {
                        showComingSoon = "QR decoration from a scan is coming later."
                    }
                    gridButton(title: "AI QR", systemImage: "wand.and.stars") {
                        showComingSoon = "AI-assisted QR styling is not available yet."
                    }
                }
            }
        }
    }

    private func gridButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            gridCell(title: title, systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }

    private func gridCell(title: String, systemImage: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(.primary)
                .frame(height: 32)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
    }

    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Trending")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Spacer()
                Button("View All") {
                    selectedTab = 1
                }
                .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(trendingSamples) { sample in
                        trendingCard(sample: sample)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private struct TrendingSample: Identifiable {
        let id: Int
        let gradient: [Color]
        let premium: Bool
    }

    private let trendingSamples: [TrendingSample] = [
        TrendingSample(id: 0, gradient: [Color(red: 1, green: 0.85, blue: 0.9), Color(red: 0.98, green: 0.6, blue: 0.75)], premium: true),
        TrendingSample(id: 1, gradient: [Color(red: 0.75, green: 0.9, blue: 1), Color(red: 0.45, green: 0.65, blue: 0.95)], premium: false),
        TrendingSample(id: 2, gradient: [Color(red: 0.85, green: 0.95, blue: 0.8), Color(red: 0.45, green: 0.75, blue: 0.5)], premium: true),
        TrendingSample(id: 3, gradient: [Color(red: 0.95, green: 0.88, blue: 1), Color(red: 0.7, green: 0.55, blue: 0.95)], premium: false),
    ]

    private func trendingCard(sample: TrendingSample) -> some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(colors: sample.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 132, height: 132)
                .overlay {
                    Image(systemName: "qrcode")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .shadow(color: sample.gradient[0].opacity(0.35), radius: 8, x: 0, y: 4)

            if sample.premium {
                Image(systemName: "crown.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.yellow)
                    .padding(6)
                    .background(Circle().fill(.black.opacity(0.55)))
                    .padding(8)
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(selectedTab: .constant(0))
    }
}
