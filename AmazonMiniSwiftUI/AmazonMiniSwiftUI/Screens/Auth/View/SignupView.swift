//
//  SignupView.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 26/07/26.
//

import SwiftUI

// Branded registration form. Validates inline (on first submit) and, on success, the
// AuthViewModel auto-logs the new user in (RootView flips to the main app).
struct SignupView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    @State private var fullName = ""
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var gender = "Male"
    @State private var birthDate = Self.twentyYearsAgo
    @State private var attemptedSubmit = false

    private let genderOptions = ["Male", "Female"]
    var onSwitchToLogin: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                AuthHeaderView(subtitle: "Create your free account")

                VStack(spacing: 16) {
                    AuthInputField(
                        title: "Full Name",
                        text: $fullName,
                        textContentType: .name,
                        autocapitalization: .words,
                        leadingIcon: "person",
                        errorMessage: attemptedSubmit && !AuthValidator.isValidFullName(fullName)
                            ? "Full name is required." : nil
                    )

                    AuthInputField(
                        title: "Username",
                        text: $username,
                        textContentType: .username,
                        autocapitalization: .never,
                        autocorrection: false,
                        leadingIcon: "at",
                        errorMessage: attemptedSubmit && !AuthValidator.isValidUsername(username)
                            ? "Username must be at least 3 characters." : nil
                    )

                    AuthInputField(
                        title: "Email",
                        text: $email,
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress,
                        autocapitalization: .never,
                        autocorrection: false,
                        leadingIcon: "envelope",
                        errorMessage: attemptedSubmit && !AuthValidator.isValidEmail(email)
                            ? "Enter a valid email address." : nil
                    )

                    AuthInputField(
                        title: "Password",
                        text: $password,
                        isSecure: true,
                        textContentType: .newPassword,
                        autocapitalization: .never,
                        autocorrection: false,
                        leadingIcon: "lock",
                        errorMessage: attemptedSubmit && !AuthValidator.isValidPassword(password)
                            ? "Min 8 chars, with 1 uppercase, 1 lowercase, and 1 number." : nil
                    )

                    AuthInputField(
                        title: "Confirm Password",
                        text: $confirmPassword,
                        isSecure: true,
                        textContentType: .newPassword,
                        autocapitalization: .never,
                        autocorrection: false,
                        leadingIcon: "lock",
                        errorMessage: attemptedSubmit && confirmPassword != password
                            ? "Passwords do not match." : nil
                    )

                    genderRow
                    birthDateRow

                    if let error = authViewModel.error {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(Color.errorRed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    PrimaryButton(
                        title: authViewModel.isLoading ? "Creating…" : "Sign Up",
                        isLoading: authViewModel.isLoading,
                        isEnabled: true
                    ) {
                        submit()
                    }
                }

                HStack {
                    Text("Already have an account?")
                        .font(.subheadline)
                        .foregroundStyle(Color.brandSecondary)
                    Spacer()
                    Button("Log in") { onSwitchToLogin() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.brandNavy)
                }
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.white)
    }

    // MARK: - Styled controls

    private var genderRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Gender")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.brandNavy)
            Picker("Gender", selection: $gender) {
                ForEach(genderOptions, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.segmented)
        }
    }

    private var birthDateRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Birth Date")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.brandNavy)
            DatePicker("", selection: $birthDate, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Submit

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

    private var isFormValid: Bool {
        AuthValidator.isValidUsername(username) &&
        AuthValidator.isValidEmail(email) &&
        AuthValidator.isValidFullName(fullName) &&
        AuthValidator.isValidPassword(password) &&
        confirmPassword == password &&
        AuthValidator.isValidBirthDate(birthDate)
    }

    private static var twentyYearsAgo: Date {
        Calendar.current.date(byAdding: .year, value: -20, to: Date()) ?? Date()
    }
}

#Preview {
    SignupView(onSwitchToLogin: {})
        .environment(AuthViewModel())
}
