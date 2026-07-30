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
                    ProfileView().chevronOnlyBackButton()
                } label: {
                    row(icon: "person.text.rectangle", title: "Update Profile", tint: Color.brandNavy)
                }

                NavigationLink {
                    AboutView().chevronOnlyBackButton()
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
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(AuthViewModel())
    }
}
