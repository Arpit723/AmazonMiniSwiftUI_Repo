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
                            ProductDetailView(productId: productId)
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
                            Image(systemName: "cart").tint(.black)
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
                        Menu {
                            Button("Logout", role: .destructive) {
                                authViewModel.logout()
                            }
                        } label: {
                            Image(systemName: "person.crop.circle")
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink { CartView() } label: { /* your existing cart icon */
                        
                            Image(systemName: "cart").tint(.black)
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
                            OrderHistoryView()
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
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
        .environment(CartViewModel())
        .environment(AuthViewModel())
}
