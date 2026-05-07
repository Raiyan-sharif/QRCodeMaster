# QRCodeMaster

An iOS app for **creating**, **customising**, and **scanning** QR codes and barcodes — with 31 payload types, rich style controls, brand-themed backgrounds, 12 finder-eye shapes, decorative templates, **batch scanning** from Home, fluid screen-transition animations, and a full saved-code library.

## Contents

- [Quick Start (User Guide)](#quick-start-user-guide)
- [Features](#features)
- [Requirements](#requirements)
- [Architecture](#architecture)
- [Building](#building)
- [Privacy Entitlements](#privacy-entitlements)
- [Roadmap](#roadmap)
- [License](#license)

### Quick links

- [QR Creation — 31 payload types across 4 pages](#qr-creation--31-payload-types-across-4-pages)
- [Customize panel (6 tabs)](#customize-panel-6-tabs)
- [Readability guardrails](#readability-guardrails)
- [Motion & transitions](#motion--transitions)
- [Key design decisions](#key-design-decisions)

## Requirements

| | |
|---|---|
| **Xcode** | 16 + |
| **iOS** | 18.6 + (`IPHONEOS_DEPLOYMENT_TARGET` in the Xcode project) |
| **Language** | Swift 5 · SwiftUI · SwiftData |

## Quick Start (User Guide)

### 1) Create a QR or barcode

1. Open the app and go to **Home**.
2. Tap **Create QR** or **Create Barcode**.
3. Pick a type (Text, URL, WiFi, Contact, Email, etc.).
4. Fill in the form fields and continue.

### 2) Customize the design

Use the 6 customization tabs:

- **Template**: choose a decorative background.
- **Color**: set foreground and background colors or choose a brand image style.
- **Logo**: place a center logo/photo.
- **Text**: add caption text below the code.
- **Dots**: change module shape style.
- **Eyes**: choose finder-eye style.

Tip: If readability is important, avoid low-contrast foreground/background combinations.

### 3) Verify before sharing

On the saved preview screen, tap **Verify QR Code** to test if the generated code is readable.  
Verification uses **Apple Vision** with several passes (orientation, upscaling, high-contrast mono) so styled QRs are more likely to decode in-app than with a single raw bitmap pass. Real-world scanners can still differ; Vision is intentionally strict.

This is useful after applying heavy styling, logos, or decorative backgrounds.

The customizer also runs a **Readability Advisor** during style changes: contrast, logo coverage, module size, quiet zone, and decorative-shape risk are analyzed so the app can suggest safer settings before export. New styles default to **error correction H** for stronger recovery.

### 4) Save and share

- Save the generated code to app library (**Drafts**).
- Export to Photos.
- Share using the iOS share sheet.

### 5) Scan codes

**Single scan (Scan tab)**

1. Open **Scan**.
2. Point camera at a QR/barcode.
3. `http/https` links open safely in browser.
4. Non-link payloads stay in-app so you can copy them.
5. Use **Save to Folder** (clipboard helper) to save pasted text directly.

**Batch scan (Home → Quick actions → Batch Scan)**

1. Scan many codes in one session; **URLs are not opened automatically** so you can keep scanning.
2. Use the **⋯** menu to **Copy all text**, **Save all to Drafts**, or **Clear list**. Swipe left on a row to remove one entry.

### 6) Manage Drafts

- Search by title/payload.
- Organize into folders.
- Mark favorites.
- Swipe left on an item to delete.

## Features

### Tabs

| Tab | Description |
|-----|-------------|
| **Home** | Quick-create shortcuts (QR / Barcode), **Batch Scan** (multi-code session → Drafts / copy all), template shortcut, trending-style cards, gear icon opens **Mine**. Staggered entrance on appear; primary cards and quick actions use press-scale feedback. |
| **Template** | **27** procedural full-canvas backgrounds, each assigned to **exactly one** gallery filter: **Hot**, **Social**, **Love**, **Vcard**, **Business**, **Wifi** (no template is listed under more than one tab). Tapping a cell opens Create → Customize with that template pre-selected. |
| **Scan** | Camera scanner for QR codes and all major barcode formats. Safe URL opening for `http`/`https`; non-URL payloads stay in-app for copy. Clipboard helper is labeled **Save to Folder** and confirms before saving. |
| **Drafts** | SwiftData-backed library with folders, favorites, full-text search, detail view, share, save-to-photos, and native swipe-to-delete rows. |

Tab switching uses SwiftUI **`TabView`** with a material tab bar (`MainTabView`) so system hit-testing and safe areas behave correctly on all device sizes.

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
| **Template** | **None** plus all catalog templates in a horizontal strip. Same **27** built-in styles as the Template tab (`QRBackgroundTemplateCatalog.allTemplates`); categories are for the gallery only — the customizer lists every style in one row. |
| **Color** | Foreground hex, background solid swatches. **Background → Image**: 22 brand cells (see `QRBackgroundTemplateCatalog.brandItems`: Instagram, WhatsApp, Facebook, Pinterest, Viber, Snapchat, Skype, Spotify, YouTube, PayPal, TikTok, LINE, LinkedIn, WeChat, X, Bitcoin, Ethereum, BNB, Telegram, Messenger, Discord, Reddit). Brand selection paints the brand gradient plus a **subtle centred SF Symbol** (same identifier as the picker) into the inner QR card; the outer canvas stays white or shows the decorative template. |
| **Logo** | Photo picker; scales to at most 22 % of QR width with a white backdrop. |
| **Text** | Caption label drawn below the exported image. |
| **Dots** | 11 module shapes: Square, Rounded, Dot, **2×2 / 3×3 / 4×4 / 5×5 Dots**, **3×2 Dots**, **Plus Dots**, **Photo dots**, Diamond. |
| **Eyes** | 12 finder-eye styles (see table below). |

Customize toolbar and preview animations: [Motion & transitions](#motion--transitions).

Generated output preview (`QRSavedView`) also includes **Verify QR Code**, backed by `QRImageVerifier` (Vision, multi-pass). The live customizer preview uses the same verifier after each render. Preview/export raster size defaults to **768 pt** for sharper modules (better for Vision and for sharing).

### Readability guardrails

- `QRReadabilityAdvisor` scores style risk using contrast ratio, quiet-zone estimate, module pixel size, payload density, logo coverage, and decorative-style penalties.
- Dense/high-risk combinations can trigger safe defaults: black-on-white colors, square modules, square finder eyes, smaller logo cap, higher error correction (`H`), and readability underlay preference.
- Dense payload mode constrains styling in the customizer (non-square module/eye styles are disabled) to preserve decode reliability.
- One-tap fix actions are exposed for common issues (`Increase Contrast`, `Reduce Logo`, `Simplify Dots`, `Apply All & Retry`).

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

`BrandIconView` (Color panel grid only) draws **custom marks** and SF Symbol composites on each brand gradient (no remote image loads), so the picker works fully **offline** and avoids noisy network failures in development. Whole cell at **90 % opacity**.

The **exported QR** uses the same approach: `QRStyleRenderer` draws the inner card with gradient colours and a low-opacity **system SF Symbol** for that brand so exports stay fast and consistent with the picker.

### Motion & transitions

| Area | Behaviour | Primary types / files |
|------|-----------|-------------------------|
| **Root tabs** | Native `TabView` + `tabItem` labels; material tab bar background. Each tab owns a `NavigationStack` (standard lazy behaviour). | `MainTabView.swift` |
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
│   ├── BatchScanView.swift        # Multi-scan session from Home; save-all to Drafts
│   └── MetadataScannerView.swift
├── Services/
│   ├── QRGeneratorService.swift         # CIFilter QR + module-matrix extraction; correction level normalized (falls back to H)
│   ├── QRStyleRenderer.swift            # CoreGraphics renderer (background, modules, eyes, logo, frame, caption)
│   ├── QRStyleOptions.swift             # Style model — Codable, Equatable, backward-compat; default error correction H
│   ├── QRPayloadEncoder.swift           # 31 payload types + structured payload structs
│   ├── QRBackgroundTemplateCatalog.swift # 27 categorized decorative templates + 22 brand items
│   ├── QRReadabilityAdvisor.swift       # Risk scoring + safe-style fallback actions
│   ├── QRImageVerifier.swift            # Vision barcode verify (multi-pass) vs expected payload
│   ├── BarcodeGeneratorService.swift
│   └── EAN13Encoder.swift
├── Shared/
│   ├── BrandIconView.swift        # Brand grid: custom-drawn marks on gradients (offline)
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
├── MainTabView.swift               # TabView shell; Home / Template / Scan / Drafts
├── QRCodeMasterApp.swift
└── ModelContainer+App.swift      # Ensures Application Support exists before SwiftData store URL
```

### Key design decisions

| Decision | Rationale |
|----------|-----------|
| Module-matrix extraction at native QR resolution | Prevents `count == outputPoints` (export size) confusion that breaks the 7×7 finder-region guard. |
| Even-odd winding for finder-eye voids | Leaves the void area truly transparent so any background (template, brand gradient) shows through. |
| Brand background as inner-card gradient + logo mark | Full-canvas gradient was user-reported wrong; `ctx.clip()` + `ctx.drawLinearGradient` restricts it to the inner 72 % rect. |
| Direct `CGContext.drawLinearGradient` for brand step | Avoids nested `UIGraphicsBeginImageContextWithOptions` context issues that broke clipping when using intermediate `UIImage.draw`. |
| `Task.detached` for rendering | Keeps the main actor / SwiftUI free during the ~50 ms CoreGraphics render. |
| Manual `Codable` on `QRStyleOptions` | Backward-compatible decoding: unknown keys fall back to defaults rather than throwing. |
| Native `TabView` for root navigation | Reliable hit testing and safe-area behaviour across devices (replacing a custom overlay tab bar). |
| `ModelContainer` store URL | Application Support directory is created up front so SwiftData does not race on first launch. |
| `QRImageVerifier` multi-pass Vision | Correct EXIF orientation, optional upscale, high-contrast mono, and latest supported barcode revision to reduce false “unreadable” results on styled QRs. |
| 4-module quiet zone in plain layout | Matches common QR decoding guidance; improves compatibility with stricter scanners/vision passes compared with tighter margins. |
| Default error correction **H** | Stronger QR recovery; invalid stored correction strings fall back to H in `QRGeneratorService`. |
| `renderVersion` Int bumped per render | Gives each QR image a unique `.id()` so SwiftUI replaces it with a cross-fade transition rather than an in-place swap. |
| `PressScaleButtonStyle` with configurable `scale` | Centralises press-feedback so every tappable surface (primary cards, grid buttons, type icons) shares one consistent spring curve. |
| Direction-aware panel slide in `QRCustomizeView` | `prevPanel` index comparison determines `.leading` vs `.trailing` edge so the panel always slides in the intuitive direction. |
| Template gallery partition | `CatalogEntry.category` assigns each decorative ID to a single `GalleryCategory`; `templates(in:)` filters so Hot / Social / Love / Vcard / Business / Wifi lists never overlap. |
| `QRReadabilityAdvisor` preflight checks | Centralizes readability heuristics and safe defaults so high-risk style combos can be corrected before share/export. |

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
- **Cloud sync** — placeholder toggle in `MineView`.
- **AdMob / ads** — banner slot reserved in `HomeView`.

## License

No open-source license file is currently included in this repository.  
Unless stated otherwise, treat this code as all rights reserved.
