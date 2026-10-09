import SwiftUI

struct ProductListView: View {
    @StateObject private var viewModel = ProductListViewModel()
    @Environment(CartViewModel.self) private var cartViewModel
    @Environment(AuthViewModel.self) private var authViewModel


    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryChips

                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = viewModel.error {
                        Text("Error: \(error)")
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        listOfProdcutsView
                    }
                }
            }
            .navigationDestination(for: Int.self) { productId in
                ProductDetailView(productId: productId).chevronOnlyBackButton()
            }
            .searchable(text: $viewModel.searchText)
            .onChange(of: viewModel.searchText) {
                viewModel.searchTextChanged()
            }
            .navigationTitle("Products")
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
            .task {
                async let products: Void = viewModel.loadProducts()
                async let categories: Void = viewModel.loadCategories()
                _ = await (products, categories)
            }
        }
    }
    
    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                CategoryChip(
                    label: "All",
                    isSelected: viewModel.selectedCategory == nil
                ) {
                    viewModel.selectCategory(nil)
                }

                ForEach(viewModel.categories) { category in
                    CategoryChip(
                        label: category.name,
                        isSelected: viewModel.selectedCategory == category.slug
                    ) {
                        viewModel.selectCategory(category.slug)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
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

private struct CategoryChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppFont.footnote.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : Color.brandNavy)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.brandOrange : Color.fieldBackground)
                        .overlay(Capsule().stroke(Color.fieldBorder, lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Category \(label)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    ProductListView()
        .environment(CartViewModel())
        .environment(AuthViewModel())
}
