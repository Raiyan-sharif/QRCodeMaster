//
//  MainTabView.swift
//  QRCodeMaster
//

import SwiftData
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(selectedTab: $selectedTab)
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(0)

            NavigationStack {
                TemplateHomeView()
            }
            .tabItem { Label("Template", systemImage: "square.grid.2x2") }
            .tag(1)

            NavigationStack {
                ScannerView {
                    selectedTab = 0
                }
            }
            .tabItem { Label("Scan", systemImage: "viewfinder") }
            .tag(2)

            NavigationStack {
                LibraryView()
            }
            .tabItem { Label("Drafts", systemImage: "folder.fill") }
            .tag(3)
        }
        .tint(Color(red: 0.2, green: 0.55, blue: 0.95))
    }
}

#Preview {
    MainTabView()
        .modelContainer(AppModelContainer.make(inMemory: true))
}
