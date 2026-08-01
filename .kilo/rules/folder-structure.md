# Folder Structure

Where things live and where to add new code.

## Layout

```
AmazonMiniSwiftUI/AmazonMiniSwiftUI/
├── AmazonMiniSwiftUIApp.swift   # @main; builds/injects VMs via .environment(_:)
├── RootView.swift               # auth-gated: isLoggedIn ? ProductListView : AuthFlowView
├── Core/                        # shared infrastructure only (not a feature)
│   ├── DesignSystem/            # cross-feature UI: DesignTokens, PriceText, RemoteImage, PrimaryButton, AuthInputField, BackButton
│   └── KeychainStore.swift      # generic Codable Keychain wrapper (enum, static, Sendable)
└── Screens/                     # EVERYTHING else lives in its feature folder
    ├── Auth/     {View, ViewModel, Model, Services}   # User, AuthService, AuthViewModel, AuthValidator, login/signup
    ├── Product/  {View, ViewModel, Model, Services}   # catalog + detail
    ├── Cart/     {View, ViewModel, Model, Services}   # Cart model, CartService, PaymentService, cart + checkout
    ├── Orders/   {View, ViewModel, Model, Services}   # order history + OrderStore
    ├── Profile/  {View}
    └── Settings/ {View}
```

Tests: `AmazonMiniSwiftUITests/` (unit, `@testable import AmazonMiniSwiftUI`), `AmazonMiniSwiftUIUITests/` (UI).

## Rules

- **Feature-wise at the top level.** Everything lives under `Screens/<Feature>/` — there is **no top-level `Models/` or `Services/`**. A feature's models, services, view models, and views all live together in that feature's `Model/`, `Services/`, `ViewModel/`, `View/` subfolders (only as needed — `Profile/` and `Settings/` have just `View/`).
- **One cohesive feature per folder** — don't let one folder collect multiple concerns (earlier `Product/` held cart/checkout/orders too; those were split into `Cart/` and `Orders/`).
- **Shared infrastructure only** goes in `Core/`: design-system components used by every feature (`Core/DesignSystem/`) and generic utilities like `KeychainStore`. If a type is used by exactly one feature, it belongs in that feature — not in `Core/`.
- **Cross-feature references are fine** — single module, no imports. E.g. `Cart.swift` lives in `Cart/Model/` but is read by the home screen's badge; `AuthValidator` lives in `Auth/ViewModel/` but is reused by `Profile/`. App-wide VMs (`AuthViewModel`, `CartViewModel`, `CheckoutViewModel`) live in their owning feature and are shared via `@Environment`.
- **File moves are free** — under the file-system-synchronized group, relocating a `.swift` file needs no `.pbxproj` edit and no import changes (Swift resolves types module-wide). **Do not edit `project.pbxproj` to add files.**
- A subfolder + its parents are created on demand (e.g. `Screens/Settings/View/AboutView.swift`).
