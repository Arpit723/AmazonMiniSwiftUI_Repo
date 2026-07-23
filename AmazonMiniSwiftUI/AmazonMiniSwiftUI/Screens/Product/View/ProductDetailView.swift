import SwiftUI


struct ProductDetailView: View {
    @StateObject private var viewModel = ProductDetailViewModel()
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
        }
        .padding()
    }
}

#Preview {
    ProductDetailView(productId: 0)
}
