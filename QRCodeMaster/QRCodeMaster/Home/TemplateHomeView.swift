//
//  TemplateHomeView.swift
//  QRCodeMaster
//

import SwiftUI

/// Template tab: browse backgrounds that apply when creating a QR code.
struct TemplateHomeView: View {
    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 14)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Pick a look, then create a QR code on Home to use it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(QRBackgroundTemplateCatalog.items.filter { $0.id != "none" }) { item in
                        VStack(spacing: 8) {
                            if let img = QRBackgroundTemplateCatalog.previewImage(id: item.id, length: 100) {
                                Image(uiImage: img)
                                    .resizable()
                                    .interpolation(.medium)
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            } else {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.secondarySystemFill))
                                    .frame(width: 100, height: 100)
                            }
                            Text(item.title)
                                .font(.caption.weight(.medium))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)

                NavigationLink {
                    QRCreateView()
                } label: {
                    Label("Create QR with template", systemImage: "qrcode")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding()
            }
            .padding(.top, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Template")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        TemplateHomeView()
    }
}
