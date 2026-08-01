# Folder Structure

Where things live and where to add new code.

## Layout

```
AmazonMiniSwiftUI/AmazonMiniSwiftUI/
├── AmazonMiniSwiftUIApp.swift   # @main; builds/injects VMs via .environment(_:)
├── RootView.swift               # auth-gated: isLoggedIn ? ProductListView : AuthFlowView
├── Core/
│   ├── DesignSystem/            # shared UI: DesignTokens, PriceText, RemoteImage, PrimaryButton, AuthInputField, BackButton
│   └── KeychainStore.swift      # generic Codable Keychain wrapper (enum, static, Sendable)
├── Models/                      # app-wide value types (User, Cart)
├── Services/                    # app-wide networking (AuthService, CartService, PaymentService)
└── Screens/
    ├── Auth/        {View, ViewModel}                 # login, signup, AuthViewModel, AuthValidator
    ├── Product/     {View, ViewModel, Model, Services}# catalog + detail
    ├── Cart/        {View, ViewModel}                 # cart + checkout (CheckoutViewModel has no own view)
    ├── Orders/      {View, ViewModel, Model, Services}# order history + OrderStore
    ├── Profile/     {View}
    └── Settings/    {View}
```

Tests: `AmazonMiniSwiftUITests/` (unit, `@testable import AmazonMiniSwiftUI`), `AmazonMiniSwiftUIUITests/` (UI).

## Rules

- **Feature-per-folder** under `Screens/`. One cohesive feature per folder — don't let one folder collect multiple concerns (earlier `Product/` held cart/checkout/orders too; those were split out). Each feature uses `View/`, `ViewModel/`, `Model/`, `Services/` subfolders **only as needed** (e.g. `Profile/` and `Settings/` have only `View/`).
- **Cross-feature** types go in top-level `Models/`, `Services/`, or `Core/` — never duplicated inside a feature. `Cart.swift` stays in `Models/` because it's read across screens (home badge, cart, checkout).
- **Shared UI** (reusable across features) goes in `Core/DesignSystem/` (e.g. `BackButton.swift`, `QuantityStepper.swift`, `AuthInputField.swift`).
- **App-wide ViewModels** (injected at the `@main` root: `AuthViewModel`, `CartViewModel`, `CheckoutViewModel`) live in their owning feature folder and are shared via `@Environment` — cross-feature references are fine (single module, no imports).
- **File moves are free** — under the file-system-synchronized group, relocating a `.swift` file needs no `.pbxproj` edit and no import changes (Swift resolves types module-wide). **Do not edit `project.pbxproj` to add files.**
- A subfolder + its parents are created on demand (e.g. `Screens/Settings/View/AboutView.swift`).
