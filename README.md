# QRCodeMaster

An iOS app for **creating** and **scanning** QR codes and barcodes, with optional **templates**, a **library** of saved items, and a **Mine** settings hub.

## Requirements

- **Xcode** 16+ (project targets recent iOS SDKs)
- **iOS** 18.6+ (see `IPHONEOS_DEPLOYMENT_TARGET` in the Xcode project)
- Swift 5 / SwiftUI / SwiftData

## Features

| Area | What it does |
|------|----------------|
| **Home** | Quick entry to create QR or barcode, template shortcut, expandable actions, trending-style previews, gear opens **Mine**. |
| **Template** | Browse procedural QR background templates; open create flow with a chosen look. |
| **Scan** | Camera scanner (QR + barcode metadata). Safer URL open for `http`/`https`; plain text and other payloads can be copied. “Leave scan” returns to **Home**. |
| **Drafts** | SwiftData **library**: folders, favorites, search, detail with share/save. |
| **Mine** (settings sheet) | VIP promo card (locks reflect subscription state), create/scan/favorites history shortcuts, sync placeholder, App Store review prompt, share sheet, Mail feedback. |

### Creation

- **QR**: payload types (URL, text, Wi‑Fi, etc. via encoder helpers), live preview, styling (colors, correction level, optional logo), template backgrounds blended in the renderer (QR centered, dark modules only over art).
- **Barcode**: Code 128 (Core Image) and **EAN‑13 / UPC** (custom encoder with debug self-check).

### Data & architecture

- **SwiftData** models: `SavedCode`, `Folder` (see `Models/`).
- **Subscription seam**: `SubscriptionStatusProvider` + `FreeSubscriptionStatus` (unlimited / “premium on” for development); `FeatureFlags` reads from the same provider for future IAP.

### Privacy

Usage strings are set in the target for **Camera** and **Photo Library** (save). Review `INFOPLIST_KEY_*` in the Xcode project if you add more capabilities.

## Building

1. Open `QRCodeMaster/QRCodeMaster.xcodeproj` in Xcode.
2. Select an iPhone simulator or device.
3. **Product → Run** (⌘R).

Command-line example:

```bash
cd QRCodeMaster
xcodebuild -scheme QRCodeMaster -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Project layout (high level)

```
QRCodeMaster/QRCodeMaster/
├── Create/           # QRCreateView, BarcodeCreateView, CreateRootView
├── Home/             # HomeView, TemplateHomeView
├── Library/          # LibraryView, LibraryFilteredView, CodeDetailView
├── Scanner/          # ScannerView, MetadataScannerView
├── Services/         # Generators, encoders, QRStyleRenderer, template catalog
├── Settings/         # MineView (settings / profile UI)
├── Subscription/     # Feature flags & subscription protocol
├── Models/           # SwiftData models
├── Utils/            # Share sheet, photo saver
├── Assets.xcassets/  # App icon, accent color
├── MainTabView.swift
├── QRCodeMasterApp.swift
└── ModelContainer+App.swift
```

## Roadmap ideas

- StoreKit **VIP / IAP** wired to `SubscriptionStatusProvider`.
- **Batch scan** and **cloud sync** (called out as placeholders in the UI).
- **AdMob** or similar if you want parity with ad-supported reference apps.

## License

Specify your license here if the repo is public.
