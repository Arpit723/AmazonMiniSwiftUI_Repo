//
//  SignupView.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 26/07/26.
//

import SwiftUI

// Registration form. Validates inline (on first submit) and, on success, the
// AuthViewModel auto-logs the new user in (RootView flips to the main app).
struct SignupView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    @State private var fullName = ""
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var gender = "Male"
    @State private var birthDate = twentyYearsAgo
    @State private var attemptedSubmit = false

    private let genderOptions = ["Male", "Female"]
    var onSwitchToLogin: () -> Void

    var body: some View {
        Form {
            Section("Account") {
                TextField("Username (min 3 chars)", text: $username)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                fieldError(
                    "Username must be at least 3 characters.",
                    show: attemptedSubmit && !AuthValidator.isValidUsername(username)
                )

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                fieldError(
                    "Enter a valid email address.",
                    show: attemptedSubmit && !AuthValidator.isValidEmail(email)
                )
            }

            Section("Profile") {
                TextField("Full Name", text: $fullName)
                fieldError(
                    "Full name is required.",
                    show: attemptedSubmit && !AuthValidator.isValidFullName(fullName)
                )

                Picker("Gender", selection: $gender) {
                    ForEach(genderOptions, id: \.self) { Text($0).tag($0) }
                }

                DatePicker("Birth Date", selection: $birthDate, in: ...Date(), displayedComponents: .date)
            }

            Section("Security") {
                SecureField("Password", text: $password)
                fieldError(
                    "Min 8 chars, with 1 uppercase, 1 lowercase, and 1 number.",
                    show: attemptedSubmit && !AuthValidator.isValidPassword(password)
                )

                SecureField("Confirm Password", text: $confirmPassword)
                fieldError(
                    "Passwords do not match.",
                    show: attemptedSubmit && confirmPassword != password
                )
            }

            if let error = authViewModel.error {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }

            Section {
                Button {
                    submit()
                } label: {
                    HStack {
                        Spacer()
                        Text(authViewModel.isLoading ? "Creating…" : "Sign Up").bold()
                        Spacer()
                    }
                }
                .disabled(authViewModel.isLoading)
            }

            Section {
                HStack {
                    Text("Already have an account?")
                    Spacer()
                    Button("Log in") { onSwitchToLogin() }
                        .font(.footnote)
                }
            }
        }
    }

    // MARK: - Private

    private func fieldError(_ text: String, show: Bool) -> some View {
        Group {
            if show {
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var isFormValid: Bool {
        AuthValidator.isValidUsername(username) &&
        AuthValidator.isValidEmail(email) &&
        AuthValidator.isValidFullName(fullName) &&
        AuthValidator.isValidPassword(password) &&
        confirmPassword == password &&
        AuthValidator.isValidBirthDate(birthDate)
    }

    private func submit() {
        attemptedSubmit = true
        guard isFormValid else { return }
        Task {
            await authViewModel.signup(
                fullName: fullName,
                username: username,
                email: email,
                password: password,
                confirmPassword: confirmPassword,
                gender: gender,
                birthDate: birthDate
            )
        }
    }

    private static var twentyYearsAgo: Date {
        Calendar.current.date(byAdding: .year, value: -20, to: Date()) ?? Date()
    }
}

#Preview {
    SignupView(onSwitchToLogin: {})
        .environment(AuthViewModel())
}
