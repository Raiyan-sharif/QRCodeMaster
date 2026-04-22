# QRCodeMaster

An iOS app for **creating**, **customising**, and **scanning** QR codes and barcodes — with 31 payload types, rich style controls, brand-themed backgrounds, 12 finder-eye shapes, decorative templates, fluid screen-transition animations, and a full saved-code library.

## Contents

- [Requirements](#requirements)
- [Features](#features)
  - [Motion & transitions](#motion--transitions)
- [Architecture](#architecture)
- [Building](#building)
- [Privacy entitlements](#privacy-entitlements)
- [Roadmap](#roadmap)
- [License](#license)

## Requirements

| | |
|---|---|
| **Xcode** | 16 + |
| **iOS** | 18.6 + (`IPHONEOS_DEPLOYMENT_TARGET` in the Xcode project) |
| **Language** | Swift 5 · SwiftUI · SwiftData |

## Features

### Tabs

| Tab | Description |
|-----|-------------|
| **Home** | Quick-create shortcuts (QR / Barcode), template gallery preview, trending-style cards, gear icon opens **Mine**. Staggered entrance on appear; primary cards and quick actions use press-scale feedback. |
| **Template** | Browse procedural background templates (Sunset, Ocean, Forest, Paper, Grid, …) organized by category. Tapping opens the full Create → Customize flow with the template pre-loaded. |
| **Scan** | Camera scanner for QR codes and all major barcode formats. Safe URL opening for `http`/`https`; all other payloads can be copied. |
| **Drafts** | SwiftData-backed library with folders, favorites, full-text search, detail view, share, and save-to-photos. |

Tab switching is implemented in `MainTabView` with a **custom tab bar** (not `TabView`): see [Motion & transitions](#motion--transitions).

### QR Creation — 31 payload types across 4 pages

| Page | Types |
|------|-------|
| 1 | Text, URL, Instagram, Contact, Facebook, WiFi, WhatsApp, YouTube |
| 2 | Email, Review, Threads, Discord, SMS, TikTok, Line, Phone |
| 3 | Truth Social, Spotify, PayPal, LinkedIn, Calendar, Crypto, Reddit, Skype |
| 4 | Messenger, Pinterest, Viber, WeChat, X, Telegram, Snapchat |

Structured input forms (multi-field) for: **WiFi**, **Contact** (name, phone, fax, email, company, job title, address, website, memo), **SMS**, **Email**, **Spotify**, **Calendar**.  
Phone-based types include an **interactive country-code picker** with flag emoji, localized name, and dial code — defaults to the device locale.

Type selection and input-area transitions are described under [Motion & transitions](#motion--transitions).

### Customize panel (6 tabs)

| Panel | Options |
|-------|---------|
| **Template** | **None** plus 8 full-canvas procedural backgrounds (Sunset, Ocean, Forest, Paper, Soft grid, Dots, Midnight, Aurora). |
| **Color** | Foreground hex, background solid swatches. **Background → Image**: 22 brand cells (see `QRBackgroundTemplateCatalog.brandItems`: Instagram, WhatsApp, Facebook, Pinterest, Viber, Snapchat, Skype, Spotify, YouTube, PayPal, TikTok, LINE, LinkedIn, WeChat, X, Bitcoin, Ethereum, BNB, Telegram, Messenger, Discord, Reddit). Brand selection paints the brand gradient plus a **subtle centred SF Symbol** (same identifier as the picker) into the inner QR card; the outer canvas stays white or shows the decorative template. |
| **Logo** | Photo picker; scales to at most 22 % of QR width with a white backdrop. |
| **Text** | Caption label drawn below the exported image. |
| **Dots** | 7 module shapes: Square, Rounded, Dot, **2×2 / 3×3 / 4×4 Dots** (N×N halftone circles per dark module), Diamond. |
| **Eyes** | 12 finder-eye styles (see table below). |

Customize toolbar and preview animations: [Motion & transitions](#motion--transitions).

#### 12 finder-eye styles

| Style | Outer | Inner |
|-------|-------|-------|
| Square | Square | Square |
| Rounded | Rounded square | Rounded square |
| Circle | Circle | Circle |
| Sq+Circle | Square | Circle |
| Circ+Sq | Circle | Square |
| Sq+Diamond | Square | Diamond ◆ |
| Diamond | Diamond ◆ | Diamond ◆ |
| Rnd+Circle | Rounded square | Circle |
| Sq+Round | Square | Heavily-rounded rect |
| Circ+Round | Circle | Rounded square |
| Concentric | Circle ring | Circle ring (no fill) |
| Rnd+Diamond | Rounded square | Diamond ◆ |

All finder-eye voids use an **even-odd fill rule** so the background (solid, template, or brand gradient) shows through the void area without any white overlay.

### Barcode creation

- **Code 128** via Core Image
- **EAN-13 / UPC-A** via custom encoder with built-in check-digit self-test

### Brand icon cells

`BrandIconView` (Color panel grid only) loads the real brand logo from the **Clearbit CDN** (`logo.clearbit.com`) when online, overlaid on the brand's gradient using `.blendMode(.screen)`. Falls back to custom-drawn marks / SF Symbol composites when offline. Whole cell at **90 % opacity**.

The **exported QR** does not embed remote bitmaps: `QRStyleRenderer` draws the inner card with the same gradient colours and a low-opacity **system SF Symbol** for that brand so exports stay fast, offline-safe, and consistent with the picker’s icon family.

### Motion & transitions

| Area | Behaviour | Primary types / files |
|------|-----------|-------------------------|
| **Root tabs** | Custom tab bar; inactive tabs are opacity-hidden with a small horizontal offset and scale; spring animation on change; selected tab icon scales up with a spring. All four `NavigationStack`s remain mounted so camera, navigation, and scroll state persist. | `MainTabView.swift` |
| **Home** | Header → primary cards → quick actions → trending appear in sequence (slide up + fade, staggered delays). | `HomeView.swift` |
| **Create** | Selected payload type icon springs to ~108 %; changing type re-identifies the input block with asymmetric slide + opacity. Type grid buttons use `PressScaleButtonStyle`. | `QRCreateView.swift`, `PressScaleButtonStyle.swift` |
| **Customize** | Opening / switching panels uses direction-aware slide (based on panel order) + opacity; tool icons scale when active; each finished QR render bumps `renderVersion` so the preview image cross-fades. | `QRCustomizeView.swift` |

Shared press feedback: `PressScaleButtonStyle` (configurable scale) — used on home cards, quick-action grid, and create type cells.

---

## Architecture

```
QRCodeMaster/QRCodeMaster/
├── Create/
│   ├── QRCreateView.swift        # 31-type paginated grid + dynamic input forms
│   ├── QRCustomizeView.swift     # 6-panel customizer + EyeStylePreview canvas
│   ├── QRSavedView.swift
│   ├── BarcodeCreateView.swift
│   └── CreateRootView.swift
├── Home/
│   ├── HomeView.swift
│   └── TemplateHomeView.swift
├── Library/
│   ├── LibraryView.swift
│   ├── LibraryFilteredView.swift
│   └── CodeDetailView.swift
├── Scanner/
│   ├── ScannerView.swift
│   └── MetadataScannerView.swift
├── Services/
│   ├── QRGeneratorService.swift         # CIFilter QR + module-matrix extraction
│   ├── QRStyleRenderer.swift            # CoreGraphics renderer (background, modules, eyes, logo, frame, caption)
│   ├── QRStyleOptions.swift             # Style model — Codable, Equatable, backward-compat
│   ├── QRPayloadEncoder.swift           # 31 payload types + structured payload structs
│   ├── QRBackgroundTemplateCatalog.swift # 8 decorative templates + 22 brand items
│   ├── BarcodeGeneratorService.swift
│   └── EAN13Encoder.swift
├── Shared/
│   ├── BrandIconView.swift        # AsyncImage Clearbit + offline fallback
│   ├── CountryPickerSheet.swift   # Searchable country / dial-code picker
│   └── PressScaleButtonStyle.swift # Reusable press-scale button feedback
├── Settings/
│   └── MineView.swift
├── Models/
│   ├── SavedCode.swift
│   └── Folder.swift
├── Subscription/
│   ├── SubscriptionStatusProvider.swift
│   └── FeatureFlags.swift
├── Utils/
│   ├── ShareSheet.swift
│   └── PhotoLibrarySaver.swift
├── AppEnvironment.swift
├── MainTabView.swift               # Custom animated tab bar; four persistent NavigationStacks
├── QRCodeMasterApp.swift
└── ModelContainer+App.swift
```

### Key design decisions

| Decision | Rationale |
|----------|-----------|
| Module-matrix extraction at native QR resolution | Prevents `count == outputPoints` (512) confusion that breaks the 7×7 finder-region guard. |
| Even-odd winding for finder-eye voids | Leaves the void area truly transparent so any background (template, brand gradient) shows through. |
| Brand background as inner-card gradient + logo mark | Full-canvas gradient was user-reported wrong; `ctx.clip()` + `ctx.drawLinearGradient` restricts it to the inner 72 % rect. |
| Direct `CGContext.drawLinearGradient` for brand step | Avoids nested `UIGraphicsBeginImageContextWithOptions` context issues that broke clipping when using intermediate `UIImage.draw`. |
| `Task.detached` for rendering | Keeps the main actor / SwiftUI free during the ~50 ms CoreGraphics render. |
| Manual `Codable` on `QRStyleOptions` | Backward-compatible decoding: unknown keys fall back to defaults rather than throwing. |
| Opacity-hidden tabs instead of lazy `if selectedTab == X` | All four NavigationStacks remain in the view hierarchy at all times; camera sessions, navigation stacks, and scroll positions survive tab switches. |
| `renderVersion` Int bumped per render | Gives each QR image a unique `.id()` so SwiftUI replaces it with a cross-fade transition rather than an in-place swap. |
| `PressScaleButtonStyle` with configurable `scale` | Centralises press-feedback so every tappable surface (primary cards, grid buttons, type icons) shares one consistent spring curve. |
| Direction-aware panel slide in `QRCustomizeView` | `prevPanel` index comparison determines `.leading` vs `.trailing` edge so the panel always slides in the intuitive direction. |

---

## Building

1. Open `QRCodeMaster/QRCodeMaster.xcodeproj` in Xcode.
2. Select an iPhone simulator or device (iOS 18.6 +).
3. **Product → Run** (⌘ R).

Command-line:

```bash
cd QRCodeMaster
xcodebuild -scheme QRCodeMaster \
           -destination 'platform=iOS Simulator,name=iPhone 16' \
           build
```

### Privacy entitlements

| Key | Reason |
|-----|--------|
| `NSCameraUsageDescription` | QR / barcode scanning |
| `NSPhotoLibraryAddUsageDescription` | Save generated images |

---

## Roadmap

- **StoreKit VIP / IAP** — wire to existing `SubscriptionStatusProvider` seam; premium badge cells are already in the UI.
- **Batch scan** — placeholder button in `ScannerView`.
- **Cloud sync** — placeholder toggle in `MineView`.
- **AdMob / ads** — banner slot reserved in `HomeView`.

## License

Specify your license here if the repo is public.
