# QRCodeMaster

An iOS app for **creating**, **customising**, and **scanning** QR codes and barcodes — with 31 payload types, rich style controls, brand-themed backgrounds, 12 finder-eye shapes, decorative templates, and a full saved-code library.

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
| **Home** | Quick-create shortcuts (QR / Barcode), template gallery preview, trending-style cards, gear icon opens **Mine**. |
| **Template** | Browse procedural background templates (Sunset, Ocean, Forest, Paper, Grid, …) organized by category. Tapping opens the full Create → Customize flow with the template pre-loaded. |
| **Scan** | Camera scanner for QR codes and all major barcode formats. Safe URL opening for `http`/`https`; all other payloads can be copied. |
| **Drafts** | SwiftData-backed library with folders, favorites, full-text search, detail view, share, and save-to-photos. |

### QR Creation — 31 payload types across 4 pages

| Page | Types |
|------|-------|
| 1 | Text, URL, Instagram, Contact, Facebook, WiFi, WhatsApp, YouTube |
| 2 | Email, Review, Threads, Discord, SMS, TikTok, Line, Phone |
| 3 | Truth Social, Spotify, PayPal, LinkedIn, Calendar, Crypto, Reddit, Skype |
| 4 | Messenger, Pinterest, Viber, WeChat, X, Telegram, Snapchat |

Structured input forms (multi-field) for: **WiFi**, **Contact** (name, phone, fax, email, company, job title, address, website, memo), **SMS**, **Email**, **Spotify**, **Calendar**.  
Phone-based types include an **interactive country-code picker** with flag emoji, localized name, and dial code — defaults to the device locale.

### Customize panel (6 tabs)

| Panel | Options |
|-------|---------|
| **Template** | 8 full-canvas decorative backgrounds (gradient + pattern art). |
| **Color** | Foreground hex, background solid swatches. **Background → Image**: 22 brand icon cells (Instagram, WhatsApp, Facebook, YouTube, TikTok, Snapchat, Spotify, Telegram, Discord, Reddit, X, Line, LinkedIn, Pinterest, Viber, WeChat, PayPal, Skype, Messenger, Truth Social, BNB, Ethereum). Brand selection paints the brand gradient + centered logo mark into the inner QR card area; outer canvas stays white (or the decorative template). |
| **Logo** | Photo picker; scales to at most 22 % of QR width with a white backdrop. |
| **Text** | Caption label drawn below the exported image. |
| **Dots** | 4 module shapes: Square, Rounded, Dot, Diamond. |
| **Eyes** | 12 finder-eye styles (see table below). |

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

`BrandIconView` loads the real brand logo from the **Clearbit CDN** (`logo.clearbit.com`) when online, overlaid on the brand's gradient background using `.blendMode(.screen)`. Falls back to custom-drawn letter marks / SF Symbol composites when offline. Renders at 90 % opacity.

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
│   └── CountryPickerSheet.swift   # Searchable country / dial-code picker
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
├── MainTabView.swift
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
