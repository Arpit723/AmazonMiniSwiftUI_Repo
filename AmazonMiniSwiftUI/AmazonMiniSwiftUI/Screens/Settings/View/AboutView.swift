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
}

#Preview {
    NavigationStack { AboutView() }
}
