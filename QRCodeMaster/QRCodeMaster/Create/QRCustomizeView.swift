//
//  QRCustomizeView.swift
//  QRCodeMaster
//

import PhotosUI
import SwiftData
import SwiftUI

struct QRCustomizeView: View {
    let payload: String
    let payloadType: QRPayloadType
    var initialStyle: QRStyleOptions = .default

    @Environment(\.modelContext) private var modelContext
    @Environment(\.featureFlags)  private var features

    @State private var style: QRStyleOptions
    @State private var logoItem:  PhotosPickerItem?
    @State private var logoImage: UIImage?
    @State private var rendered:    UIImage?
    @State private var isRendering: Bool = false
    @State private var renderTask:  Task<Void, Never>?
    @State private var activePanel: Panel?
    @State private var navigateToSaved = false
    @State private var savedImage: UIImage?

    // Color panel state
    @State private var colorTab: ColorTab = .foreground

    // Text panel state
    @State private var editCaption: String = ""
    @State private var editCaptionColor: Color = .black

    // Gradient / color swatches
    private let solidPresets: [Color] = [
        .black, .white,
        Color(red: 0.95, green: 0.25, blue: 0.45),
        Color(red: 0.95, green: 0.2, blue: 0.2),
        Color(red: 0.15, green: 0.35, blue: 0.75),
        Color(red: 0.98, green: 0.58, blue: 0.1),
        Color(red: 0.55, green: 0.25, blue: 0.88),
        Color(red: 0.18, green: 0.72, blue: 0.65),
        Color(red: 0.15, green: 0.55, blue: 0.28),
    ]

    enum Panel: CaseIterable {
        case template, color, logo, text, dots, eyes
        var title: String {
            switch self {
            case .template: "Template"
            case .color:    "Color"
            case .logo:     "Logo"
            case .text:     "Text"
            case .dots:     "Dots"
            case .eyes:     "Eyes"
            }
        }
        var systemImage: String {
            switch self {
            case .template: "rectangle.grid.2x2.fill"
            case .color:    "paintpalette.fill"
            case .logo:     "r.circle.fill"
            case .text:     "textformat"
            case .dots:     "circle.grid.3x3.fill"
            case .eyes:     "eye.fill"
            }
        }
        var iconColor: Color {
            switch self {
            case .template: Color(red: 0.42, green: 0.45, blue: 0.95)
            case .color:    Color(red: 0.25, green: 0.72, blue: 0.45)
            case .logo:     Color(red: 0.95, green: 0.32, blue: 0.32)
            case .text:     Color(red: 0.4, green: 0.42, blue: 0.95)
            case .dots:     Color(red: 0.95, green: 0.55, blue: 0.18)
            case .eyes:     Color(red: 0.65, green: 0.32, blue: 0.95)
            }
        }
    }

    enum ColorTab { case foreground, background }

    init(payload: String, payloadType: QRPayloadType, initialStyle: QRStyleOptions = .default) {
        self.payload = payload
        self.payloadType = payloadType
        self.initialStyle = initialStyle
        _style = State(initialValue: initialStyle)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // QR Preview
            qrPreviewSection

            Divider()

            // Tool buttons
            toolButtonRow
                .padding(.vertical, 14)
                .padding(.horizontal, 20)

            // Active panel (expands inline below tools)
            if let panel = activePanel {
                Divider()
                panelContent(panel)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer(minLength: 0)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Customize")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Save") { doSave() }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.18, green: 0.72, blue: 0.65))
                    .disabled(rendered == nil)
            }
        }
        .navigationDestination(isPresented: $navigateToSaved) {
            if let img = savedImage {
                QRSavedView(image: img, payload: payload, payloadType: payloadType, styleOptions: style)
            }
        }
        .onAppear { regenerate() }
        .onChange(of: style)     { _, _ in regenerate() }
        .onChange(of: logoImage) { _, _ in regenerate() }
        .onChange(of: logoItem)  { _, new in loadLogo(new) }
    }

    // MARK: - Preview section

    private var qrPreviewSection: some View {
        ZStack {
            Color(.systemBackground)
            if let rendered {
                Image(uiImage: rendered)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(24)
                    .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
                    // Dim + spinner overlay while a new render is in flight.
                    .overlay {
                        if isRendering {
                            ZStack {
                                Color(.systemBackground).opacity(0.55)
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(1.3)
                            }
                            .allowsHitTesting(false)
                        }
                    }
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Generating…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
        .animation(.easeInOut(duration: 0.15), value: isRendering)
    }

    // MARK: - Tool button row

    private var toolButtonRow: some View {
        HStack(spacing: 0) {
            ForEach(Panel.allCases, id: \.title) { panel in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        activePanel = (activePanel == panel) ? nil : panel
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: panel.systemImage)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(activePanel == panel ? panel.iconColor : Color(.label))
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(activePanel == panel ? panel.iconColor.opacity(0.15) : Color.clear)
                            )
                        Text(panel.title)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(activePanel == panel ? panel.iconColor : Color(.secondaryLabel))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Panel content router

    @ViewBuilder
    private func panelContent(_ panel: Panel) -> some View {
        ScrollView {
            switch panel {
            case .template: templatePanel
            case .color:    colorPanel
            case .logo:     logoPanel
            case .text:     textPanel
            case .dots:     dotsPanel
            case .eyes:     eyesPanel
            }
        }
        .frame(height: 260)
        .background(Color(.systemBackground))
    }

    // MARK: - Template panel

    private var templatePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Background Template")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.top, 14)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(QRBackgroundTemplateCatalog.items) { item in
                        templateChip(item)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
    }

    private func templateChip(_ item: QRBackgroundTemplateCatalog.Item) -> some View {
        let selected = (style.backgroundTemplateId ?? "none") == item.id
        return Button {
            style.backgroundTemplateId = item.id == "none" ? nil : item.id
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemFill))
                        .frame(width: 70, height: 70)
                    if item.id == "none" {
                        Image(systemName: "rectangle.slash")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    } else if let img = QRBackgroundTemplateCatalog.previewImage(id: item.id, length: 70) {
                        Image(uiImage: img)
                            .resizable().scaledToFill()
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? Color(red: 0.18, green: 0.72, blue: 0.65) : Color.clear, lineWidth: 2.5))
                Text(item.title)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(width: 80)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Color panel

    private var colorPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Foreground / Background tab strip with X and ✓ controls
            HStack(spacing: 0) {
                Button { activePanel = nil } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(spacing: 0) {
                    colorTabButton("Foreground", tab: .foreground)
                    colorTabButton("Background", tab: .background)
                }

                Spacer()

                Button { activePanel = nil } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(red: 0.18, green: 0.72, blue: 0.65))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            Divider()

            if colorTab == .foreground {
                // Foreground: only solid colour swatches
                colorSwatchSection(
                    title: "Solid Color",
                    selectedHex: style.foregroundHex,
                    onSelect: { style.foregroundHex = $0 }
                )
            } else {
                // Background: image brand grid + solid colours
                backgroundImageSection

                Divider().padding(.leading, 16)

                colorSwatchSection(
                    title: "Solid Color",
                    selectedHex: style.backgroundHex,
                    onSelect: {
                        style.backgroundHex = $0
                        style.brandBackgroundId = nil  // clear brand image when a solid colour is chosen
                    }
                )
            }
        }
    }

    private func colorTabButton(_ label: String, tab: ColorTab) -> some View {
        Button { colorTab = tab } label: {
            VStack(spacing: 4) {
                Text(label)
                    .font(.subheadline.weight(colorTab == tab ? .semibold : .regular))
                    .foregroundStyle(colorTab == tab ? Color(red: 0.18, green: 0.72, blue: 0.65) : .secondary)
                Rectangle()
                    .fill(colorTab == tab ? Color(red: 0.18, green: 0.72, blue: 0.65) : Color.clear)
                    .frame(height: 2)
            }
            .padding(.horizontal, 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Background image grid (brand templates)

    private let brandCellSize: CGFloat = 64

    private var backgroundImageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Image")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.top, 10)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(
                    rows: Array(repeating: GridItem(.fixed(brandCellSize), spacing: 8), count: 3),
                    spacing: 10
                ) {
                    // None
                    noneCell

                    // Photo picker
                    PhotoPickerBrandCell(logoImage: $logoImage, logoItem: $logoItem)

                    // Brand templates
                    ForEach(QRBackgroundTemplateCatalog.brandItems) { brand in
                        brandCell(brand)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .frame(height: brandCellSize * 3 + 8 * 2 + 2)
        }
    }

    private var noneCell: some View {
        let isSelected = (style.brandBackgroundId ?? "none") == "none"
        return Button { style.brandBackgroundId = nil } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemFill))
                    .frame(width: brandCellSize, height: brandCellSize)
                Image(systemName: "circle.slash")
                    .font(.system(size: 22))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color(red: 0.18, green: 0.72, blue: 0.65) : Color.clear, lineWidth: 3)
            )
        }
        .buttonStyle(.plain)
    }

    private func brandCell(_ brand: QRBackgroundTemplateCatalog.BrandItem) -> some View {
        let isSelected = style.brandBackgroundId == brand.id
        return Button { style.brandBackgroundId = brand.id } label: {
            BrandIconView(brand: brand, size: brandCellSize)
                .overlay(
                    RoundedRectangle(cornerRadius: brandCellSize * 0.22, style: .continuous)
                        .stroke(isSelected ? Color(red: 0.18, green: 0.72, blue: 0.65) : Color.clear, lineWidth: 3)
                )
        }
        .buttonStyle(.plain)
    }

    private func colorSwatchSection(title: String, selectedHex: String, onSelect: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if !title.isEmpty {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // Rainbow / custom picker first
                    ColorPicker("", selection: Binding(
                        get: { Color(uiColor: UIColor(hex: selectedHex) ?? .black) },
                        set: { c in
                            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                            UIColor(c).getRed(&r, green: &g, blue: &b, alpha: &a)
                            onSelect(String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255)))
                        }
                    ))
                    .labelsHidden()
                    .frame(width: 36, height: 36)

                    // Presets
                    ForEach(solidPresets.indices, id: \.self) { idx in
                        let color = solidPresets[idx]
                        Button {
                            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                            UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
                            let hex = String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
                            onSelect(hex)
                        } label: {
                            Circle()
                                .fill(color)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle().stroke(Color(.systemBackground), lineWidth: 2)
                                        .padding(2)
                                        .opacity(uiColorHex(for: color) == selectedHex ? 1 : 0)
                                )
                                .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
    }

    private func uiColorHex(for color: Color) -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }

    // MARK: - Logo panel

    private var logoPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Logo Image")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.top, 14)

            HStack(spacing: 14) {
                // None
                Button {
                    logoImage = nil
                    logoItem  = nil
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.secondarySystemFill))
                            .frame(width: 56, height: 56)
                        Image(systemName: "circle.slash")
                            .foregroundStyle(.secondary)
                    }
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(logoImage == nil ? Color(red: 0.18, green: 0.72, blue: 0.65) : Color.clear, lineWidth: 2.5))
                }
                .buttonStyle(.plain)

                // Photos picker
                PhotosPicker(selection: $logoItem, matching: .images) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.secondarySystemFill))
                            .frame(width: 56, height: 56)
                        if let logoImage {
                            Image(uiImage: logoImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            Image(systemName: "photo.badge.plus")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(logoImage != nil ? Color(red: 0.18, green: 0.72, blue: 0.65) : Color.clear, lineWidth: 2.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)

            Text("Logo correction level")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)

            Picker("Error correction", selection: $style.errorCorrection) {
                Text("L ~7%").tag("L")
                Text("M ~15%").tag("M")
                Text("Q ~25%").tag("Q")
                Text("H ~30%").tag("H")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
    }

    // MARK: - Text panel

    private var textPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Caption text (shown below QR)")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.top, 14)

            TextField("e.g. Scan me", text: $style.captionText)
                .font(.body)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.secondarySystemFill))
                )
                .padding(.horizontal, 16)

            Text("Caption color")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.top, 4)

            colorSwatchSection(
                title: "",
                selectedHex: style.captionColorHex,
                onSelect: { style.captionColorHex = $0 }
            )
        }
    }

    // MARK: - Dots panel

    private var dotsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Module Shape")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.top, 14)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                spacing: 12
            ) {
                ForEach(QRStyleOptions.ModuleShape.allCases, id: \.rawValue) { shape in
                    Button { style.moduleShape = shape } label: {
                        VStack(spacing: 6) {
                            ModuleShapePreview(shape: shape)
                                .frame(width: 52, height: 52)
                                .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(style.moduleShape == shape ? Color(red: 0.18, green: 0.72, blue: 0.65) : Color.clear, lineWidth: 2.5)
                                )
                            Text(shape.displayName)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
    }

    // MARK: - Eyes panel

    private var eyesPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Finder Eye Style")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.top, 14)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                spacing: 12
            ) {
                ForEach(QRStyleOptions.EyeStyle.allCases, id: \.rawValue) { eye in
                    Button { style.eyeStyle = eye } label: {
                        VStack(spacing: 6) {
                            EyeStylePreview(style: eye)
                                .frame(width: 52, height: 52)
                                .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(style.eyeStyle == eye ? Color(red: 0.18, green: 0.72, blue: 0.65) : Color.clear, lineWidth: 2.5)
                                )
                            Text(eye.displayName)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
    }

    // MARK: - Actions

    private func regenerate() {
        renderTask?.cancel()
        guard !payload.isEmpty else { rendered = nil; return }

        // Capture all needed state before leaving the main actor.
        let msg       = payload
        let opts      = style
        let logo      = logoImage
        let watermark = features.watermarkEnabled

        isRendering = true
        renderTask = Task {
            // Render on a background thread so the main thread (and SwiftUI)
            // stay responsive during QR generation (UIGraphicsImageContext is
            // thread-safe for off-screen image rendering).
            let image = await Task.detached(priority: .userInitiated) {
                QRStyleRenderer.render(
                    message: msg,
                    options: opts,
                    logo: logo,
                    outputPoints: 512,
                    showWatermark: watermark
                )
            }.value

            guard !Task.isCancelled else { return }
            rendered    = image
            isRendering = false
        }
    }

    private func loadLogo(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                logoImage = UIImage(data: data)
            }
        }
    }

    private func doSave() {
        guard let img = rendered, let data = img.pngData() else { return }
        let json = try? JSONEncoder().encode(style)
        let title = payloadType.title + " · " + Date.now.formatted(date: .abbreviated, time: .shortened)
        let item = SavedCode(
            kind: .qr,
            payload: payload,
            title: title,
            thumbnailData: data,
            source: .created,
            styleOptionsJSON: json
        )
        modelContext.insert(item)
        try? modelContext.save()
        savedImage = img
        navigateToSaved = true
    }
}

// MARK: - Brand photo-picker cell

private struct PhotoPickerBrandCell: View {
    @Binding var logoImage: UIImage?
    @Binding var logoItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $logoItem, matching: .images) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemFill))
                    .frame(width: 64, height: 64)
                if let img = logoImage {
                    Image(uiImage: img)
                        .resizable().scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                } else {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Module shape mini-preview

private struct ModuleShapePreview: View {
    let shape: QRStyleOptions.ModuleShape

    private let grid = [(0,0),(0,1),(0,2),(1,0),(1,2),(2,0),(2,1),(2,2)]
    private let side: CGFloat = 9

    var body: some View {
        Canvas { ctx, size in
            let step = (size.width - 2) / 3
            let color = GraphicsContext.Shading.color(.black)
            for (r, c) in grid {
                let x = 1 + CGFloat(c) * step + step * 0.1
                let y = 1 + CGFloat(r) * step + step * 0.1
                let rect = CGRect(x: x, y: y, width: step * 0.8, height: step * 0.8)
                let path: Path
                switch shape {
                case .square:   path = Path(rect)
                case .rounded:  path = Path(roundedRect: rect, cornerRadius: rect.width * 0.3)
                case .dot:      path = Path(ellipseIn: rect)
                case .diamond:
                    var p = Path()
                    let cx = rect.midX, cy = rect.midY, half = rect.width * 0.5
                    p.move(to: CGPoint(x: cx, y: cy - half))
                    p.addLine(to: CGPoint(x: cx + half, y: cy))
                    p.addLine(to: CGPoint(x: cx, y: cy + half))
                    p.addLine(to: CGPoint(x: cx - half, y: cy))
                    p.closeSubpath()
                    path = p
                }
                ctx.fill(path, with: color)
            }
        }
        .padding(8)
    }
}

// MARK: - Eye style mini-preview

private struct EyeStylePreview: View {
    let style: QRStyleOptions.EyeStyle

    var body: some View {
        Canvas { ctx, size in
            let ink = GraphicsContext.Shading.color(.primary)
            let lw: CGFloat = 3
            let pad: CGFloat = 6
            let outer  = CGRect(x: pad, y: pad, width: size.width - pad * 2, height: size.height - pad * 2)
            let iPad   = outer.width * 0.28
            let inner  = outer.insetBy(dx: iPad, dy: iPad)
            let outerR = outer.width * 0.25
            let innerR = inner.width * 0.25

            switch style {

            // ── Original 4 ────────────────────────────────────────────────
            case .square:
                ctx.stroke(Path(outer), with: ink, lineWidth: lw)
                ctx.fill(Path(inner), with: ink)

            case .roundedLeaf:
                ctx.stroke(Path(roundedRect: outer, cornerRadius: outerR), with: ink, lineWidth: lw)
                ctx.fill(Path(roundedRect: inner, cornerRadius: innerR), with: ink)

            case .circle:
                ctx.stroke(Path(ellipseIn: outer), with: ink, lineWidth: lw)
                ctx.fill(Path(ellipseIn: inner), with: ink)

            case .squareCircle:
                ctx.stroke(Path(outer), with: ink, lineWidth: lw)
                ctx.fill(Path(ellipseIn: inner), with: ink)

            // ── 8 New styles ───────────────────────────────────────────────
            case .circleSquare:
                ctx.stroke(Path(ellipseIn: outer), with: ink, lineWidth: lw)
                ctx.fill(Path(inner), with: ink)

            case .squareDiamond:
                ctx.stroke(Path(outer), with: ink, lineWidth: lw)
                ctx.fill(diamondPath(inner), with: ink)

            case .diamond:
                ctx.stroke(diamondPath(outer), with: ink, lineWidth: lw)
                ctx.fill(diamondPath(inner), with: ink)

            case .roundedCircle:
                ctx.stroke(Path(roundedRect: outer, cornerRadius: outerR), with: ink, lineWidth: lw)
                ctx.fill(Path(ellipseIn: inner), with: ink)

            case .squareRounded:
                ctx.stroke(Path(outer), with: ink, lineWidth: lw)
                ctx.fill(Path(roundedRect: inner, cornerRadius: inner.width * 0.45), with: ink)

            case .circleRound:
                ctx.stroke(Path(ellipseIn: outer), with: ink, lineWidth: lw)
                ctx.fill(Path(roundedRect: inner, cornerRadius: inner.width * 0.28), with: ink)

            case .concentric:
                ctx.stroke(Path(ellipseIn: outer), with: ink, lineWidth: lw)
                ctx.stroke(Path(ellipseIn: inner), with: ink, lineWidth: lw * 0.8)

            case .roundedDiamond:
                ctx.stroke(Path(roundedRect: outer, cornerRadius: outerR), with: ink, lineWidth: lw)
                ctx.fill(diamondPath(inner), with: ink)
            }
        }
        .padding(8)
    }

    // Diamond (axis-aligned rhombus) path helper
    private func diamondPath(_ rect: CGRect) -> Path {
        var p = Path()
        p.move(to:    CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

#Preview {
    NavigationStack {
        QRCustomizeView(payload: "https://apple.com", payloadType: .url)
    }
    .modelContainer(AppModelContainer.make(inMemory: true))
}
