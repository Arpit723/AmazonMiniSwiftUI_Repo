import SwiftUI


struct ProductDetailView: View {
    @StateObject private var viewModel = ProductDetailViewModel()
    @Environment(CartViewModel.self) private var cartViewModel
    let productId: Int

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

            Text(viewModel.productDetail?.description ?? "")
                .font(AppFont.body)
                .foregroundStyle(Color.brandText)

            addToCartSection
        }
        .padding()
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
                PrimaryButton(title: "Add to Cart") {
                    if let product = viewModel.productDetail {
                        cartViewModel.addItem(product: product)
                    }
                }
            }
        }
        .animation(.easeInOut, value: qty)
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(productId: 0)
            .environment(CartViewModel())
    }
}
