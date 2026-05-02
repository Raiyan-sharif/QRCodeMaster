//
//  MainTabView.swift
//  QRCodeMaster
//

import SwiftData
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    private let teal = Color(red: 0.2, green: 0.55, blue: 0.95)

    var body: some View {
        // System TabView: reliable hit testing on all devices (custom ZStack +
        // overlay bars can fail on large phones / certain simulators). Selection
        // binding matches HomeView quick actions (Template, etc.).
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(selectedTab: $selectedTab)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack {
                TemplateHomeView()
            }
            .tabItem {
                Label("Template", systemImage: "square.grid.2x2")
            }
            .tag(1)

            NavigationStack {
                ScannerView { selectedTab = 0 }
            }
            .tabItem {
                Label("Scan", systemImage: "viewfinder")
            }
            .tag(2)

            NavigationStack {
                LibraryView()
            }
            .tabItem {
                Label("Drafts", systemImage: "folder.fill")
            }
            .tag(3)
        }
        .tint(teal)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    MainTabView()
        .modelContainer(AppModelContainer.make(inMemory: true))
}
