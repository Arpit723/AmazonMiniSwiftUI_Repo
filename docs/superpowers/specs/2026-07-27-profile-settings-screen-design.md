# Profile & Settings Screen — Design Spec

- **Date:** 2026-07-27
- **Author:** Pair (Kilo + Arpit)
- **Status:** Draft, pending user review
- **Scope:** Add a **Profile screen** (view + edit user details) and a **Settings screen** (account hub) to AmazonMiniSwiftUI, reachable from the home screen after login.

---

## 1. Goals

After a user logs in, they can reach an account area from the home screen and:

1. **View & edit** their own details: **First Name, Last Name, Gender, Birthdate**.
2. **Open a Settings hub** with: **About app**, **Update Profile** (→ Profile screen), **Logout**, **Delete User**.

## 2. Non-goals (YAGNI)

- Editing email / username / password (out of scope; displayed read-only).
- Profile photo upload (avatar shown read-only if present).
- Server-side persistence of profile edits — DummyJSON does not persist writes; edits persist locally only (Keychain). This is a documented limitation, identical to the existing signup behaviour.
- Two-factor auth, password change flows.

## 3. Context (existing code)

- `User` model (`Models/User.swift:18-30`) already has `firstName`, `lastName`, `gender: String?`, `birthDate: String?` (format `"yyyy-M-d"`), plus `username`, `email?`, `image?`. Plain `Codable, Identifiable, Hashable, Sendable` struct.
- `AuthViewModel` (`Screens/Auth/ViewModel/AuthViewModel.swift`): `@MainActor @Observable`, exposes `currentUser: User?`, `isLoggedIn`, `displayName`. `logout()` is public; `persistCurrentUser()` (line 154) and `appendRegisteredUser(_:)` (line 147) are **private** and must be wrapped by new public methods.
- Session persistence uses `KeychainStore` (`Core/KeychainStore.swift`) under keys `auth.currentUser` and `auth.registeredUsers`.
- Home screen = `ProductListView` (`Screens/Product/View/ProductListView.swift`) inside a `NavigationStack`. Leading toolbar item `person.crop.circle` currently opens a `Menu` with only "Logout" (lines 50-59).
- Navigation pattern: `NavigationStack` + value-based `navigationDestination(for:)` for products; legacy `NavigationLink { Destination() } label:` for Cart/OrderHistory. Pushed views must **not** add their own `NavigationStack` (CartView convention; OrderHistoryView violates this and should not be copied).
- Reusable components: `AuthInputField`, `PrimaryButton` (`Screens/Auth/View/AuthComponents.swift`); color tokens in `Theme.swift`.
- `AuthValidator` (`Screens/Auth/ViewModel/AuthValidator.swift`): `isValidBirthDate` (line 34), `formatDate` → `"yyyy-M-d"` (line 48).
- App version: `MARKETING_VERSION = 1.0` (`project.pbxproj`); read at runtime via `Bundle.main`.
- Deployment: iOS 18.5, Swift 6 strict concurrency. New files auto-include (file-system-synchronized groups) — **no `.pbxproj` edits**.

## 4. Navigation architecture

Chosen layout (selected from three analysed options; see §9):

```
Home (ProductListView)
 └─ toolbar[leading] person.crop.circle  ──push──▶  SettingsView
        ├─ "About app"        ──push──▶  AboutView
        ├─ "Update Profile"   ──push──▶  ProfileView   (edit + Save)
        ├─ "Logout"           (confirm alert)  ▶ AuthFlowView
        └─ "Delete User"      (confirm alert)  ▶ DELETE /users/{id} + clear Keychain ▶ AuthFlowView
```

**Why Settings-first:** the Settings menu itself contains "Update Profile", so Settings must be the parent of Profile to avoid a circular path (Profile → Settings → "Update Profile" → Profile). The single `person.crop.circle` icon is the natural "account" entry point; replacing its Logout-only `Menu` with a push to Settings removes the duplicate Logout from the home bar and centralises account actions.

## 5. Screens

### 5.1 SettingsView (`Screens/Settings/View/SettingsView.swift`)

- A `Form` / `List` of rows:
  - **About app** → push `AboutView`.
  - **Update Profile** → push `ProfileView`.
  - **Logout** → destructive-styled row; presents a confirmation alert; on confirm calls `authViewModel.logout()`.
  - **Delete User** → destructive-styled row; presents a confirmation alert; on confirm calls `await authViewModel.deleteAccount()`; shows a loading state while deleting.
- `navigationTitle("Settings")`, `.navigationBarTitleDisplayMode(.inline)`.
- No own `NavigationStack` (pushed from `ProductListView`).
- Reads `@Environment(AuthViewModel.self)`.
- Local `@State` for the two alert booleans and (optionally) a deletion-in-progress flag.

### 5.2 AboutView (`Screens/Settings/View/AboutView.swift`)

- Static content: app display name, version + build (read via `Bundle.main.infoDictionary` for `CFBundleShortVersionString` / `CFBundleVersion`), a one-line description, and a small "Tech" note (SwiftUI, iOS 18+, DummyJSON demo API).
- `navigationTitle("About")`, `.navigationBarTitleDisplayMode(.inline)`.
- No external state.

### 5.3 ProfileView (`Screens/Profile/View/ProfileView.swift`)

- Read-only header: avatar (`AsyncImage` if `currentUser.image` is non-nil, else a `person.crop.circle.fill` placeholder) + `displayName` + `@username` + email caption.
- Editable inputs (reuse `AuthInputField` / `PrimaryButton` / `Theme`):
  - **First Name** — `AuthInputField`.
  - **Last Name** — `AuthInputField`.
  - **Gender** — segmented `Picker` with `.Male` / `.Female` segments (default to existing value or `.Male`). On save, lowercased to match the model (e.g. `"male"`).
  - **Birthdate** — `DatePicker` with `in: ...Date()` (past only), `.graphical` or `.compact` style, `labelsHidden()`; initialised by parsing `currentUser.birthDate` (`"yyyy-M-d"`) with the same `DateFormatter` used by `AuthValidator.formatDate`.
- **Save Changes** — `PrimaryButton`:
  - Disabled while a field is invalid (non-empty names; birthdate in the past) or while saving.
  - On tap: calls `await profileViewModel.save()` (or `authViewModel.updateProfile(...)`), shows a brief success state (e.g. a dismissible confirmation or a checkmark), then stays on screen.
- `navigationTitle("Profile")`, `.navigationBarTitleDisplayMode(.inline)`.
- No own `NavigationStack`.

## 6. State management

- **No new shared/global state.** The Profile screen edits the already-injected `AuthViewModel.currentUser`.
- Two implementation options for Profile (pick in plan):
  - **(a) Minimal:** `ProfileView` holds local `@State` copies of the editable fields, and on Save calls a new `AuthViewModel.updateProfile(firstName:lastName:gender:birthDate:)`. No new view model file. *(Recommended — least surface area.)*
  - **(b) Dedicated VM:** a small `@MainActor @Observable ProfileViewModel` seeded from `currentUser`, owning validation + the save call. Adds a file; justified only if logic grows.
- All VMs follow `@MainActor @Observable final class`; models stay `Sendable` value types; services `Sendable` + async/await.

## 7. Data & persistence

- `AuthViewModel.updateProfile(...)` (new, public):
  1. Mutate `currentUser.firstName/lastName/gender/birthDate`.
  2. Call `persistCurrentUser()` (writes `auth.currentUser` to Keychain).
  3. If the account is a locally-registered one (present in `auth.registeredUsers`), also rewrite its entry via `appendRegisteredUser(currentUser)` so the updated profile survives re-login.
- `AuthViewModel.deleteAccount()` (new, public, async):
  1. Set `isLoading = true`.
  2. Call `AuthService.deleteUser(id:)` (`DELETE /users/{id}`). Best-effort for DummyJSON; tolerate failure (the local account is still cleared).
  3. Remove the user from `auth.registeredUsers` (Keychain) if present.
  4. `KeychainStore.delete(for: .currentUser)`; `currentUser = nil` → `RootView` flips to `AuthFlowView`.
  5. Set `isLoading = false` (and clear `error`).
- `AuthService.deleteUser(id:)` (new): `DELETE {baseURL}/users/{id}`, decode the DummyJSON response (or ignore body), map non-2xx to `AuthError`.
- **No SwiftData / UserDefaults / Core Data** changes. No Combine.

## 8. Files to add / change

**Add (auto-included by synchronized groups):**
- `Screens/Settings/View/SettingsView.swift`
- `Screens/Settings/View/AboutView.swift`
- `Screens/Profile/View/ProfileView.swift`
- `Screens/Profile/ViewModel/ProfileViewModel.swift` *(only if option 6b is chosen)*

**Change:**
- `Services/AuthService.swift` — add `deleteUser(id:)`.
- `Screens/Auth/ViewModel/AuthViewModel.swift` — add public `updateProfile(...)` and `deleteAccount()`; expose/keep `persistCurrentUser`/`appendRegisteredUser` private (called internally).
- `Screens/Product/View/ProductListView.swift` — replace the leading `Menu`(Logout) toolbar item with a `NavigationLink` (or value-based push) to `SettingsView`.

## 9. Alternatives considered

- **B — Profile-first (Profile is parent of Settings):** rejected because Settings contains "Update Profile", which would create a circular Profile → Settings → Profile path.
- **C — Two home toolbar icons (person→Profile, gear→Settings):** rejected as cluttered; account actions (Logout/Delete/About) would be duplicated or orphaned across two destinations.

## 10. Verification

- Build via `xcodebuild` for scheme `AmazonMiniSwiftUI`, generic iOS Simulator, Debug → expect `** BUILD SUCCEEDED **` with **no new warnings**.
- Manual smoke: log in → person icon → Settings → Update Profile (edit fields, Save, relaunch app → edits persist via Keychain) → About → back → Logout → re-login → Delete User → returns to login and cannot re-login.
- Swift 6 strict concurrency: no new Sendable/concurrency warnings.

## 11. Open questions / risks

- DummyJSON cannot persist profile edits server-side; for seeded demo accounts (e.g. `emilys`) edits live only in local Keychain and will not appear if the same account logs in from a fresh install. Acceptable for this demo; documented in-app is not required.
- Gender vocabulary is limited to Male/Female to match the existing signup `Picker`; can be extended later.
