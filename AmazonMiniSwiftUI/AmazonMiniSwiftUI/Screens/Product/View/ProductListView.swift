import SwiftUI

struct ProductListView: View {
    @StateObject private var viewModel = ProductListViewModel()
    @Environment(CartViewModel.self) private var cartViewModel
    @Environment(AuthViewModel.self) private var authViewModel


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
                            ProductDetailView(productId: productId).chevronOnlyBackButton()
                        }
                }
            }.searchable(text: $viewModel.searchText)
                .onChange(of: viewModel.searchText) {
                    viewModel.searchTextChanged()
                }
                .navigationTitle("Products")
            /*
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showCart = true
                        } label: {
                            Image(systemName: "cart").foregroundStyle(Color.brandNavy)
                                .overlay(alignment: .topTrailing) {
                                    if cartViewModel.itemCount > 0 {
                                        Text("\(cartViewModel.itemCount)")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                            .padding(5)
                                            .background(Color.red, in: Circle())
                                            .offset(x: 7, y: -7)
                                    }
                                }
                        }
                        .accessibilityLabel("Cart, \(cartViewModel.itemCount) items")
                    }
                }
             */
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        NavigationLink {
                            SettingsView().chevronOnlyBackButton()
                        } label: {
                            Image(systemName: "person.crop.circle").foregroundStyle(Color.brandNavy)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink { CartView().chevronOnlyBackButton() } label: { /* your existing cart icon */
                        
                            Image(systemName: "cart").foregroundStyle(Color.brandNavy)
                                .overlay(alignment: .topTrailing) {
                                    if cartViewModel.itemCount > 0 {
                                        Text("\(cartViewModel.itemCount)")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                            .padding(5)
                                            .background(Color.red, in: Circle())
                                            .offset(x: 7, y: -7)
                                    }
                                }
                            
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink {
                            OrderHistoryView().chevronOnlyBackButton()
                        } label: {
                            Image(systemName: "clock.arrow.circlepath").foregroundStyle(Color.brandNavy)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Picker("Sort by", selection: Binding(
                                get: { viewModel.sortOption },
                                set: { viewModel.selectSort($0) }
                            )) {
                                ForEach(SortOption.allCases) { option in
                                    Text(option.label).tag(option)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down.circle")
                                .foregroundStyle(Color.brandNavy)
                        }
                    }
                }
            
            
//                .navigationDestination(isPresented: $showCart) {
//                    CartView()
//                }
                .task {
                    await viewModel.loadProducts()
                }
        }
    }
    
    private var listOfProdcutsView: some View {
        
        
        List {
            ForEach(viewModel.products) { product in
                NavigationLink(value: product.id) {
                    HStack(spacing: AppSpacing.md) {
                        RemoteImage(urlString: product.thumbnail)
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.title)
                                .font(AppFont.headline)
                                .foregroundStyle(Color.brandNavy)
                                .lineLimit(2)
                            DiscountPriceView(price: product.price, discountPercentage: product.discountPercentage, font: AppFont.subheadline, color: Color.brandSecondary)
                        }
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
            await viewModel.pullToRefresh()
        }

        
    }
}

#Preview {
    ProductListView()
        .environment(CartViewModel())
        .environment(AuthViewModel())
}
