//
//  TemplateHomeView.swift
//  QRCodeMaster
//

import SwiftData
import SwiftUI

// MARK: - Data model

private enum TemplateCategory: String, CaseIterable, Identifiable {
    case hot, social, love, vcard, business, wifi

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hot:      "Hot"
        case .social:   "Social"
        case .love:     "Love"
        case .vcard:    "Vcard"
        case .business: "Business"
        case .wifi:     "Wifi"
        }
    }

    var subcategories: [String] {
        switch self {
        case .hot:      ["All", "New", "Featured"]
        case .social:   ["Instagram", "WhatsApp", "Facebook", "X"]
        case .love:     ["Heart", "Wedding", "Valentine"]
        case .vcard:    ["Personal", "Business Card"]
        case .business: ["Corporate", "Minimal"]
        case .wifi:     ["Home", "Office"]
        }
    }

    /// Template IDs from QRBackgroundTemplateCatalog that belong to this category.
    var templateIds: [String] {
        switch self {
        case .hot:      ["sunset", "aurora", "ocean", "midnight", "forest", "dots", "grid", "paper"]
        case .social:   ["sunset", "aurora", "ocean", "midnight", "forest", "dots", "grid", "paper"]
        case .love:     ["sunset", "aurora", "forest", "dots"]
        case .vcard:    ["paper", "grid", "dots", "ocean"]
        case .business: ["midnight", "grid", "paper", "ocean"]
        case .wifi:     ["ocean", "aurora", "grid", "midnight"]
        }
    }
}

private struct TemplateItem: Identifiable {
    let id: String          // unique per-grid-cell
    let templateId: String  // catalog ID
    let badge: Badge?

    enum Badge { case new, premium }
}

// MARK: - View

struct TemplateHomeView: View {
    @State private var selectedCategory: TemplateCategory = .hot
    @State private var selectedSubcategory: String = "All"

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

            // Category tabs
            categoryTabs

            // Sub-category pills
            if !selectedCategory.subcategories.isEmpty {
                subCategoryPills
            }

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
        .onChange(of: selectedCategory) { _, _ in
            selectedSubcategory = selectedCategory.subcategories.first ?? "All"
        }
    }

    // MARK: - Category tabs

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(TemplateCategory.allCases) { cat in
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

    // MARK: - Sub-category pills

    private var subCategoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(selectedCategory.subcategories, id: \.self) { sub in
                    Button {
                        selectedSubcategory = sub
                    } label: {
                        Text(sub)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(selectedSubcategory == sub ? teal : Color(.label))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(selectedSubcategory == sub ? teal.opacity(0.12) : Color(.secondarySystemFill))
                                    .overlay(
                                        Capsule()
                                            .stroke(selectedSubcategory == sub ? teal : Color.clear, lineWidth: 1.5)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.15), value: selectedSubcategory)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Grid items

    private var gridItems: [TemplateItem] {
        let ids = selectedCategory.templateIds
        return ids.enumerated().map { idx, tid in
            let badge: TemplateItem.Badge? = idx < 3 ? .new : (idx < 6 ? .premium : nil)
            return TemplateItem(id: "\(selectedCategory.id)-\(idx)-\(tid)", templateId: tid, badge: badge)
        }
    }

    // MARK: - Template cell

    private func templateCell(_ item: TemplateItem) -> some View {
        ZStack(alignment: .topLeading) {
            // Preview image
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

            // Badge
            if let badge = item.badge {
                badgeView(badge)
                    .padding(6)
            }
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
