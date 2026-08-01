# API & State Patterns

## State management

- **Dominant pattern:** `@MainActor @Observable final class` view models.
- VMs are injected at the app root with `.environment(_:)` and read with `@Environment(FooViewModel.self)`. **No Combine.**
- A few legacy VMs still use `ObservableObject` + `@Published` + `@StateObject` (`ProductListViewModel`, `ProductDetailViewModel`). Match the file you're editing; prefer `@Observable` for anything new.

## Services

- `final class … Sendable`, no mutable shared state, `async/await` + `URLSession`.
- Services `throw`; the ViewModel catches and maps the error to a `String? error` the view binds to.
- Models are `Codable` + `Sendable` value types (`struct`).

## Backend (DummyJSON)

- Base URL: `https://dummyjson.com`.
- **DummyJSON does not persist writes.** Signups, profile edits, and cart changes are mirrored locally:
  - Auth session + registered users → Keychain (`KeychainStore.Key.currentUser`, `.registeredUsers`).
  - Orders → JSON file in Documents (`OrderStore`, an `actor`).
- Don't expect a server round-trip to stick; treat local state as source of truth for the UI.

## Date format

- DummyJSON birthDate is `"yyyy-M-d"` (no leading zeros). Use `AuthValidator.formatDate(_:)` / `AuthValidator.parseBirthDate(_:)` — never re-roll a `DateFormatter`.

## Dependency injection (for testing)

- `AuthService(session: URLSession = .shared)` and `AuthViewModel(service: AuthService = AuthService())` both accept injected deps.
- Inject an ephemeral `URLSession` whose `protocolClasses` contains `MockURLProtocol` to run network code fully offline in unit tests.
