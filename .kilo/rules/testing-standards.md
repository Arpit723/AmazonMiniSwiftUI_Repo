# Testing Standards

## Framework

- `XCTest` + `@testable import AmazonMiniSwiftUI`. Target: `AmazonMiniSwiftUITests/` (file-system-synchronized → new test files auto-include, no `.pbxproj` edit).
- ViewModel tests are `@MainActor` (the VMs are `@MainActor`-isolated). `async` test methods are fine for async VM methods.

## Patterns

- **Avoid real network in unit tests.** For logic that doesn't need the network (e.g. `CartViewModel.quantity(for:)`), set observable state directly (`vm.items = […]`) and assert — deterministic and offline.
- **For networked code** (e.g. `AuthService.deleteUser`, `AuthViewModel.deleteAccount`), inject an ephemeral `URLSession` with `MockURLProtocol` (see `AmazonMiniSwiftUITests/MockURLProtocol.swift`) returning canned `(HTTPURLResponse, Data)`. Capture the `URLRequest` inside the handler and assert **after** the `await` (XCT assertions inside the handler don't attach to the test reliably).
- **Keychain isolation:** `tearDown` must `KeychainStore.delete` for every key a test writes (`currentUser`, `registeredUsers`). Also reset shared test state (`MockURLProtocol.handler = nil`) in `tearDown`.
- **TDD** for pure logic: write the failing test → confirm RED → implement → confirm GREEN → commit.

## Commands

```bash
# One class
xcodebuild test -scheme AmazonMiniSwiftUI -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:AmazonMiniSwiftUITests/<TestClass>

# Full suite
xcodebuild test -scheme AmazonMiniSwiftUI -destination 'platform=iOS Simulator,name=iPhone 16'
```

Run from the **`AmazonMiniSwiftUI/`** subdirectory (where the `.xcodeproj` lives), not the repo root.

## Pass criteria

`** TEST SUCCEEDED **` with pristine output. Two pre-existing, benign warnings (multiple matching simulators; an AppIntents note from the UI-test target) — ignore those; fix anything new.
