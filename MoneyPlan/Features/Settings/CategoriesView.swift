import SwiftUI

@MainActor
@Observable
final class CategoriesViewModel {
    var categories: [Category] = []
    var isLoading = true
    var errorMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            categories = try await FinanceAPI.fetchCategories()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func create(name: String, icon: String?) async throws {
        _ = try await FinanceAPI.createCategory(name: name, icon: icon)
        await load()
    }

    func update(_ category: Category, name: String, icon: String?) async throws {
        _ = try await FinanceAPI.updateCategory(id: category.id, name: name, icon: icon)
        await load()
    }

    func delete(_ category: Category) async throws {
        try await FinanceAPI.deleteCategory(id: category.id)
        await load()
    }
}

/// Category management as an icon-tile grid: tap a tile to edit, tap "New" or +
/// to add. Long-press enters home-screen-style jiggle mode where tiles wiggle
/// with a native gray minus badge to delete; Done (or tapping empty space) exits.
struct CategoriesView: View {
    @State private var viewModel = CategoriesViewModel()
    @State private var showAddSheet = false
    @State private var editingCategory: Category?
    @State private var toDelete: Category?
    @State private var actionError: String?
    @State private var isEditMode = false

    private let columns = [GridItem(.adaptive(minimum: 76), spacing: 14)]

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingStateView()
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView("common.unexpectedError", systemImage: "exclamationmark.triangle", description: Text(error))
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(viewModel.categories) { category in
                            CategoryTile(category: category, isEditMode: isEditMode) {
                                editingCategory = category
                            } onDelete: {
                                toDelete = category
                            } onEnterEditMode: {
                                enterEditMode()
                            }
                        }

                        NewCategoryTile {
                            showAddSheet = true
                        }
                    }
                    .padding()

                    // Tapping the empty space below the grid exits jiggle mode.
                    if isEditMode {
                        Color.clear
                            .frame(height: 300)
                            .contentShape(Rectangle())
                            .onTapGesture { exitEditMode() }
                    }
                }
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationTitle("settings.categories")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isEditMode {
                    Button("common.done") { exitEditMode() }
                        .fontWeight(.semibold)
                } else {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("categories.add")
                }
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .sheet(isPresented: $showAddSheet) {
            CategoryFormSheet { name, icon in
                try await viewModel.create(name: name, icon: icon)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingCategory) { category in
            CategoryFormSheet(editing: category) { name, icon in
                try await viewModel.update(category, name: name, icon: icon)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog(
            "categories.confirmDelete.title",
            isPresented: Binding(
                get: { toDelete != nil },
                set: { if !$0 { toDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("common.delete", role: .destructive) {
                if let category = toDelete {
                    Task {
                        do { try await viewModel.delete(category) } catch { actionError = error.localizedDescription }
                    }
                }
            }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("categories.confirmDelete.body")
        }
        .alert(
            "common.unexpectedError",
            isPresented: Binding(
                get: { actionError != nil },
                set: { if !$0 { actionError = nil } }
            )
        ) {
            Button("common.done", role: .cancel) {}
        } message: {
            Text(actionError ?? "")
        }
    }

    private func enterEditMode() {
        guard !isEditMode else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.easeInOut(duration: 0.2)) {
            isEditMode = true
        }
    }

    private func exitEditMode() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isEditMode = false
        }
    }
}

// MARK: - Tiles

private struct CategoryTile: View {
    let category: Category
    let isEditMode: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onEnterEditMode: () -> Void

    @State private var isWiggling = false

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: CategoryIcon.symbol(for: category))
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppColors.primary)
                .frame(width: 58, height: 58)
                .background(AppColors.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(alignment: .topLeading) {
                    // Custom categories can be deleted; seeded defaults cannot.
                    if isEditMode, !category.isDefault {
                        Button(action: onDelete) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 22))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color(.darkGray), Color(.systemGray5))
                        }
                        .offset(x: -8, y: -8)
                        .accessibilityLabel("common.delete")
                        .transition(.scale.combined(with: .opacity))
                    }
                }

            Text(category.name)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .rotationEffect(.degrees(rotationAngle))
        .animation(
            isWiggling
                ? .easeInOut(duration: 0.13).repeatForever(autoreverses: true).delay(Double.random(in: 0 ... 0.1))
                : .easeOut(duration: 0.15),
            value: isWiggling
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditMode {
                onEdit()
            }
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            onEnterEditMode()
        }
        .onChange(of: isEditMode) { _, editing in
            isWiggling = editing
        }
        .onAppear {
            isWiggling = isEditMode
        }
    }

    /// Home-screen jiggle: oscillates between ±1.8° while in edit mode.
    private var rotationAngle: Double {
        guard isEditMode else { return 0 }
        return isWiggling ? 1.8 : -1.8
    }
}

private struct NewCategoryTile: View {
    let onAdd: () -> Void

    var body: some View {
        Button(action: onAdd) {
            VStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppColors.muted)
                    .frame(width: 58, height: 58)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(AppColors.muted.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    }

                Text("categories.new")
                    .font(.caption)
                    .foregroundStyle(AppColors.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("categories.add")
    }
}

// MARK: - Add / edit form

private struct CategoryFormSheet: View {
    @Environment(\.dismiss) private var dismiss

    var editing: Category?
    var onSave: (String, String?) async throws -> Void

    @State private var name = ""
    @State private var selectedIcon: String = CategoryIcon.pickerSymbols[0]
    @State private var isSaving = false
    @State private var errorMessage = ""

    private let iconColumns = [GridItem(.adaptive(minimum: 52), spacing: 12)]

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    TextField("categories.namePlaceholder", text: $name)
                        .padding(14)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("categories.form.iconSection")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColors.muted)
                            .textCase(.uppercase)
                            .tracking(0.8)

                        LazyVGrid(columns: iconColumns, spacing: 12) {
                            ForEach(CategoryIcon.pickerSymbols, id: \.self) { symbol in
                                iconOption(symbol)
                            }
                        }
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundStyle(AppColors.danger)
                            .font(.footnote)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(editing == nil ? "categories.addTitle" : "categories.editTitle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("common.save") {
                            Task { await save() }
                        }
                        .disabled(trimmedName.isEmpty)
                    }
                }
            }
            .onAppear(perform: populate)
        }
        .tint(AppColors.primary)
        .interactiveDismissDisabled(isSaving)
    }

    private func iconOption(_ symbol: String) -> some View {
        let isSelected = symbol == selectedIcon
        return Button {
            selectedIcon = symbol
        } label: {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(isSelected ? .white : AppColors.muted)
                .frame(width: 52, height: 44)
                .background(
                    isSelected ? AppColors.primary : Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
        }
        .buttonStyle(.plain)
    }

    private func populate() {
        guard let editing else { return }
        name = editing.name
        selectedIcon = CategoryIcon.symbol(for: editing)
    }

    private func save() async {
        guard !trimmedName.isEmpty else { return }
        isSaving = true
        errorMessage = ""
        defer { isSaving = false }

        do {
            try await onSave(trimmedName, selectedIcon)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
