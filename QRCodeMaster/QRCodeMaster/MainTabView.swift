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
                CreateRootView()
            }
            .tabItem { Label("Create", systemImage: "qrcode") }
            .tag(0)

            NavigationStack {
                ScannerView {
                    selectedTab = 0
                }
            }
            .tabItem { Label("Scan", systemImage: "viewfinder") }
            .tag(1)

            NavigationStack {
                LibraryView()
            }
            .tabItem { Label("Library", systemImage: "folder") }
            .tag(2)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(AppModelContainer.make(inMemory: true))
}
