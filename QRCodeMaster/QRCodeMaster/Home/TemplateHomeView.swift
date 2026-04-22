//
//  TemplateHomeView.swift
//  QRCodeMaster
//

import SwiftData
import SwiftUI

// MARK: - Data model

private struct TemplateItem: Identifiable {
    let id: String          // unique per-grid-cell
    let templateId: String  // catalog ID
    let title: String
    let badge: Badge?

    enum Badge { case new, premium }
}

// MARK: - View

struct TemplateHomeView: View {
    @State private var selectedCategory: QRBackgroundTemplateCatalog.GalleryCategory = .hot

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
    private let teal = Color(red: 0.18, green: 0.72, blue: 0.65)

    var body: some View {
        VStack(spacing: 0) {
            // Crown header
            HStack {
                Spacer()
                Image(systemName: "crown.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.yellow)
                    .padding(.trailing, 20)
                    .padding(.top, 4)
            }

            // Category tabs — each template appears in exactly one category (see `allTemplates`).
            categoryTabs

            Divider()

            // Template grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(gridItems) { item in
                        NavigationLink {
                            QRCreateView(
                                initialStyle: QRStyleOptions(backgroundTemplateId: item.templateId)
                            )
                        } label: {
                            templateCell(item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Template")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Category tabs

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(QRBackgroundTemplateCatalog.GalleryCategory.allCases) { cat in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = cat
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text(cat.title)
                                .font(.system(size: 15, weight: selectedCategory == cat ? .semibold : .regular))
                                .foregroundStyle(selectedCategory == cat ? teal : Color(.secondaryLabel))
                                .padding(.horizontal, 16)

                            Rectangle()
                                .fill(selectedCategory == cat ? teal : Color.clear)
                                .frame(height: 2.5)
                                .cornerRadius(1.5)
                        }
                        .padding(.top, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Grid items

    private var gridItems: [TemplateItem] {
        let entries = QRBackgroundTemplateCatalog.templates(in: selectedCategory)
        return entries.enumerated().map { idx, entry in
            let badge: TemplateItem.Badge? = idx == 0 ? .new : (idx == 1 ? .premium : nil)
            return TemplateItem(
                id: "\(selectedCategory.id)-\(idx)-\(entry.id)",
                templateId: entry.id,
                title: entry.title,
                badge: badge
            )
        }
    }

    // MARK: - Template cell

    private func templateCell(_ item: TemplateItem) -> some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topLeading) {
                Group {
                    if let img = QRBackgroundTemplateCatalog.previewImage(id: item.templateId, length: 120) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemFill))
                    }
                }
                .frame(height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)

                if let badge = item.badge {
                    badgeView(badge)
                        .padding(6)
                }
            }

            Text(item.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func badgeView(_ badge: TemplateItem.Badge) -> some View {
        switch badge {
        case .new:
            Text("NEW")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.orange, in: Capsule())
        case .premium:
            Image(systemName: "crown.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.yellow)
                .padding(5)
                .background(Color.black.opacity(0.5), in: Circle())
        }
    }
}

#Preview {
    NavigationStack {
        TemplateHomeView()
    }
    .modelContainer(AppModelContainer.make(inMemory: true))
}
