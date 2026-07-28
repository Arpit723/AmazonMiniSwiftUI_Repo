import SwiftUI


struct ProductDetailView: View {
    @StateObject private var viewModel = ProductDetailViewModel()
    @Environment(CartViewModel.self) private var cartViewModel
    @State private var showAddedConfirmation = false
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
        .overlay(alignment: .top) {
            if showAddedConfirmation {
                Text("Added to Cart")
                    .font(AppFont.footnote.weight(.semibold))
                    .foregroundStyle(Color.brandNavy)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
                    .shadow(radius: 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, AppSpacing.sm)
            }
        }
        .animation(.easeInOut, value: showAddedConfirmation)
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

            PriceText(amount: viewModel.productDetail?.price ?? 0, font: AppFont.headline, color: Color.brandNavy)

            Text(viewModel.productDetail?.description ?? "")
                .font(AppFont.body)
                .foregroundStyle(Color.brandText)

            PrimaryButton(title: "Add to Cart") {
                if let product = viewModel.productDetail {
                    cartViewModel.addItem(product: product)
                    showConfirmation()
                }
            }
        }
        .padding()
    }

    // Brief, self-dismissing "Added to Cart" banner — no new dependencies.
    private func showConfirmation() {
        withAnimation { showAddedConfirmation = true }
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation { showAddedConfirmation = false }
        }
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(productId: 0)
            .environment(CartViewModel())
    }
}
