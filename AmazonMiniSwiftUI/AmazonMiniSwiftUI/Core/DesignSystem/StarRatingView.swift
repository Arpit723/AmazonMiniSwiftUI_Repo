//
//  StarRatingView.swift
//  AmazonMiniSwiftUI
//
//  Read-only star rating display reused across features (product detail summary, review
//  rows, and later product list rows). Renders `maxRating` stars filled proportionally to
//  `rating`, with half-star support. Keep it presentational — no state, no actions.
//
//      StarRatingView(rating: 4.6)
//      StarRatingView(rating: Double(review.rating), size: 12)
//
//  Created by Arpit Parekh on 10/08/26.
//

import SwiftUI

struct StarRatingView: View {
    let rating: Double
    var maxRating: Int = 5
    var size: CGFloat = 14

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: symbolName(for: index))
                    .font(.system(size: size))
                    .foregroundStyle(Color.brandOrange)
            }
        }
    }

    private func symbolName(for index: Int) -> String {
        let filled = Double(index) <= rating
        let half = !filled && Double(index) - rating < 1
        if filled { return "star.fill" }
        if half { return "star.leadinghalf.filled" }
        return "star"
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        StarRatingView(rating: 4.6)
        StarRatingView(rating: 2.5)
        StarRatingView(rating: 0)
    }
    .padding()
}
