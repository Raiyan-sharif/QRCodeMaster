//
//  CreateRootView.swift
//  QRCodeMaster
//

import SwiftUI

struct CreateRootView: View {
    var body: some View {
        List {
            Section {
                NavigationLink {
                    QRCreateView()
                } label: {
                    Label("QR code", systemImage: "qrcode")
                }
                NavigationLink {
                    BarcodeCreateView()
                } label: {
                    Label("Barcode", systemImage: "barcode")
                }
            } header: {
                Text("New")
            }
        }
        .navigationTitle("Create")
    }
}

#Preview {
    NavigationStack {
        CreateRootView()
    }
}
