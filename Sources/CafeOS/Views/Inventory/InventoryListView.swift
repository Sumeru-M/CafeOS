// MARK: - InventoryListView.swift
// Main inventory screen with search, filter, sort, and swipe-to-delete.

import SwiftUI

struct InventoryListView: View {
    @EnvironmentObject var vm: InventoryViewModel
    @State private var showAddItem   = false
    @State private var showSortMenu  = false

    var body: some View {
        ZStack {
            // Main content
            Group {
                if vm.isLoading {
                    LoadingView(message: "Loading inventory…")
                } else if vm.isEmpty {
                    emptyState
                } else {
                    itemList
                }
            }

            // Error banner (top overlay)
            if let error = vm.error {
                VStack {
                    ErrorBannerView(message: error.localizedDescription) { vm.clearError() }
                        .padding(.top, 4)
                    Spacer()
                }
                .zIndex(10)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: vm.error != nil)
            }
        }
        .navigationTitle("Inventory")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $vm.searchText, prompt: "Search items…")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // Sort picker
                Menu {
                    ForEach(InventoryViewModel.SortOption.allCases, id: \.self) { option in
                        Button(action: { vm.sortOption = option }) {
                            Label(option.rawValue, systemImage: vm.sortOption == option ? "checkmark" : "")
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle")
                        .foregroundColor(.cafeCaramel)
                }

                // Category filter
                Menu {
                    Button("All Categories") { vm.filterCategory = nil }
                    Divider()
                    ForEach(InventoryCategory.allCases, id: \.self) { cat in
                        Button(action: { vm.filterCategory = cat }) {
                            Label("\(cat.icon) \(cat.rawValue)",
                                  systemImage: vm.filterCategory == cat ? "checkmark" : "")
                        }
                    }
                } label: {
                    Image(systemName: vm.filterCategory == nil
                          ? "line.3.horizontal.decrease.circle"
                          : "line.3.horizontal.decrease.circle.fill")
                        .foregroundColor(.cafeCaramel)
                }

                // Add button
                Button(action: { vm.resetDraft(); showAddItem = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.cafeCaramel)
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showAddItem) {
            AddEditItemView(mode: .add)
        }
    }

    // MARK: Sub-views

    private var itemList: some View {
        List {
            // Low stock summary banner
            if vm.lowStockCount > 0 && vm.filterCategory == nil && vm.searchText.isEmpty {
                lowStockBanner
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            ForEach(vm.displayedItems) { item in
                NavigationLink(destination: InventoryDetailView(item: item)) {
                    ItemRowView(item: item)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task { await vm.deleteItem(item) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    NavigationLink(destination: AddEditItemView(mode: .edit(item))) {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.cafeCaramel)
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(.spring(response: 0.4), value: vm.displayedItems.map(\.id))
    }

    private var lowStockBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text("\(vm.lowStockCount) item\(vm.lowStockCount == 1 ? "" : "s") below reorder level")
                .font(AppFonts.body_(14))
            Spacer()
        }
        .padding(AppLayout.padding)
        .background(Color.orange.opacity(0.12))
        .cornerRadius(AppLayout.cardRadius)
        .padding(.horizontal, AppLayout.padding)
        .padding(.bottom, 8)
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "📦",
            title: "No Items Yet",
            subtitle: "Add your first inventory item to get started tracking your café supplies.",
            actionTitle: "Add Item",
            action: { vm.resetDraft(); showAddItem = true }
        )
    }
}
