import Foundation

@MainActor
final class ProductListViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var error: String?
    @Published var isLoading = false
    @Published var isLoadingNextPage = false
    @Published var searchText: String = ""
    @Published var canLoadMorePages = true
    @Published var sortOption: SortOption = .relevance
    @Published var categories: [ProductCategory] = []
    @Published var selectedCategory: String? = nil
    private var skipCount: Int = 0
    private var limit: Int = 25

    private let service: ProductService

    private func isCancelled(_ error: Error) -> Bool {
        error is CancellationError || (error as? URLError)?.code == .cancelled
    }

    private var searchTask: Task<Void, Never>?
    private var sortTask: Task<Void, Never>?
    private var categoryTask: Task<Void, Never>?

   
    init(service: ProductService = ProductService()) {
        self.service = service
        Task {
            await self.loadProducts()
        }
    }

    
    func loadProducts() async {
        isLoading = true
        error = nil
        isLoadingNextPage = false
        canLoadMorePages = true
        skipCount = 0
        if searchText.isEmpty {
            do {
                let fetched: [Product]
                if let selectedCategory {
                    fetched = try await service.fetchProducts(
                        category: selectedCategory,
                        limit: self.limit,
                        skip: self.skipCount,
                        sortBy: sortOption.sortBy,
                        order: sortOption.order
                    )
                } else {
                    fetched = try await service.fetchProducts(
                        limit: self.limit,
                        skip: self.skipCount,
                        sortBy: sortOption.sortBy,
                        order: sortOption.order
                    )
                }
                self.products = fetched
                self.isLoading = false
            } catch {
                if isCancelled(error) { return }
                self.error = error.localizedDescription
                self.isLoading = false
            }
        } else {
            await self.performSearch(query: searchText)
        }
    }

    func loadCategories() async {
        do {
            categories = try await service.fetchCategories()
        } catch {
            // Category chips degrade silently; the product list stays usable.
        }
    }

    func selectCategory(_ category: String?) {
        guard selectedCategory != category || !searchText.isEmpty else { return }
        selectedCategory = category
        searchText = ""
        searchTask?.cancel()
        categoryTask?.cancel()
        categoryTask = Task {
            await loadProducts()
        }
    }

    func selectSort(_ option: SortOption) {
        guard sortOption != option else { return }
        sortOption = option
        sortTask?.cancel()
        sortTask = Task {
            await loadProducts()
        }
    }
    
    
    // MARK: - Pull to refresh
    func pullToRefresh() async {
        //            let fetched =
        self.skipCount = 0
        self.error = nil

        do {
            let fetched: [Product]
            if !searchText.isEmpty {
                fetched = try await service.searchProducts(searchText: searchText)
            } else if let selectedCategory {
                fetched = try await service.fetchProducts(
                    category: selectedCategory,
                    limit: limit,
                    skip: 0,
                    sortBy: sortOption.sortBy,
                    order: sortOption.order
                )
            } else {
                fetched = try await service.fetchProducts(
                    limit: limit,
                    skip: 0,
                    sortBy: sortOption.sortBy,
                    order: sortOption.order
                )
            }
            products = fetched
            error = nil

        } catch {
            if isCancelled(error) { return }
            self.error = error.localizedDescription
        }
        //
        //        : try await service.searchProducts(searchText: searchText)
    }
    
    func loadNextPage() async {
        isLoadingNextPage = true
        error = nil


        do {
            let fetched: [Product]
            if let selectedCategory, searchText.isEmpty {
                fetched = try await service.fetchProducts(
                    category: selectedCategory,
                    limit: limit,
                    skip: products.count,
                    sortBy: sortOption.sortBy,
                    order: sortOption.order
                )
            } else {
                fetched = try await service.fetchProducts(
                    limit: limit,
                    skip: products.count,
                    sortBy: sortOption.sortBy,
                    order: sortOption.order
                )
            }
            self.products.append(contentsOf: fetched)
            self.error = nil
            self.isLoadingNextPage = false
            self.skipCount += self.limit
            self.canLoadMorePages = (fetched.count == self.limit)
        } catch {
            if isCancelled(error) { return }
            self.error = error.localizedDescription
            self.isLoadingNextPage = false
        }

    }
    
    
    private func observeSearchText() {
        Task {
            await self.performSearch(query: searchText)
        }
    }

    private func performSearch(query: String) async {
        guard !query.isEmpty else {
            await loadProducts()
            return
        }
        selectedCategory = nil
        isLoading = true
        error = nil
        self.canLoadMorePages = false
        do {
            self.products = try await service.searchProducts(searchText: query)
            self.error = nil
        } catch {
            if isCancelled(error) { return }
            self.error = error.localizedDescription
        }
        self.isLoading = false
    }

    func searchTextChanged() {
        searchTask?.cancel()
        if searchText.isEmpty && selectedCategory != nil { return }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await performSearch(query: searchText)
        }
    }

    func searchProducts(searchText: String) async {
        self.isLoading = true
        self.error = nil
        self.skipCount = 0
        self.canLoadMorePages = false
        do {
            self.products = try await service.searchProducts(
                searchText: searchText
            )
            self.isLoading = false
            self.error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

//        func loadProducts1() async {
//            isLoading = true
//            error = nil
//            isLoadingNextPage = false
//            canLoadMorePages = true
//            await service.fetchProducts(limit: limit, skip: skipCount)
//                .sink( receiveCompletion: {  [weak self] completion in
//                    self?.isLoading = false
//                    if case .failure(let err) = completion {
//                        self?.error = err.localizedDescription
//                    }
//                }, receiveValue: { [weak self] products in
//                    self?.skipCount = 0
//                    self?.products = products
//                }
//                )
//                .store(in: &cancellables)
//        }

  

//        func loadNextPage1() async {
//            error = nil
//            isLoadingNextPage = true
//    
//            await service.fetchProducts(limit: limit, skip: skipCount)
//                .sink { [weak self] completion in
//                    self?.isLoadingNextPage = false
//                    if case .failure(let err) = completion {
//                        self?.error = err.localizedDescription
//                    }
//                } receiveValue: { [weak self] products in
//                        self?.products.append(contentsOf:  products)
//                        self?.skipCount += (self?.limit ?? 0)
//                        self?.canLoadMorePages = (products.count == self?.limit)
//                }
//                .store(in: &cancellables)
//        }




    //    private func run(_ publisher: AnyPublisher<[Product], Error>) {
    //            activeRequest?.cancel()          // ← kill any older, slower request
    //            activeRequest = publisher
    //                .sink { [weak self] completion in
    //                    self?.isLoading = false
    //                    if case .failure(let err) = completion {
    //                        self?.error = err.localizedDescription
    //                    }
    //                } receiveValue: { [weak self] products in
    //                    self?.products = products
    //                }
    //        }

  //Refresh added
    
    

    //      private func observeSearchText() {
    //          Task {
    ////              await self.performSearch(query: searchText)
    //          }
    //      }

    //TODO: Apply this method
    //    func searchProducts(searchText: String) async {
    //        self.isLoading = true
    //
    //        await service.searchProducts(searchText: searchText).sink(receiveCompletion: { [weak self] completion in
    //            self?.isLoading = false
    //            switch completion {
    //            case .finished:
    //                self?.error = nil
    //                break
    //            case .failure(let error):
    //                print("Error: \(error)")
    //                self?.error = error.localizedDescription
    //            }
    //        }, receiveValue: { [weak self] products in
    //            self?.products = products
    //            self?.skipCount = 0
    //        }).store(in: &cancellables)
    //    }
    
    //            .sink { [weak self] completion in
    //                if case .failure(let err) = completion {
    //                    self?.error = err.localizedDescription
    //                }
    //            } receiveValue: { [weak self1] products in
    //            }
    //            .store(in: &cancellables)
    
    //    private func observeSearchText() async {
    //        $searchText
    //            .removeDuplicates()
    //            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
    //            .sink { [weak self] query in
    //                Task { [weak self] in
    //                    await self?.performSearch(query: query)
    //                }
    //            }
    //            .store(in: &cancellables)
    //    }
}
