//
//  AuthHeaderView.swift
//  AmazonMiniSwiftUI
//
//  Branded logo block reused at the top of Login and Signup: an orange rounded square
//  holding a bag icon, plus the "Amazon Mini" wordmark and a one-line subtitle.
//
//  Created by Arpit Parekh on 27/07/26.
//

import SwiftUI

struct AuthHeaderView: View {
    var subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.brandOrange)
                    .frame(width: 72, height: 72)
                    .shadow(color: Color.brandOrange.opacity(0.35), radius: 8, y: 4)
                Image(systemName: "bag.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 4) {
                Text("Amazon Mini")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.brandNavy)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.brandSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)
    }
}
