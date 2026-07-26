# Login & Signup Feature — Implementation Plan

## 1. Goal

Add authentication to AmazonMiniSwiftUI: a **Signup** screen and a **Login** screen,
with the app gated so the product/cart experience is only reachable when logged in.
Build it following the async/await + `@Observable` conventions the Cart feature
established (not the older Combine-style Product code).

**Signup fields:** Username, Full Name (auto-split), Email, Password, Confirm Password,
Gender (Male/Female), Birth Date.
**Login fields:** Username, Password.
**Password rules:** ≥8 chars, ≥1 uppercase, ≥1 lowercase, ≥1 digit; confirm must match.

## 2. Critical API realities (verified live — do not assume otherwise)

DummyJSON imposes two hard constraints that shaped every decision:

1. **Login is username-based, NOT email.**
   `POST /user/login` requires `{ username, password }`. Sending `email` returns
   `{"message":"Username and password required"}`. Seeded demo account:
   `emilys` / `emilyspass`.

2. **Registration does NOT persist.**
   `POST /users/add` returns a mock user with a new id, but a subsequent
   `/user/login` with those credentials returns `{"message":"Invalid credentials"}`.

**Consequence (our chosen strategy): "Username + local persistence".**
- Signup calls the real `POST /users/add` (to exercise the API) AND persists the new
  user's credentials locally (Keychain) so the account can actually log in.
- Login checks the local store first (self-registered users); if no local match,
  calls `POST /user/login` (works for seeded users).
- Login identifier is **username** (email login is impossible against this API).

### API reference (verified)

- **Login:** `POST /user/login`
  - Request: `{ "username": String, "password": String, "expiresInMins": Int? }`
  - Response (200): `{ id, username, email, firstName, lastName, gender, image, accessToken, refreshToken }`
  - Errors: 400 `{"message":"Username and password required"}`, 404 `{"message":"Invalid credentials"}`.

- **Register:** `POST /users/add`
  - Request: `{ firstName, lastName, username, email, password, gender, birthDate, ... }`
  - Response (mock, non-persistent): a full user object including `id`, `password`,
    `birthDate` (format `"1996-5-30"` = M-D-YYYY), `gender` (`"male"`/`"female"`).
  - NOTE: the returned `id` is throwaway; do not rely on it for login.

- **Current user (optional, future validation):** `GET /user/me` with
  `Authorization: Bearer <accessToken>`.

## 3. Resolved decisions

| Topic | Decision |
|---|---|
| Auth strategy | Username login + local persistence for self-registered users |
| Login identifier | Username (API requirement) |
| Gender | Include (Picker Male/Female → lowercase on submit) |
| Full name | Single field; auto-split first token→`firstName`, rest→`lastName` |
| Token + credential storage | Keychain |
| Routing | Conditional root; auto-restore on launch if a current user is stored; Logout clears session |
| Post-signup | Auto-login (set as current user) after successful registration |
| Observation pattern | `@Observable` + `@MainActor` (match CartViewModel) |
| Service pattern | `final class … Sendable`, async/await (match CartService) |

## 4. Architecture & conventions

Follow the Cart feature's established patterns:
- Folder structure: `Models/`, `Services/`, `Core/`, `Features/<Feature>/`.
- `@Observable` + `@MainActor` for the ViewModel; `.environment(_:)` for sharing.
- Services are `Sendable`, async/await, `URLSession.shared.data(for:)`, no Combine.
- Models are `Codable` + `Sendable` value types.
- Errors: service methods `throw`; ViewModel catches and maps to a `String?` `error`
  that views bind to.
- Project uses Xcode **file-system-synchronized groups** → new files auto-include; no
  `project.pbxproj` edits. Swift 6 + strict concurrency already on (iOS 18.5 target).

## 5. Data model — `Models/User.swift`

```swift
// Authenticated user. Tokens/password are optional: present only on some responses.
struct User: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    var firstName: String
    var lastName: String
    var username: String
    var email: String?
    var gender: String?
    var birthDate: String?     // "1996-5-30"
    var image: String?
    var password: String?      // present on /users/add + /users/{id}; absent on login
    var accessToken: String?   // present on /user/login only
    var refreshToken: String?
}

// POST /user/login body
struct LoginRequest: Encodable {
    let username: String
    let password: String
    let expiresInMins: Int?
}

// POST /users/add body
struct SignupRequest: Encodable {
    let firstName: String
    let lastName: String
    let username: String
    let email: String
    let password: String
    let gender: String         // lowercase "male"/"female"
    let birthDate: String      // "yyyy-M-d"
}
```

The login response and the `/users/add` response both decode into `User` (different
optional fields present/absent — optionals make both decode cleanly without custom
`init(from:)`).

## 6. Services

### `Core/KeychainStore.swift` — thin Keychain wrapper (stateless, `Sendable`)

```swift
enum KeychainStore {
    static func save<T: Encodable>(_ value: T, for key: String) throws
    static func load<T: Decodable>(_ type: T.Type, for key: String) throws -> T?
    static func delete(for key: String)
}
```
- Uses `SecItemAdd` / `SecItemCopyMatching` / `SecItemDelete` with `kSecClassGenericPassword`.
- Store two items:
  - `currentUser` — the active session `User` (drives `isLoggedIn`).
  - `registeredUsers` — `[User]` of self-registered accounts (each carries its `password`
    so local login can match `username`+`password`).
- No instance state → `enum` with static methods; inherently `Sendable`.

### `Services/AuthService.swift` — async/await, `Sendable` (mirror CartService)

```swift
final class AuthService: Sendable {
    private let baseURL = URL(string: "https://dummyjson.com")!
    private let session: URLSession
    init(session: URLSession = .shared) { self.session = session }

    func login(username: String, password: String) async throws -> User   // POST /user/login
    func register(_ request: SignupRequest) async throws -> User          // POST /users/add
    func currentUser(token: String) async throws -> User                  // GET /user/me (optional)
}
```
- Same private `send`/`validate` helper style as `CartService` (set `Content-Type`,
  status 2xx check, `URLError(.badServerResponse)` on failure).
- `login` decodes the 200 body (incl. tokens) into `User`; on 4xx, surface the API's
  `message` via a thrown `AuthError`.

```swift
enum AuthError: LocalizedError {
    case invalidCredentials      // API "Invalid credentials" / "Username and password required"
    case usernameTaken           // local duplicate on signup (optional check)
    case message(String)
    var errorDescription: String? { ... }
}
```

## 7. ViewModel — `Features/Auth/AuthViewModel.swift`

```swift
@MainActor
@Observable
final class AuthViewModel {
    var currentUser: User?
    var isLoading = false
    var error: String?

    var isLoggedIn: Bool { currentUser != nil }
    var displayName: String { ... }   // firstName + lastName

    private let service: AuthService
    private let keychain: KeychainStore.Type   // or an instance

    init(service: AuthService = AuthService()) { ... }

    // Called on app launch (RootView .task). Restores currentUser from Keychain.
    func restoreSessionIfNeeded()

    // Login: local-first, then API.
    func login(username: String, password: String) async

    // Signup: validate → API register → persist locally → set as current user.
    func signup(fullName: String, username: String, email: String,
                password: String, confirmPassword: String,
                gender: String, birthDate: Date) async

    func logout()
}
```

**`login` flow:**
1. Look up `username` in Keychain `registeredUsers`; if found and `password` matches →
   set `currentUser`, return (no network).
2. Else `try await service.login(...)`; on success set `currentUser` + persist to Keychain.
3. Map `AuthError.invalidCredentials` → friendly `error` string.

**`signup` flow:**
1. Run form validation (§9). On failure, set per-field errors and return.
2. Split `fullName` → `firstName`/`lastName`; format `birthDate` → `"yyyy-M-d"`; lowercase `gender`.
3. `try await service.register(SignupRequest(...))`.
4. Persist the returned user into Keychain `registeredUsers` (append).
5. Set `currentUser` (auto-login) + persist as `currentUser`.
6. Catch errors → `error` string.

**`logout`:** clear `currentUser` in Keychain + set `currentUser = nil`.

## 8. Views — `Features/Auth/`

### `LoginView.swift`
- Fields: Username, Password (`.secureField`), error text, `isLoading` disable+spinner.
- "Login" button (disabled while empty/loading), "Create account" link → toggles to Signup.
- A small demo-credential hint: "Try `emilys` / `emilyspass`".

### `SignupView.swift`
- Fields: Full Name, Username, Email, Password, Confirm Password (secure),
  Gender `Picker` (Male/Female), Birth Date `DatePicker`.
- Inline per-field validation errors under each field; "Sign Up" disabled until valid.
- "Already have an account? Log in" link → toggles to Login.
- On success the VM auto-logs-in, so RootView flips to the main app automatically.

### `AuthFlowView.swift` (container)
- Owns `@State var mode: AuthMode { login, signup }` and a `NavigationStack`.
- Shows `LoginView` or `SignupView` and switches on the links. Keeps the auth screens
  out of the product `NavigationStack`.

## 9. Validation rules (client-side, before any API call)

Implement as pure, testable functions (e.g., an `AuthValidator` enum / static methods):

- **Password:** regex `^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$` (≥8, ≥1 lower, ≥1 upper, ≥1 digit).
- **Confirm password:** must equal password.
- **Email:** basic email regex (e.g., `^[^@\s]+@[^@\s]+\.[^@\s]+$`).
- **Username:** non-empty (recommend ≥3 chars).
- **Full name:** non-empty (splittable).
- **Birth date:** a valid past date (not future; optionally ≥13 yrs — recommend no hard
  age gate for the demo, just "must be in the past").
- Return a per-field error dictionary so the UI can show inline messages.

## 10. Error handling

- Service throws `AuthError`; ViewModel maps to `String?` `error` (bind in views).
- User-facing messages: "Invalid username or password.", "This username is already taken."
  (if local duplicate check enabled), "Please fix the highlighted fields.", network fallback
  `error.localizedDescription`.
- Form validation produces inline field errors separate from the `error` banner.

## 11. App entry + routing

### `AmazonMiniSwiftUIApp.swift` (modify)
- Add `@State private var authViewModel = AuthViewModel()`.
- Inject `.environment(authViewModel)` (alongside existing `.environment(cartViewModel)`).
- Show the root router: `RootView()`.
- SwiftData `ModelContainer` wiring stays untouched.

### `RootView.swift` (new — replaces the direct `ContentView→ProductListView` start)
```swift
struct RootView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    var body: some View {
        Group {
            if authViewModel.isLoggedIn {
                ProductListView()        // main app (existing)
            } else {
                AuthFlowView()
            }
        }
        .task { authViewModel.restoreSessionIfNeeded() }
    }
}
```
- `ContentView` can be retired or repurposed; simplest is to point the App at `RootView`.
- Keep `ContentView`/SwiftData untouched to avoid scope creep (just stop using it as root).

### `ProductListView.swift` (minimal UI addition — no logic changes)
- Add a **Logout** entry to the existing toolbar (e.g., a leading `Menu` or trailing item)
  that calls `authViewModel.logout()`. (Parallel to the Cart toolbar button already added.)

## 12. Data flow

```
SIGNUP
form → validate → splitName/formatDate → POST /users/add (real, mock)
     → persist registered user (Keychain) → set currentUser → main app

LOGIN
username+password → local registeredUsers match? → set currentUser
                  → else POST /user/login → set currentUser (+tokens)
                  → main app

LAUNCH
RootView .task → restoreSessionIfNeeded → read currentUser from Keychain → main app / login

LOGOUT
clear currentUser (Keychain + state) → AuthFlowView
```

## 13. File-by-file task list (implementation order)

1. **`Models/User.swift`** — `User`, `LoginRequest`, `SignupRequest` (Codable/Sendable).
2. **`Core/KeychainStore.swift`** — generic Codable Keychain save/load/delete.
3. **`Services/AuthService.swift`** — `login`, `register`, `currentUser`; `AuthError`.
4. **`Features/Auth/AuthViewModel.swift`** — `@Observable`/`@MainActor`; login/signup/logout/restore.
5. **`Features/Auth/SignupView.swift`** — form + inline validation + gender/date pickers.
6. **`Features/Auth/LoginView.swift`** — username/password + demo hint + error/loading.
7. **`Features/Auth/AuthFlowView.swift`** — NavigationStack + login/signup toggle.
8. **`RootView.swift`** — conditional root + restore-on-appear.
9. **`AmazonMiniSwiftUIApp.swift`** — inject `authViewModel`, point at `RootView`.
10. **`ProductListView.swift`** — add Logout toolbar action.
11. **Build + manual verification** (see §15).

## 14. Swift 6 concurrency checklist

- `User`, `LoginRequest`, `SignupRequest` — `Codable` value types → `Sendable` by inference
  (all value-type members); declare `Sendable` explicitly to match `Product`/`Cart`.
- `AuthService` — no mutable state → `final class … Sendable`.
- `KeychainStore` — `enum` with static methods → no instances → `Sendable`.
- `AuthViewModel` — `@MainActor` explicit (required; `@Observable` is not implicitly
  main-actor isolated). `Task { }` closures inherit MainActor; `await service.*` suspends
  off-actor and resumes on-actor.
- Validation functions are pure (no actor needs).

## 15. Verification plan

- `xcodebuild` for the `AmazonMiniSwiftUI` scheme, generic iOS Simulator, Debug — must be
  `** BUILD SUCCEEDED **` with no new warnings.
- Manual (simulator):
  1. Cold launch → Login screen shown (no stored session).
  2. Login `emilys`/`emilyspass` → reaches ProductListView (API path).
  3. Logout → back to Login.
  4. Signup a new user (use a password like `Abcdef12`) → auto-logged-in → main app.
  5. Logout → Login with the new username/password → reaches main app (local path).
  6. Relaunch while logged in → auto-restores session, skips login.
  7. Validation: weak password / mismatched confirm / bad email → inline errors, submit disabled.
- Optionally: unit-test `AuthValidator` password/email regex and the name-split helper.

## 16. Out of scope / notes

- No real backend persistence (DummyJSON limitation); local Keychain store is the
  workaround — acceptable for a learning app, NOT production.
- No "forgot password", email verification, OAuth, or token refresh UI in v1.
- `/auth/me` validation on launch deliberately not enabled (chosen routing = restore
  without re-validation); the `AuthService.currentUser(token:)` method is included for a
  future, opt-in validation pass.
- Storing passwords in the local `registeredUsers` store is a demo simplification; a real
  app would hash + salt and use a server.
- Email field is collected on signup (matches requirements) but is **not** used for login
  (API is username-only).
