//
//  MainTabView.swift
//  QRCodeMaster
//

import SwiftData
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var prevTab    = 0

    // Tab metadata
    private struct TabItem {
        let tag: Int; let icon: String; let label: String
    }
    private let tabs = [
        TabItem(tag: 0, icon: "house.fill",       label: "Home"),
        TabItem(tag: 1, icon: "square.grid.2x2",  label: "Template"),
        TabItem(tag: 2, icon: "viewfinder",        label: "Scan"),
        TabItem(tag: 3, icon: "folder.fill",       label: "Drafts"),
    ]

    private let teal = Color(red: 0.2, green: 0.55, blue: 0.95)

    var body: some View {
        ZStack(alignment: .bottom) {

            // ── Content area ─────────────────────────────────────────────
            // All four views stay alive (opacity-hidden) so navigation
            // stacks, camera state, and scroll positions are preserved.
            ZStack {
                navigationView(0) { HomeView(selectedTab: $selectedTab) }
                navigationView(1) { TemplateHomeView() }
                navigationView(2) { ScannerView { selectedTab = 0 } }
                navigationView(3) { LibraryView() }
            }
            // Extra space so content isn't hidden under the tab bar
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 56) }

            // ── Custom tab bar ────────────────────────────────────────────
            tabBar
        }
        .ignoresSafeArea(.keyboard)
        .tint(teal)
    }

    // MARK: - Helpers

    /// Wraps a view in a NavigationStack; visible only when this tab is selected.
    @ViewBuilder
    private func navigationView<Content: View>(_ tag: Int,
                                               @ViewBuilder content: () -> Content) -> some View {
        NavigationStack { content() }
            .opacity(selectedTab == tag ? 1 : 0)
            // Slide toward the selected direction + fade
            .offset(x: selectedTab == tag ? 0 : (tag < selectedTab ? -22 : 22))
            .scaleEffect(selectedTab == tag ? 1 : 0.97)
            .animation(
                .spring(response: 0.38, dampingFraction: 0.82),
                value: selectedTab
            )
    }

    // MARK: - Tab bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.tag) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 10)
        .padding(.bottom, bottomPad)
        .background(.ultraThinMaterial)
        .overlay(Divider(), alignment: .top)
    }

    private func tabButton(_ tab: TabItem) -> some View {
        Button {
            guard tab.tag != selectedTab else { return }
            prevTab = selectedTab
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                selectedTab = tab.tag
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22, weight: selectedTab == tab.tag ? .semibold : .regular))
                    .foregroundStyle(selectedTab == tab.tag ? teal : Color(.tertiaryLabel))
                    // Bounce scale when selected
                    .scaleEffect(selectedTab == tab.tag ? 1.12 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.55), value: selectedTab)

                Text(tab.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(selectedTab == tab.tag ? teal : Color(.tertiaryLabel))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Bottom padding accounts for home-indicator safe area.
    private var bottomPad: CGFloat {
        (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 0) > 0 ? 12 : 8
    }
}

#Preview {
    MainTabView()
        .modelContainer(AppModelContainer.make(inMemory: true))
}
