# AGENTS.md

Conventions for AI agents (and humans) working in this repo. Read this before writing or editing code.

## Project

**AmazonMiniSwiftUI** — a minimal SwiftUI shopping demo: auth, product browsing, cart, checkout, order history, profile & settings. Backend is the public **DummyJSON** mock API (`https://dummyjson.com`), which does **not** persist writes — session/profile data is mirrored locally in the Keychain.

- Bundle id: `com.brahmakumaris.amazonmini.AmazonMiniSwiftUI`
- Min deployment: **iOS 18.5**
- Language: **Swift 6, strict concurrency** (`SWIFT_STRICT_CONCURRENCY = complete`)

## Build & test

Run from the **`AmazonMiniSwiftUI/`** subdirectory (where the `.xcodeproj` lives), NOT the repo root.

```bash
# Build (Debug)
xcodebuild build -scheme AmazonMiniSwiftUI -destination 'platform=iOS Simulator,name=iPhone 16' -configuration Debug

# One test class
xcodebuild test -scheme AmazonMiniSwiftUI -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AmazonMiniSwiftUITests/<TestClass>

# Full suite
xcodebuild test -scheme AmazonMiniSwiftUI -destination 'platform=iOS Simulator,name=iPhone 16'
```

Success criteria: `** BUILD SUCCEEDED **` / `** TEST SUCCEEDED **` with **no new warnings**. There are two pre-existing, benign warnings (multiple matching simulators; an AppIntents note from the UI-test target) — ignore those.

## Architecture & layout

```
AmazonMiniSwiftUI/AmazonMiniSwiftUI/
├── AmazonMiniSwiftUIApp.swift   # @main; injects VMs via .environment(_:)
├── RootView.swift               # auth-gated: isLoggedIn ? ProductListView : AuthFlowView
├── Core/
│   ├── DesignSystem/            # shared UI: DesignTokens, PriceText, RemoteImage, PrimaryButton, BackButton
│   └── KeychainStore.swift      # generic Codable Keychain wrapper (enum, static, Sendable)
├── Models/                      # app-wide value types (User, Cart)
├── Services/                    # app-wide networking (AuthService, CartService, PaymentService) — Sendable, async/await
└── Screens/<Feature>/{View,ViewModel,Model,Services}/   # feature-per-folder
```

- **Feature-per-folder** under `Screens/` (e.g. `Screens/Auth/`, `Screens/Product/`, `Screens/Profile/`, `Screens/Settings/`). Cross-feature types go in top-level `Models/`, `Services/`, or `Core/`.
- Tests: `AmazonMiniSwiftUITests/` (unit, `@testable import AmazonMiniSwiftUI`), `AmazonMiniSwiftUIUITests/` (UI).

## State management

- **Dominant pattern:** `@MainActor @Observable final class` view models, injected at the app root with `.environment(_:)` and read with `@Environment(FooViewModel.self)`. **No Combine.**
- A couple of legacy VMs still use `ObservableObject` + `@Published` + `@StateObject` (`ProductListViewModel`, `ProductDetailViewModel`). Match the file you're editing; prefer `@Observable` for anything new.
- Services `throw`; the ViewModel catches and maps to a `String? error` the view binds to.
- Models are `Codable` + `Sendable` value types (`struct`).
- Networking: `URLSession` + `async/await`. Services are `Sendable` (`final class`, no mutable shared state). Both `AuthService(session:)` and `AuthViewModel(service:)` accept injected dependencies — use a `MockURLProtocol` for offline unit tests (see `AmazonMiniSwiftUITests/MockURLProtocol.swift`).

## Coding conventions (follow existing patterns)

- **Reuse the design system.** Colors/tokens in `Core/DesignSystem/DesignTokens.swift`:
  - `Color.brandNavy` (headings), `.brandText`, `.brandSecondary`, `.brandOrange` (primary actions), `.brandOrangePressed`, `.fieldBackground`, `.fieldBorder`, `.hairline`, `.errorRed`, `.successGreen`, `.surface`.
  - `AppSpacing.{xs,sm,md,lg,xl}`, `AppRadius.{sm,md,lg}`, `AppFont.{largeTitle,title,title2,headline,body,subheadline,footnote,caption}`.
  - Components: `PriceText(amount:font:color:)`, `RemoteImage(urlString:contentMode:)`, `PrimaryButton(title:isLoading:isEnabled:action:)`, `AuthInputField(...)`, `QuantityStepper(quantity:onIncrement:onDecrement:)`, `.chevronOnlyBackButton()`.
- **Pushed views must NOT wrap in their own `NavigationStack`** (the `NavigationStack` lives in `ProductListView`; follow `CartView`, not `OrderHistoryView`).
- **`#Preview` goes at file scope**, never nested inside a `struct` (a nested freestanding `#Preview` fails to compile with a circular-macro error).
- Use `.onAppear(perform: someFunc)` (the `perform:` label is required), or the trailing-closure `.onAppear { … }`.
- Header comment on each file: file header block + `// MARK: -` sectioning. Keep functions small and focused.
- Birthdate format is DummyJSON's `"yyyy-M-d"` (no leading zeros). Use `AuthValidator.formatDate(_:)` / `AuthValidator.parseBirthDate(_:)` — do not re-roll a `DateFormatter`.
- Auth session lives in the Keychain under `KeychainStore.Key.currentUser` and `.registeredUsers`. Profile edits persist locally (DummyJSON won't keep them).

## Hard rules

- **Do NOT edit `project.pbxproj` to add Swift files.** Both app and test folders are Xcode *file-system-synchronized groups* — dropping a `.swift` file in auto-includes it. (An earlier bug force-compiled app sources into the test target via `membershipExceptions`; do not re-introduce that.)
- **Never commit `.DS_Store`.** It is tracked in this repo by accident — leave any modified copy unstaged.
- `.kilo/` and `docs/superpowers/` are gitignored local working data — do not commit them.
- Match the file's existing style; don't restructure code outside the task.

## Git

- Work on a **feature branch** (e.g. `feature/<topic>`); don't implement directly on `main`.
- Commit messages: **present-tense imperative** (`Add …`, `Fix …`, `Make …`). One logical change per commit.
- Stage only intended files (`git status` + `git diff` first); never commit secrets.

## Common screens (navigation)

`ProductListView` is the home/authed root with a `NavigationStack` and toolbar: leading = account (`person.crop.circle` → `SettingsView`), trailing = cart (`cart`, with live `cartViewModel.itemCount` badge) and order history. Pushed: `ProductDetailView(productId:)`, `SettingsView` → `ProfileView`/`AboutView`, `CartView`, `OrderHistoryView`.
