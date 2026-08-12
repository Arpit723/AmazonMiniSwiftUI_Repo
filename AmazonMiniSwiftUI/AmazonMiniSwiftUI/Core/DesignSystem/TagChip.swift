//
//  TagChip.swift
//  AmazonMiniSwiftUI
//
//  A small pill-shaped label for a single keyword — used for product tags today,
//  generic enough to reuse for categories or filters later.
//
//      TagChip(text: "beauty")
//
//  Created by Arpit Parekh on 12/08/26.
//

import SwiftUI

struct TagChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppFont.caption)
            .foregroundStyle(Color.brandNavy)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(
                Capsule()
                    .fill(Color.surface)
                    .overlay(Capsule().stroke(Color.gray, lineWidth: 1.5))
            )
    }
}

#Preview {
    HStack {
        TagChip(text: "mascara")
        TagChip(text: "beauty")
        TagChip(text: "cosmetics")
    }
    .padding()
}
