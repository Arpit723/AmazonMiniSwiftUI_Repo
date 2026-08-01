# AGENTS.md

Conventions for AI agents (and humans) working in this repo. Read this before writing or editing code.

## Project

**AmazonMiniSwiftUI** — a minimal SwiftUI shopping demo (auth, product browsing, cart, checkout, order history, profile & settings). Backend is the public **DummyJSON** mock API (`https://dummyjson.com`), which does **not** persist writes — session/profile data is mirrored locally in the Keychain.

- Bundle id: `com.brahmakumaris.amazonmini.AmazonMiniSwiftUI`
- Min deployment: **iOS 18.5** · Language: **Swift 6, strict concurrency** (`SWIFT_STRICT_CONCURRENCY = complete`)

## Build & test

Run from the **`AmazonMiniSwiftUI/`** subdirectory (where the `.xcodeproj` lives), NOT the repo root.

```bash
xcodebuild build -scheme AmazonMiniSwiftUI -destination 'platform=iOS Simulator,name=iPhone 16' -configuration Debug
xcodebuild test  -scheme AmazonMiniSwiftUI -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AmazonMiniSwiftUITests/<TestClass>
xcodebuild test  -scheme AmazonMiniSwiftUI -destination 'platform=iOS Simulator,name=iPhone 16'
```

Success = `** BUILD SUCCEEDED **` / `** TEST SUCCEEDED **` with **no new warnings**. (Two pre-existing benign warnings: multiple matching simulators; an AppIntents note from the UI-test target — ignore those.)

## Detailed conventions (read the relevant file before working in that area)

| Topic | File |
|-------|------|
| Where files/folders go | `.kilo/rules/folder-structure.md` |
| Names, tokens, components, git | `.kilo/rules/naming-conventions.md` |
| State, services, backend, DI | `.kilo/rules/api-patterns.md` |
| XCTest, mocks, TDD, commands | `.kilo/rules/testing-standards.md` |

Quick essentials: state is `@MainActor @Observable` VMs via `.environment(_:)` (no Combine); services are `Sendable` + `async/await` + `throw`; models are `Codable` + `Sendable` structs. Reuse `Core/DesignSystem/` (`PriceText`, `RemoteImage`, `PrimaryButton`, `QuantityStepper`, `.chevronOnlyBackButton()`) and the tokens in `DesignTokens.swift`.

## Hard rules

- **Do NOT edit `project.pbxproj` to add Swift files.** App & test folders are Xcode *file-system-synchronized groups* — dropping a `.swift` file in auto-includes it. (An earlier bug force-compiled app sources into the test target via `membershipExceptions`; don't re-introduce it.)
- **Pushed views must NOT wrap in their own `NavigationStack`** (it lives in `ProductListView`; follow `CartView`, not `OrderHistoryView`).
- **`#Preview` goes at file scope**, never nested inside a `struct`.
- Use `.onAppear(perform: someFunc)` (the `perform:` label is required) or the trailing-closure form.
- **Never commit `.DS_Store`** (tracked here by accident — leave any modified copy unstaged). Never commit secrets.
- `.kilo/plans/` and `docs/superpowers/` are gitignored local data — don't commit them.
- Match the file's existing style; don't restructure code outside the task.

## Git

- Work on a **feature branch** (`feature/<topic>`); don't implement on `main`.
- Commit messages: **present-tense imperative** (`Add …`, `Fix …`, `Make …`), one logical change per commit. Stage only intended files (`git status` + `git diff` first).

## Common screens (navigation)

`ProductListView` is the home/authed root with a `NavigationStack` + toolbar: leading = account (`person.crop.circle` → `SettingsView`), trailing = cart (`cart`, live `cartViewModel.itemCount` badge) and order history. Pushed: `ProductDetailView(productId:)`, `SettingsView` → `ProfileView`/`AboutView`, `CartView`, `OrderHistoryView`.
