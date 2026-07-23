import SwiftUI
import Combine

struct ProductListView: View {
    @StateObject private var viewModel = ProductListViewModel()
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if let error = viewModel.error {
                    Text("Error: \(error)").foregroundStyle(.red)
                } else {
                    listOfProdcutsView
                        .navigationDestination(for: Int.self) { productId in
                            ProductDetailView(productId: productId)
                        }
                }
            }.searchable(text: $viewModel.searchText)
                .onChange(of: viewModel.searchText) {
                    viewModel.searchTextChanged()
                }
                .navigationTitle("Products")
                .task {
                    await viewModel.loadProducts()
                }
        }
    }
    
    private var listOfProdcutsView: some View {
        List {
            ForEach(viewModel.products) { product in
                NavigationLink(value: product.id) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.title).font(.headline)
                        Text("$\(product.price, specifier: "%.2f")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .task {
                    if viewModel.products.last?.id == product.id && viewModel.canLoadMorePages {
                        await viewModel.loadNextPage()
                    }
                }
            }

            if viewModel.isLoadingNextPage {
                ProgressView().frame(maxWidth: .infinity)
            }
        }.refreshable {
            await viewModel.refresh()
        }

        
    }
}

#Preview {
    ProductListView()
}
