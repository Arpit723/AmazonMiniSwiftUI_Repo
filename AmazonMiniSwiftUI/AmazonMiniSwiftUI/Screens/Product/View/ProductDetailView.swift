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
                Text("Error: \(error)").foregroundStyle(.red)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 5) {
                        imageGallery
                        infoSection
                    }
                }
            }

        }.navigationTitle(viewModel.productDetail?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadProductDetail(productId: productId)
        }
        .overlay(alignment: .top) {
            if showAddedConfirmation {
                Text("Added to Cart")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
                    .shadow(radius: 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
        .animation(.easeInOut, value: showAddedConfirmation)
    }
    
    
    private var imageGallery : some View {
        ScrollView(.horizontal, showsIndicators:false ) {
            HStack(alignment: .center, spacing: 5) {
                ForEach(viewModel.productDetail?.images ?? [], id: \.self) { imageUrlString in
                    AsyncImage(url: URL(string: imageUrlString)) { image in image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }.frame(width: 200, height: 200)
                }
            }
        }
    }
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.productDetail?.title ?? "").font(.title).bold()
            Text(viewModel.productDetail?.category ?? "").foregroundStyle(.secondary)
            Text("$\(viewModel.productDetail?.price ?? 0.0, specifier: "%.2f")").font(.headline)
            Text(viewModel.productDetail?.description ?? "")

            Button {
                if let product = viewModel.productDetail {
                    cartViewModel.addItem(product: product)
                    showConfirmation()
                }
            } label: {
                Text("Add to Cart")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
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
