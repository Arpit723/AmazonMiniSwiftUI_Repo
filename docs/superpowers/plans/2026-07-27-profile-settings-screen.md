# Profile & Settings Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Profile screen (view + edit First Name, Last Name, Gender, Birthdate) and a Settings hub (About app, Update Profile, Logout, Delete User), reachable from the home toolbar after login.

**Architecture:** Two new SwiftUI screens pushed onto the existing `ProductListView` `NavigationStack`. Profile edits flow through `AuthViewModel.updateProfile(...)` (mutates `currentUser` + persists to Keychain; no server round-trip — DummyJSON limitation). Delete flows through `AuthViewModel.deleteAccount()` → `AuthService.deleteUser(id:)` (`DELETE /users/{id}`), best-effort, then local Keychain cleanup. Pure logic (date parsing, validation, VM/service behaviour) is unit-tested; UI screens are build-verified + manual-smoke-verified.

**Tech Stack:** SwiftUI (iOS 18.5), Swift 6 strict concurrency, `@Observable` + `@MainActor`, XCTest (`@testable import AmazonMiniSwiftUI`), async/await + URLSession, Keychain persistence.

## Global Constraints

- iOS deployment target: **18.5** (`IPHONEOS_DEPLOYMENT_TARGET = 18.5`). Use modern SwiftUI APIs freely.
- Swift 6 **`SWIFT_STRICT_CONCURRENCY = complete`**: VMs are `@MainActor @Observable final class`; models are `Sendable` value types; services are `final class … Sendable`. No Combine.
- File-system-synchronized groups: new files in `AmazonMiniSwiftUI/`, `AmazonMiniSwiftUITests/` **auto-include — no `.pbxproj` edits**.
- Naming/copy: toolbar entry icon = `person.crop.circle`; screens titled `Settings`, `Profile`, `About` (inline title display mode).
- Reuse existing components: `AuthInputField`, `PrimaryButton` (`Screens/Auth/View/AuthComponents.swift`); color tokens `Color.brandNavy`, `.brandOrange`, `.brandSecondary`, `.brandText`, `.fieldBackground`, `.fieldBorder`, `.errorRed` (`Screens/Auth/View/Theme.swift`); `AuthValidator` helpers (`Screens/Auth/ViewModel/AuthValidator.swift`).
- Pushed views must **NOT** wrap in their own `NavigationStack` (follow `CartView`, not `OrderHistoryView`).
- Build target: scheme `AmazonMiniSwiftUI`, destination `platform=iOS Simulator,name=iPhone 16` (booted), Debug. Expect `** BUILD SUCCEEDED **` with **no new warnings**.
- Commits: present-tense imperative, matching existing history (e.g. `Add …`, `Make …`).

## Spec reference

`docs/superpowers/specs/2026-07-27-profile-settings-screen-design.md`

## File structure

**Add (app target — auto-included):**
- `Screens/Settings/View/SettingsView.swift` — account hub: About / Update Profile / Logout / Delete User.
- `Screens/Settings/View/AboutView.swift` — static app/version/tech info.
- `Screens/Profile/View/ProfileView.swift` — read-only header + editable form (First/Last name, Gender, Birthdate) + Save.

**Modify (app target):**
- `Screens/Auth/ViewModel/AuthValidator.swift` — add `parseBirthDate(_:)` (reverse of `formatDate`).
- `Services/AuthService.swift` — add `deleteUser(id:)`.
- `Screens/Auth/ViewModel/AuthViewModel.swift` — add `updateProfile(...)` + `deleteAccount()` (+ private Keychain helpers).
- `Screens/Product/View/ProductListView.swift` — replace leading `Menu`(Logout) toolbar item with a `NavigationLink` → `SettingsView`.

**Add (test target — auto-included):**
- `AmazonMiniSwiftUITests/MockURLProtocol.swift` — canned-response URLProtocol for offline network tests.
- `AmazonMiniSwiftUITests/AuthValidatorTests.swift` — tests for `parseBirthDate`.
- `AmazonMiniSwiftUITests/AuthServiceTests.swift` — tests for `deleteUser`.
- `AmazonMiniSwiftUITests/AuthViewModelProfileTests.swift` — tests for `updateProfile` + `deleteAccount`.

---

### Task 1: Add `AuthValidator.parseBirthDate` (pure, TDD)

**Files:**
- Modify: `AmazonMiniSwiftUI/AmazonMiniSwiftUI/Screens/Auth/ViewModel/AuthValidator.swift` (append inside `enum AuthValidator`)
- Test: `AmazonMiniSwiftUI/AmazonMiniSwiftUITests/AuthValidatorTests.swift` (new)

**Interfaces:**
- Produces: `AuthValidator.parseBirthDate(_ string: String?) -> Date?` — returns a `Date` for DummyJSON `"yyyy-M-d"` strings (e.g. `"1996-5-30"`), `nil` for nil/empty/invalid.

- [ ] **Step 1: Write the failing test**

Create `AmazonMiniSwiftUI/AmazonMiniSwiftUITests/AuthValidatorTests.swift`:

```swift
//
//  AuthValidatorTests.swift
//  AmazonMiniSwiftUITests
//

import XCTest
@testable import AmazonMiniSwiftUI

final class AuthValidatorTests: XCTestCase {

    func testParseBirthDate_validString() {
        XCTAssertNotNil(AuthValidator.parseBirthDate("1996-5-30"))
    }

    func testParseBirthDate_nilAndEmpty() {
        XCTAssertNil(AuthValidator.parseBirthDate(nil))
        XCTAssertNil(AuthValidator.parseBirthDate(""))
    }

    func testParseBirthDate_invalid() {
        XCTAssertNil(AuthValidator.parseBirthDate("not-a-date"))
    }

    func testParseBirthDate_roundTripsWithFormatDate() throws {
        let original = try XCTUnwrap(AuthValidator.parseBirthDate("2000-1-15"))
        XCTAssertEqual(AuthValidator.formatDate(original), "2000-1-15")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
xcodebuild test -scheme AmazonMiniSwiftUI -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AmazonMiniSwiftUITests/AuthValidatorTests 2>&1 | tail -30
```
Expected: compile error — `parseBirthDate` does not exist.

- [ ] **Step 3: Write minimal implementation**

Append inside `enum AuthValidator` in `Screens/Auth/ViewModel/AuthValidator.swift`, just after `formatDate`:

```swift
    // Inverse of formatDate: parses DummyJSON's "yyyy-M-d" string (e.g. "1996-5-30")
    // back into a Date. Returns nil for nil/empty/invalid input.
    static func parseBirthDate(_ string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-M-d"
        return formatter.date(from: string)
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run the same command as Step 2.
Expected: `** TEST SUCCEEDED **`, 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add AmazonMiniSwiftUI/AmazonMiniSwiftUI/Screens/Auth/ViewModel/AuthValidator.swift AmazonMiniSwiftUI/AmazonMiniSwiftUITests/AuthValidatorTests.swift
git commit -m "Add AuthValidator.parseBirthDate"
```

---

### Task 2: Add `AuthService.deleteUser` + test mock (TDD)

**Files:**
- Modify: `AmazonMiniSwiftUI/AmazonMiniSwiftUI/Services/AuthService.swift` (add method inside `final class AuthService`)
- Test: `AmazonMiniSwiftUI/AmazonMiniSwiftUITests/MockURLProtocol.swift` (new), `AmazonMiniSwiftUI/AmazonMiniSwiftUITests/AuthServiceTests.swift` (new)

**Interfaces:**
- Consumes: `AuthService(session:)` init already accepts a `URLSession`.
- Produces: `AuthService.deleteUser(id: Int) async throws` — sends `DELETE {baseURL}/users/{id}`, validates HTTP status (throws `AuthError` on non-2xx). Response body is ignored.

- [ ] **Step 1: Write the network mock helper**

Create `AmazonMiniSwiftUI/AmazonMiniSwiftUITests/MockURLProtocol.swift`:

```swift
//
//  MockURLProtocol.swift
//  AmazonMiniSwiftUITests
//

import Foundation

/// Returns canned responses so AuthService/AuthViewModel tests run offline.
/// Set `MockURLProtocol.handler` before exercising code that uses the injected
/// URLSession built from `URLSessionConfiguration.ephemeral` with this class in
/// `protocolClasses`.
final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocol didFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
```

- [ ] **Step 2: Write the failing tests**

Create `AmazonMiniSwiftUI/AmazonMiniSwiftUITests/AuthServiceTests.swift`:

```swift
//
//  AuthServiceTests.swift
//  AmazonMiniSwiftUITests
//

import XCTest
@testable import AmazonMiniSwiftUI

final class AuthServiceTests: XCTestCase {

    private func makeService() -> AuthService {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return AuthService(session: URLSession(configuration: config))
    }

    func testDeleteUser_success_sendsDELETE() async throws {
        var captured: URLRequest?
        MockURLProtocol.handler = { request in
            captured = request
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data("{}".utf8))
        }
        try await makeService().deleteUser(id: 42)
        let request = try XCTUnwrap(captured)
        XCTAssertEqual(request.httpMethod, "DELETE")
        XCTAssertEqual(request.url?.absoluteString, "https://dummyjson.com/users/42")
    }

    func testDeleteUser_throwsOn404() async {
        MockURLProtocol.handler = { request in
            let body = Data(#"{"message":"User not found"}"#.utf8)
            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return (response, body)
        }
        do {
            try await makeService().deleteUser(id: 99)
            XCTFail("Expected deleteUser to throw")
        } catch {
            XCTAssertTrue(error is AuthError)
        }
    }
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run:
```bash
xcodebuild test -scheme AmazonMiniSwiftUI -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AmazonMiniSwiftUITests/AuthServiceTests 2>&1 | tail -30
```
Expected: compile error — `deleteUser` does not exist.

- [ ] **Step 4: Write minimal implementation**

Add inside `final class AuthService` (e.g. just after `currentUser(token:)`), in `Services/AuthService.swift`:

```swift
    // DELETE /users/{id} — best-effort account removal. DummyJSON returns the deleted
    // user (or 404 for ids it never persisted). Response body is intentionally ignored.
    func deleteUser(id: Int) async throws {
        var request = URLRequest(url: baseURL.appending(path: "users/\(id)"))
        request.httpMethod = "DELETE"
        let (data, response) = try await session.data(for: request)
        try Self.validate(response, data: data)
    }
```

- [ ] **Step 5: Run tests to verify they pass**

Run the Step 3 command.
Expected: `** TEST SUCCEEDED **`, 2 tests pass.

- [ ] **Step 6: Commit**

```bash
git add AmazonMiniSwiftUI/AmazonMiniSwiftUI/Services/AuthService.swift AmazonMiniSwiftUI/AmazonMiniSwiftUITests/MockURLProtocol.swift AmazonMiniSwiftUI/AmazonMiniSwiftUITests/AuthServiceTests.swift
git commit -m "Add AuthService.deleteUser"
```

---

### Task 3: Add `AuthViewModel.updateProfile` (TDD)

**Files:**
- Modify: `AmazonMiniSwiftUI/AmazonMiniSwiftUI/Screens/Auth/ViewModel/AuthViewModel.swift` (add methods)
- Test: `AmazonMiniSwiftUI/AmazonMiniSwiftUITests/AuthViewModelProfileTests.swift` (new)

**Interfaces:**
- Consumes: existing private `persistCurrentUser()` and `KeychainStore`.
- Produces: `AuthViewModel.updateProfile(firstName: String, lastName: String, gender: String, birthDate: String)` — trims names, lowercases gender, mutates `currentUser`, persists to `auth.currentUser`, and refreshes the `auth.registeredUsers` entry **only if the account is already locally registered** (so seeded DummyJSON accounts like `emilys` are not copied into local storage).

- [ ] **Step 1: Write the failing tests**

Create `AmazonMiniSwiftUI/AmazonMiniSwiftUITests/AuthViewModelProfileTests.swift`:

```swift
//
//  AuthViewModelProfileTests.swift
//  AmazonMiniSwiftUITests
//

import XCTest
@testable import AmazonMiniSwiftUI

final class AuthViewModelProfileTests: XCTestCase {

    private func makeUser(username: String, password: String? = "Secret1") -> User {
        User(id: 1, firstName: "Old", lastName: "Name", username: username, email: nil,
             gender: "male", birthDate: "1990-1-1", image: nil, password: password,
             accessToken: nil, refreshToken: nil)
    }

    override func tearDown() {
        KeychainStore.delete(for: KeychainStore.Key.currentUser)
        KeychainStore.delete(for: KeychainStore.Key.registeredUsers)
    }

    @MainActor
    func testUpdateProfile_mutatesCurrentUserAndPersists() throws {
        let vm = AuthViewModel(service: AuthService())
        vm.currentUser = makeUser(username: "tester")

        vm.updateProfile(firstName: "Jane", lastName: "Doe", gender: "Female", birthDate: "1995-6-15")

        XCTAssertEqual(vm.currentUser?.firstName, "Jane")
        XCTAssertEqual(vm.currentUser?.lastName, "Doe")
        XCTAssertEqual(vm.currentUser?.gender, "female")
        XCTAssertEqual(vm.currentUser?.birthDate, "1995-6-15")

        let persisted = try KeychainStore.load(User.self, for: KeychainStore.Key.currentUser)
        XCTAssertEqual(persisted?.firstName, "Jane")
        XCTAssertEqual(persisted?.birthDate, "1995-6-15")
    }

    @MainActor
    func testUpdateProfile_refreshesLocalRegisteredEntry() throws {
        let local = makeUser(username: "localuser")
        try KeychainStore.save([local], for: KeychainStore.Key.registeredUsers)

        let vm = AuthViewModel(service: AuthService())
        vm.currentUser = local

        vm.updateProfile(firstName: "New", lastName: "Name", gender: "male", birthDate: "1990-1-1")

        let registered = try KeychainStore.load([User].self, for: KeychainStore.Key.registeredUsers) ?? []
        XCTAssertEqual(registered.count, 1)
        XCTAssertEqual(registered.first?.firstName, "New")
    }

    @MainActor
    func testUpdateProfile_doesNotAddSeededAccountToRegistered() throws {
        let seeded = User(id: 1, firstName: "Emily", lastName: "Blunt", username: "emilys",
                          email: nil, gender: "female", birthDate: "1996-5-30", image: nil,
                          password: nil, accessToken: "tok", refreshToken: nil)

        let vm = AuthViewModel(service: AuthService())
        vm.currentUser = seeded

        vm.updateProfile(firstName: "Em", lastName: "B", gender: "female", birthDate: "1996-5-30")

        let registered = try KeychainStore.load([User].self, for: KeychainStore.Key.registeredUsers)
        XCTAssertNil(registered)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:
```bash
xcodebuild test -scheme AmazonMiniSwiftUI -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AmazonMiniSwiftUITests/AuthViewModelProfileTests 2>&1 | tail -30
```
Expected: compile error — `updateProfile` does not exist.

- [ ] **Step 3: Write minimal implementation**

Add inside `final class AuthViewModel` (e.g. just before `// MARK: Logout`), in `Screens/Auth/ViewModel/AuthViewModel.swift`:

```swift
    // MARK: Profile update

    // Updates the current user's editable fields and persists to Keychain. For locally
    // registered accounts the registeredUsers entry is also refreshed so the change
    // survives logout/re-login. DummyJSON does not persist this server-side.
    func updateProfile(firstName: String, lastName: String, gender: String, birthDate: String) {
        guard currentUser != nil else { return }
        currentUser?.firstName = firstName.trimmingCharacters(in: .whitespaces)
        currentUser?.lastName = lastName.trimmingCharacters(in: .whitespaces)
        currentUser?.gender = gender.lowercased()
        currentUser?.birthDate = birthDate
        persistCurrentUser()
        refreshRegisteredUserIfPresent()
    }

    // Re-writes the local registeredUsers entry for the current user only if it already
    // exists (so seeded DummyJSON accounts are never copied into local storage).
    private func refreshRegisteredUserIfPresent() {
        guard let user = currentUser else { return }
        var registered = (try? KeychainStore.load([User].self, for: KeychainStore.Key.registeredUsers)) ?? []
        guard registered.contains(where: { $0.username.caseInsensitiveCompare(user.username) == .orderedSame }) else {
            return
        }
        registered.removeAll { $0.username.caseInsensitiveCompare(user.username) == .orderedSame }
        registered.append(user)
        try? KeychainStore.save(registered, for: KeychainStore.Key.registeredUsers)
    }
```

- [ ] **Step 4: Run tests to verify they pass**

Run the Step 2 command.
Expected: `** TEST SUCCEEDED **`, 3 tests pass.

- [ ] **Step 5: Commit**

```bash
git add AmazonMiniSwiftUI/AmazonMiniSwiftUI/Screens/Auth/ViewModel/AuthViewModel.swift AmazonMiniSwiftUI/AmazonMiniSwiftUITests/AuthViewModelProfileTests.swift
git commit -m "Add AuthViewModel.updateProfile"
```

---

### Task 4: Add `AuthViewModel.deleteAccount` (TDD)

**Files:**
- Modify: `AmazonMiniSwiftUI/AmazonMiniSwiftUI/Screens/Auth/ViewModel/AuthViewModel.swift` (add method)
- Test: `AmazonMiniSwiftUI/AmazonMiniSwiftUITests/AuthViewModelProfileTests.swift` (append cases)

**Interfaces:**
- Consumes: `AuthService.deleteUser(id:)` (Task 2) via the injected `service`; `KeychainStore`.
- Produces: `AuthViewModel.deleteAccount() async` — best-effort `service.deleteUser(id:)` (errors swallowed, since local accounts may 404), then prunes the `auth.registeredUsers` entry, deletes `auth.currentUser`, sets `currentUser = nil`, and ends with `isLoading = false`.

- [ ] **Step 1: Write the failing tests**

Append to `AmazonMiniSwiftUITests/AuthViewModelProfileTests.swift` (inside the class):

```swift
    @MainActor
    func testDeleteAccount_clearsSession() async throws {
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data("{}".utf8))
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let vm = AuthViewModel(service: AuthService(session: URLSession(configuration: config)))

        let local = makeUser(username: "deleteme")
        try KeychainStore.save([local], for: KeychainStore.Key.registeredUsers)
        vm.currentUser = local

        await vm.deleteAccount()

        XCTAssertNil(vm.currentUser)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(try KeychainStore.load(User.self, for: KeychainStore.Key.currentUser))
        XCTAssertEqual((try KeychainStore.load([User].self, for: KeychainStore.Key.registeredUsers))?.count ?? 0, 0)
    }

    @MainActor
    func testDeleteAccount_clearsLocalEvenWhenServer404() async throws {
        MockURLProtocol.handler = { request in
            let body = Data(#"{"message":"User not found"}"#.utf8)
            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return (response, body)
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let vm = AuthViewModel(service: AuthService(session: URLSession(configuration: config)))

        let local = makeUser(username: "deleteme")
        try KeychainStore.save([local], for: KeychainStore.Key.registeredUsers)
        vm.currentUser = local

        await vm.deleteAccount()

        XCTAssertNil(vm.currentUser)
        XCTAssertNil(try KeychainStore.load(User.self, for: KeychainStore.Key.currentUser))
        XCTAssertEqual((try KeychainStore.load([User].self, for: KeychainStore.Key.registeredUsers))?.count ?? 0, 0)
    }
```

- [ ] **Step 2: Run tests to verify they fail**

Run:
```bash
xcodebuild test -scheme AmazonMiniSwiftUI -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AmazonMiniSwiftUITests/AuthViewModelProfileTests 2>&1 | tail -30
```
Expected: compile error — `deleteAccount` does not exist.

- [ ] **Step 3: Write minimal implementation**

Add inside `final class AuthViewModel` (e.g. just after the `// MARK: Logout` block, before the local-credential-store section), in `Screens/Auth/ViewModel/AuthViewModel.swift`:

```swift
    // MARK: Delete account

    // Permanently removes the current user: best-effort DELETE on the server (errors
    // are swallowed, since locally-registered accounts were never persisted server-side
    // and may 404), then prunes the local registeredUsers entry and clears the session.
    func deleteAccount() async {
        guard let user = currentUser else { return }
        isLoading = true
        _ = try? await service.deleteUser(id: user.id)
        removeRegisteredUser(username: user.username)
        KeychainStore.delete(for: KeychainStore.Key.currentUser)
        currentUser = nil
        isLoading = false
    }

    private func removeRegisteredUser(username: String) {
        var registered = (try? KeychainStore.load([User].self, for: KeychainStore.Key.registeredUsers)) ?? []
        registered.removeAll { $0.username.caseInsensitiveCompare(username) == .orderedSame }
        if registered.isEmpty {
            KeychainStore.delete(for: KeychainStore.Key.registeredUsers)
        } else {
            try? KeychainStore.save(registered, for: KeychainStore.Key.registeredUsers)
        }
    }
```

- [ ] **Step 4: Run tests to verify they pass**

Run the Step 2 command.
Expected: `** TEST SUCCEEDED **`, all 5 cases pass.

- [ ] **Step 5: Commit**

```bash
git add AmazonMiniSwiftUI/AmazonMiniSwiftUI/Screens/Auth/ViewModel/AuthViewModel.swift AmazonMiniSwiftUI/AmazonMiniSwiftUITests/AuthViewModelProfileTests.swift
git commit -m "Add AuthViewModel.deleteAccount"
```

---

### Task 5: Create `AboutView` (build + smoke)

**Files:**
- Create: `AmazonMiniSwiftUI/AmazonMiniSwiftUI/Screens/Settings/View/AboutView.swift`

**Interfaces:**
- Produces: `AboutView()` — a self-contained `View` reading version/build from `Bundle.main`. No external dependencies.

- [ ] **Step 1: Implement the view**

Create `AmazonMiniSwiftUI/AmazonMiniSwiftUI/Screens/Settings/View/AboutView.swift`:

```swift
//
//  AboutView.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 27/07/26.
//

import SwiftUI

// MARK: - AboutView

// Static "About app" screen: branded logo, app name, version + build, a one-line
// description and a small tech note. Pushed from SettingsView; no own NavigationStack.
struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.brandOrange)
                        .frame(width: 88, height: 88)
                        .shadow(color: Color.brandOrange.opacity(0.35), radius: 8, y: 4)
                    Image(systemName: "bag.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.top, 12)

                Text("Amazon Mini")
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color.brandNavy)

                Text("Version \(appVersion) (\(appBuild))")
                    .font(.subheadline)
                    .foregroundStyle(Color.brandSecondary)

                Text("A minimal SwiftUI shopping demo: authentication, product browsing, cart, checkout, profile and settings.")
                    .font(.body)
                    .foregroundStyle(Color.brandText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                VStack(spacing: 6) {
                    Text("Built with")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.brandNavy)
                    Text("SwiftUI · iOS 18+ · Swift 6\nDemo API: dummyjson.com")
                        .font(.footnote)
                        .foregroundStyle(Color.brandSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }

    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
    }

    private var appBuild: String {
        (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "1"
    }

    #Preview {
        NavigationStack { AboutView() }
    }
}
```

- [ ] **Step 2: Build**

Run:
```bash
xcodebuild build -scheme AmazonMiniSwiftUI -destination 'platform=iOS Simulator,name=iPhone 16' -configuration Debug 2>&1 | tail -20
```
Expected: `** BUILD SUCCEEDED **`, no new warnings.

- [ ] **Step 3: Commit**

```bash
git add AmazonMiniSwiftUI/AmazonMiniSwiftUI/Screens/Settings/View/AboutView.swift
git commit -m "Add About screen"
```

---

### Task 6: Create `ProfileView` (build + smoke)

**Files:**
- Create: `AmazonMiniSwiftUI/AmazonMiniSwiftUI/Screens/Profile/View/ProfileView.swift`

**Interfaces:**
- Consumes: `@Environment(AuthViewModel.self)` (`currentUser`, `displayName`); `AuthInputField`, `PrimaryButton`, `Theme` colors; `AuthValidator.parseBirthDate`, `.formatDate`, `.isValidFullName`, `.isValidBirthDate`; `AuthViewModel.updateProfile(...)` (Task 3).
- Produces: `ProfileView()` — a `View` that hydrates editable fields from `currentUser` on appear and writes them back via `updateProfile` on Save.

- [ ] **Step 1: Implement the view**

Create `AmazonMiniSwiftUI/AmazonMiniSwiftUI/Screens/Profile/View/ProfileView.swift`:

```swift
//
//  ProfileView.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 27/07/26.
//

import SwiftUI

// MARK: - ProfileView

// View + edit the signed-in user's details: First Name, Last Name, Gender, Birthdate.
// The read-only header shows the avatar, display name, @username and email. On Save the
// editable fields are written through AuthViewModel.updateProfile (local Keychain
// persistence; DummyJSON does not persist edits server-side). No own NavigationStack.
struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var gender: Gender = .male
    @State private var birthDate: Date = .now
    @State private var didSave = false

    enum Gender: String, CaseIterable, Identifiable {
        case male = "Male"
        case female = "Female"
        var id: String { rawValue }

        static func from(stored: String?) -> Gender {
            stored?.lowercased() == "female" ? .female : .male
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header

                VStack(spacing: 16) {
                    AuthInputField(title: "First Name", text: $firstName, leadingIcon: "person")
                    AuthInputField(title: "Last Name", text: $lastName, leadingIcon: "person")

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Gender")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.brandNavy)
                        Picker("Gender", selection: $gender) {
                            ForEach(Gender.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Birthdate")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.brandNavy)
                        DatePicker("", selection: $birthDate, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.fieldBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(Color.fieldBorder, lineWidth: 1)
                            )
                    }

                    if didSave {
                        Label("Profile updated", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    PrimaryButton(title: "Save Changes", isLoading: false, isEnabled: isFormValid) {
                        save()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .onAppear(hydrate)
    }

    // MARK: Subviews

    @ViewBuilder
    private var header: some View {
        VStack(spacing: 10) {
            if let imageString = authViewModel.currentUser?.image,
               let url = URL(string: imageString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty: ProgressView()
                    case .success(let image): image.resizable().scaledToFill()
                    default: placeholderAvatar
                    }
                }
                .frame(width: 96, height: 96)
                .clipShape(Circle())
            } else {
                placeholderAvatar
            }

            Text(authViewModel.displayName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.brandNavy)

            if let username = authViewModel.currentUser?.username {
                Text("@\(username)")
                    .font(.subheadline)
                    .foregroundStyle(Color.brandSecondary)
            }
            if let email = authViewModel.currentUser?.email, !email.isEmpty {
                Text(email)
                    .font(.footnote)
                    .foregroundStyle(Color.brandSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var placeholderAvatar: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 96, height: 96)
            .foregroundStyle(Color.brandSecondary)
    }

    // MARK: Actions

    private var isFormValid: Bool {
        AuthValidator.isValidFullName(firstName)
            && AuthValidator.isValidFullName(lastName)
            && AuthValidator.isValidBirthDate(birthDate)
    }

    private func hydrate() {
        guard let user = authViewModel.currentUser else { return }
        firstName = user.firstName
        lastName = user.lastName
        gender = Gender.from(stored: user.gender)
        if let parsed = AuthValidator.parseBirthDate(user.birthDate) {
            birthDate = parsed
        }
    }

    private func save() {
        authViewModel.updateProfile(
            firstName: firstName,
            lastName: lastName,
            gender: gender.rawValue,
            birthDate: AuthValidator.formatDate(birthDate)
        )
        didSave = true
    }

    #Preview {
        NavigationStack {
            ProfileView()
                .environment(AuthViewModel())
        }
    }
}
```

- [ ] **Step 2: Build**

Run:
```bash
xcodebuild build -scheme AmazonMiniSwiftUI -destination 'platform=iOS Simulator,name=iPhone 16' -configuration Debug 2>&1 | tail -20
```
Expected: `** BUILD SUCCEEDED **`, no new warnings.

- [ ] **Step 3: Commit**

```bash
git add AmazonMiniSwiftUI/AmazonMiniSwiftUI/Screens/Profile/View/ProfileView.swift
git commit -m "Add Profile screen"
```

---

### Task 7: Create `SettingsView` + wire entry from home toolbar (build + smoke)

**Files:**
- Create: `AmazonMiniSwiftUI/AmazonMiniSwiftUI/Screens/Settings/View/SettingsView.swift`
- Modify: `AmazonMiniSwiftUI/AmazonMiniSwiftUI/Screens/Product/View/ProductListView.swift` (lines 50-59: replace leading `Menu`(Logout) with a `NavigationLink` → `SettingsView`)

**Interfaces:**
- Consumes: `@Environment(AuthViewModel.self)` (`logout()`, `deleteAccount()`); `ProfileView` (Task 6), `AboutView` (Task 5).
- Produces: `SettingsView()` — a `View` (List) whose rows navigate to Profile/About or trigger Logout/Delete with confirmation alerts.

- [ ] **Step 1: Implement the view**

Create `AmazonMiniSwiftUI/AmazonMiniSwiftUI/Screens/Settings/View/SettingsView.swift`:

```swift
//
//  SettingsView.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 27/07/26.
//

import SwiftUI

// MARK: - SettingsView

// Account hub pushed from the home toolbar. Lists About app, Update Profile, Logout
// and Delete User. Pushed destinations (Profile, About) must NOT add their own
// NavigationStack (CartView convention).
struct SettingsView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    @State private var showLogoutConfirm = false
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false

    var body: some View {
        List {
            Section {
                NavigationLink {
                    ProfileView()
                } label: {
                    row(icon: "person.text.rectangle", title: "Update Profile", tint: Color.brandNavy)
                }

                NavigationLink {
                    AboutView()
                } label: {
                    row(icon: "info.circle", title: "About App", tint: Color.brandNavy)
                }
            }

            Section {
                Button {
                    showLogoutConfirm = true
                } label: {
                    row(icon: "rectangle.portrait.and.arrow.right", title: "Logout", tint: Color.brandSecondary)
                }

                Button {
                    showDeleteConfirm = true
                } label: {
                    row(icon: "trash", title: "Delete User", tint: Color.errorRed)
                }
                .disabled(isDeleting)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Log out?", isPresented: $showLogoutConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Log out", role: .destructive) { authViewModel.logout() }
        } message: {
            Text("You can sign back in anytime.")
        }
        .alert("Delete account?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    isDeleting = true
                    await authViewModel.deleteAccount()
                    isDeleting = false
                }
            }
        } message: {
            Text("This permanently removes your account on this device and cannot be undone.")
        }
        .overlay {
            if isDeleting {
                ProgressView("Deleting account…")
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    @ViewBuilder
    private func row(icon: String, title: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 24)
            Text(title)
                .foregroundStyle(title == "Delete User" ? Color.errorRed : Color.brandText)
        }
    }

    #Preview {
        NavigationStack {
            SettingsView()
                .environment(AuthViewModel())
        }
    }
}
```

- [ ] **Step 2: Wire the home toolbar entry**

In `Screens/Product/View/ProductListView.swift`, find this block (the leading toolbar item, lines ~50-59):

```swift
                    ToolbarItem(placement: .navigationBarLeading) {
                        Menu {
                            Button("Logout", role: .destructive) {
                                authViewModel.logout()
                            }
                        } label: {
                            Image(systemName: "person.crop.circle")
                        }
                    }
```

Replace it with a navigation push to `SettingsView`:

```swift
                    ToolbarItem(placement: .navigationBarLeading) {
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Image(systemName: "person.crop.circle")
                        }
                    }
```

(Logout has moved into SettingsView; do not keep a duplicate Logout on the home bar.)

- [ ] **Step 3: Build**

Run:
```bash
xcodebuild build -scheme AmazonMiniSwiftUI -destination 'platform=iOS Simulator,name=iPhone 16' -configuration Debug 2>&1 | tail -20
```
Expected: `** BUILD SUCCEEDED **`, no new warnings.

- [ ] **Step 4: Manual smoke test**

Boot the app on the `iPhone 16` simulator, log in, then verify:
- Home toolbar shows the `person.crop.circle` icon on the leading side.
- Tapping it pushes `Settings`.
- `Update Profile` pushes `Profile`; the fields show the current user's First/Last name, Gender, and Birthdate.
- Edit all four fields, tap `Save Changes` → "Profile updated" appears.
- Quit & relaunch the app (session restores) → open Profile again → edits persisted.
- Back to Settings → `About App` → shows app name + `Version 1.0 (1)`.
- Back to Settings → `Logout` → confirm → returns to login screen.
- Re-login → Settings → `Delete User` → confirm → returns to login screen; the account can no longer log in.

- [ ] **Step 5: Commit**

```bash
git add AmazonMiniSwiftUI/AmazonMiniSwiftUI/Screens/Settings/View/SettingsView.swift AmazonMiniSwiftUI/AmazonMiniSwiftUI/Screens/Product/View/ProductListView.swift
git commit -m "Add Settings screen and wire home toolbar entry"
```

---

### Task 8: Final full verification

**Files:** none (verification only)

- [ ] **Step 1: Run the full test suite**

Run:
```bash
xcodebuild test -scheme AmazonMiniSwiftUI -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -30
```
Expected: `** TEST SUCCEEDED **`; `AuthValidatorTests` (4), `AuthServiceTests` (2), `AuthViewModelProfileTests` (5) all pass. No new warnings.

- [ ] **Step 2: Run a clean release-ish build**

Run:
```bash
xcodebuild build -scheme AmazonMiniSwiftUI -destination 'platform=iOS Simulator,name=iPhone 16' -configuration Debug 2>&1 | tail -20
```
Expected: `** BUILD SUCCEEDED **`, no new warnings.

- [ ] **Step 3: Confirm no stray changes**

Run:
```bash
git status --short
git log --oneline -8
```
Expected: working tree clean (or only intended files), 7 feature commits on top of the design-spec commit.

---

## Self-Review (run after writing — results)

- **Spec coverage:** Profile view+edit (Task 6), Settings hub with all 4 actions (Task 7), About (Task 5), `updateProfile` persistence incl. local-account refresh (Task 3), `deleteAccount` via `DELETE /users/{id}` + Keychain cleanup (Tasks 2+4), home toolbar entry (Task 7). All spec sections mapped to tasks. ✔
- **Placeholder scan:** no TBD/TODO; every code step contains full code. ✔
- **Type consistency:** `parseBirthDate(_:)`, `deleteUser(id:)`, `updateProfile(firstName:lastName:gender:birthDate:)`, `deleteAccount()` signatures match across tasks/tests/views. ✔
- **Known limitation (documented in spec §11):** profile edits do not round-trip to DummyJSON (local Keychain only) — acceptable for this demo.
