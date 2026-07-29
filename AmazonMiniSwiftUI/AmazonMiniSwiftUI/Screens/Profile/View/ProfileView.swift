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
        .onAppear(perform: hydrate)
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
}

#Preview {
    NavigationStack {
        ProfileView()
            .environment(AuthViewModel())
    }
}
