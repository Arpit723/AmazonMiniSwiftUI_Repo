import Foundation

@MainActor
final class ProductListViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var error: String?
    @Published var isLoading = false
    @Published var isLoadingNextPage = false
    @Published var searchText: String = ""
    @Published var canLoadMorePages = true
    private var skipCount: Int = 0
    private var limit: Int = 25

    private let service: ProductService

    private var searchTask: Task<Void, Never>?

   
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
                self.products = try await service.fetchProducts(
                    limit: self.limit,
                    skip: self.skipCount
                )
                self.isLoading = false
            } catch {
                self.error = error.localizedDescription
            }
        } else {
            await self.performSearch(query: searchText)
        }
    }
    
    
    // MARK: - Pull to refresh
    func pullToRefresh() async {
        //            let fetched =
        self.skipCount = 0
        self.error = nil

        do {
            let fetched =
                searchText.isEmpty
                ? try await service.fetchProducts(
                    limit: limit,
                    skip: 0
                ) : try await service.searchProducts(searchText: searchText)
            products = fetched
            error = nil

        } catch {
            self.error = error.localizedDescription
        }
        //
        //        : try await service.searchProducts(searchText: searchText)
    }
    
    func loadNextPage() async {
        isLoadingNextPage = true
        error = nil


        do {
            let products = try await service.fetchProducts(
                    limit: limit,
                    skip: products.count
                )
            self.products.append(contentsOf: products)
            self.error = nil
            self.isLoadingNextPage = false
            self.skipCount += self.limit
            self.canLoadMorePages = (products.count == self.limit)
        } catch {
            self.error = error.localizedDescription
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
        isLoading = true
        error = nil
        self.canLoadMorePages = false
        do {
            self.products = try await service.searchProducts(searchText: query)
            self.error = nil
        } catch {
            self.error = error.localizedDescription
        }
        self.isLoading = false
    }
    
    func searchTextChanged() {
        searchTask?.cancel()
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

    //    func loadProducts() async {
    //        isLoading = true
    //        error = nil
    //        isLoadingNextPage = false
    //        canLoadMorePages = true
    //        await service.fetchProducts(limit: limit, skip: skipCount)
    //            .sink( receiveCompletion: {  [weak self] completion in
    //                self?.isLoading = false
    //                if case .failure(let err) = completion {
    //                    self?.error = err.localizedDescription
    //                }
    //            }, receiveValue: { [weak self] products in
    //                self?.skipCount = 0
    //                self?.products = products
    //            }
    //            )
    //            .store(in: &cancellables)
    //    }

  

    //    func loadNextPage() async {
    //        error = nil
    //        isLoadingNextPage = true
    //
    //        await service.fetchProducts(limit: limit, skip: skipCount)
    //            .sink { [weak self] completion in
    //                self?.isLoadingNextPage = false
    //                if case .failure(let err) = completion {
    //                    self?.error = err.localizedDescription
    //                }
    //            } receiveValue: { [weak self] products in
    //                    self?.products.append(contentsOf:  products)
    //                    self?.skipCount += (self?.limit ?? 0)
    //                    self?.canLoadMorePages = (products.count == self?.limit)
    //            }
    //            .store(in: &cancellables)
    //    }




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
