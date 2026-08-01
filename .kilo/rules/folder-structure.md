# Folder Structure

Where things live and where to add new code.

## Layout

```
AmazonMiniSwiftUI/AmazonMiniSwiftUI/
├── AmazonMiniSwiftUIApp.swift   # @main; builds/injects VMs via .environment(_:)
├── RootView.swift               # auth-gated: isLoggedIn ? ProductListView : AuthFlowView
├── Core/
│   ├── DesignSystem/            # shared UI: DesignTokens, PriceText, RemoteImage, PrimaryButton, BackButton
│   └── KeychainStore.swift      # generic Codable Keychain wrapper (enum, static, Sendable)
├── Models/                      # app-wide value types (User, Cart)
├── Services/                    # app-wide networking (AuthService, CartService, PaymentService)
└── Screens/<Feature>/{View,ViewModel,Model,Services}/   # feature-per-folder
```

Tests: `AmazonMiniSwiftUITests/` (unit, `@testable import AmazonMiniSwiftUI`), `AmazonMiniSwiftUIUITests/` (UI).

## Rules

- **Feature-per-folder** under `Screens/` (`Auth/`, `Product/`, `Profile/`, `Settings/`). Each feature folder uses `View/`, `ViewModel/`, `Model/`, `Services/` subfolders as needed.
- **Cross-feature** types go in top-level `Models/`, `Services/`, or `Core/` — never duplicated inside a feature.
- **Shared UI** (reusable across features) goes in `Core/DesignSystem/` (e.g. `BackButton.swift`, `QuantityStepper.swift`).
- **New files auto-include** — both app and test folders are Xcode file-system-synchronized groups. Dropping a `.swift` file in is enough. **Do not edit `project.pbxproj` to add files.**
- A subfolder + its parents are created on demand (e.g. `Screens/Settings/View/AboutView.swift`).
