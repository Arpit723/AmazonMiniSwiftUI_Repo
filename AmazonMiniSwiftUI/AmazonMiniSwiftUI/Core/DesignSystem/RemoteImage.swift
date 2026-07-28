//
//  RemoteImage.swift
//  AmazonMiniSwiftUI
//
//  A branded remote image that replaces the repeated bare `AsyncImage` pattern across
//  the app. It shows a consistent placeholder (rounded gray surface + photo glyph)
//  while loading and on failure. The caller decides the size and clipping:
//
//      RemoteImage(urlString: product.thumbnail)
//          .frame(width: 56, height: 56)
//          .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
//
//  Created by Arpit Parekh on 27/07/26.
//

import SwiftUI

struct RemoteImage: View {
    var urlString: String?
    var contentMode: ContentMode = .fit

    var body: some View {
        AsyncImage(url: urlString.flatMap(URL.init)) { phase in
            switch phase {
            case .empty:
                placeholder()
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            case .failure:
                placeholder(icon: "exclamationmark.triangle")
            @unknown default:
                placeholder()
            }
        }
    }

    private func placeholder(icon: String = "photo") -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                .fill(Color.fieldBackground)
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.brandSecondary)
        }
    }
}
