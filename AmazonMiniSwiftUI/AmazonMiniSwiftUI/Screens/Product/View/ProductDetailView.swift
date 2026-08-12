import SwiftUI


struct ProductDetailView: View {
    @StateObject private var viewModel: ProductDetailViewModel
    @Environment(CartViewModel.self) private var cartViewModel
    let productId: Int

    init(productId: Int, viewModel: ProductDetailViewModel = ProductDetailViewModel()) {
        self.productId = productId
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.error {
                Text("Error: \(error)").foregroundStyle(Color.errorRed)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        imageGallery
                        infoSection
                    }
                }
            }
        }
        .navigationTitle(viewModel.productDetail?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard viewModel.productDetail == nil else { return }
            await viewModel.loadProductDetail(productId: productId)
        }
    }

    private var imageGallery: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.productDetail?.images ?? [], id: \.self) { imageUrlString in
                    RemoteImage(urlString: imageUrlString)
                        .frame(width: 240, height: 240)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                }
            }
            .padding(.horizontal)
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(viewModel.productDetail?.title ?? "")
                .font(AppFont.title)
                .foregroundStyle(Color.brandNavy)

            Text((viewModel.productDetail?.category ?? "").capitalized)
                .font(AppFont.subheadline)
                .foregroundStyle(Color.brandSecondary)

            DiscountPriceView(price: viewModel.productDetail?.price ?? 0, discountPercentage: viewModel.productDetail?.discountPercentage ?? 0, font: AppFont.headline, color: Color.brandNavy)

            brandTagsSection

            if let detail = viewModel.productDetail {
                HStack(spacing: AppSpacing.xs) {
                    StarRatingView(rating: detail.rating, size: 13)
                    Text(String(format: "%.1f", detail.rating))
                        .font(AppFont.footnote)
                        .foregroundStyle(Color.brandSecondary)
                    Text("(\(detail.reviews.count) review\(detail.reviews.count == 1 ? "" : "s"))")
                        .font(AppFont.footnote)
                        .foregroundStyle(Color.brandSecondary)
                }
            }

//            PriceText(amount: viewModel.productDetail?.price ?? 0, font: AppFont.headline, color: Color.brandNavy)

            stockBadge

            Text(viewModel.productDetail?.description ?? "")
                .font(AppFont.body)
                .foregroundStyle(Color.brandText)

            addToCartSection

            reviewsSection
        }
        .padding()
    }

    private var brandTagsSection: some View {
        let detail = viewModel.productDetail
        return VStack(alignment: .leading, spacing: AppSpacing.xs) {
            if let brand = detail?.brand, !brand.isEmpty {
                HStack(spacing: AppSpacing.xs) {
                    Text("Brand:")
                        .font(AppFont.footnote)
                        .foregroundStyle(Color.brandSecondary)
                    Text(brand)
                        .font(AppFont.footnote)
                        .foregroundStyle(Color.brandNavy)
                }
            }

            if let tags = detail?.tags, !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.xs) {
                        ForEach(tags, id: \.self) { tag in
                            TagChip(text: tag)
                        }
                    }
                }
            }
        }
    }

    private var stockBadge: some View {
        let stock = viewModel.productDetail?.stock ?? 0
        return Group {
            if stock == 0 {
                Text("Out of Stock")
                    .font(AppFont.footnote)
                    .foregroundStyle(Color.errorRed)
            } else if stock <= 5 {
                Text("Only \(stock) left")
                    .font(AppFont.footnote)
                    .foregroundStyle(Color.brandOrange)
            }
        }
    }

    // Stateful add/stepper control. "Add to Cart" while the product isn't in the cart;
    // a − [qty] + stepper once it is. Decrementing at quantity 1 removes the item and
    // reverts to the button. Reads cart state live via @Observable, so it reflects
    // changes made anywhere in the app.
    private var addToCartSection: some View {
        let qty = viewModel.productDetail.map { cartViewModel.quantity(for: $0.id) } ?? 0
        return Group {
            if qty > 0, let product = viewModel.productDetail {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        QuantityStepper(
                            quantity: qty,
                            onIncrement: { cartViewModel.updateQuantity(id: product.id, quantity: qty + 1) },
                            onDecrement: {
                                if qty <= 1 {
                                    cartViewModel.removeItem(id: product.id)
                                } else {
                                    cartViewModel.updateQuantity(id: product.id, quantity: qty - 1)
                                }
                            }
                        )
                        Spacer()
                        DiscountPriceView(price: product.price * Double(qty), discountPercentage: product.discountPercentage, font: AppFont.headline, color: Color.brandNavy)
                    }

                    if qty > 1 {
                        Text("Subtotal for \(qty) items")
                            .font(AppFont.footnote)
                            .foregroundStyle(Color.brandSecondary)
                    }
                }
                .transition(.opacity)
            } else {
                let stock = viewModel.productDetail?.stock ?? 0
                PrimaryButton(
                    title: stock > 0 ? "Add to Cart" : "Out of Stock",
                    isEnabled: stock > 0
                ) {
                    if let product = viewModel.productDetail {
                        cartViewModel.addItem(product: product)
                    }
                }
            }
        }
        .animation(.easeInOut, value: qty)
    }

    private var reviewsSection: some View {
        let reviews = viewModel.productDetail?.reviews ?? []
        return Group {
            if !reviews.isEmpty {
                DisclosureGroup("Reviews (\(reviews.count))") {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        ForEach(reviews, id: \.reviewerEmail) { review in
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                HStack {
                                    Text(review.reviewerName)
                                        .font(AppFont.subheadline)
                                        .foregroundStyle(Color.brandNavy).bold().fontWeight(.bold)
                                    Spacer()
                                    StarRatingView(rating: Double(review.rating), size: 12)
                                }
                                Text(review.comment)
                                    .font(AppFont.body)
                                    .foregroundStyle(Color.brandText)
                                if let date = review.parsedDate {
                                    Text(date.formatted(date: .abbreviated, time: .omitted))
                                        .font(AppFont.caption)
                                        .foregroundStyle(Color.brandSecondary)
                                }
                            }
                            if review.reviewerEmail != reviews.last?.reviewerEmail {
                                Divider().overlay(Color.black).frame(height: 1.0)
                            }
                        }
                    }
                    .padding(.top, AppSpacing.sm)
                }
                .font(AppFont.headline)
                .foregroundStyle(Color.brandNavy)
                .tint(Color.brandOrange)
            }
        }
    }
}

#Preview {
    let viewModel = ProductDetailViewModel()
    viewModel.productDetail = .mock

    return NavigationStack {
        ProductDetailView(productId: ProductDetail.mock.id, viewModel: viewModel)
            .environment(CartViewModel())
    }
}
