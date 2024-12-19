//
//  SpacesView.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/15/24.
//

import SwiftUI
import SwiftData
import MijickPopups
import NavigationTransition
import NavigationTransitions
import Toasts
import SwipeActions

//MARK: - Spaces View

struct SpacesView: View {
    @Query private var categories: [SpaceCategory]
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentToast) var presentToast
    
    // Check if the user has made any purchase
    private var hasAccess: Bool {
        !PurchaseManager.shared.purchasedProductIdentifiers.isEmpty
    }
    
    var sortedCategories: [SpaceCategory] {
        categories.sorted { $0.name < $1.name }
    }
    
    @State private var hideFloatingButton = false
    @State private var currentScrollOffset: CGFloat = 0 // Track current offset for debounce
    @State var previousViewOffset: CGFloat = 0
    let minimumOffset: CGFloat = 60
    
    @State var showPaywallSheet = false
    
    var body: some View {
        GeometryReader { proxy in
            var columns: [GridItem] {
                let width = proxy.size.width
                let amountOfColumns: Int
                
                if width > 600 { // iPad in landscape or larger screens
                    amountOfColumns = 5
                } else if width > 500 { // iPad in portrait
                    amountOfColumns = 4
                } else if width > 400 { // Larger iPhones or small tablets
                    amountOfColumns = 3
                } else { // Smaller iPhones
                    amountOfColumns = 2
                }
                
                return Array(repeating: GridItem(.flexible(), spacing: 16), count: amountOfColumns)
            }
            
            NavigationStack {
                ZStack {
                    if hasAccess {
                        // Main Content (User has access)
                        ScrollView {
                            if sortedCategories.isEmpty {
                                emptyView
                            } else {
                                mainContent(columns: columns)
                            }
                        }
                        
                        // Floating Action Button
                        MainButton(imageName: "plus", colorHex: "#1e6794", width: 60) {
                            Task {
                                await CentrePopup_AddCategory(
                                    modelContext: modelContext
                                ) {
                                    let toast = ToastValue(
                                        icon: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green),
                                        message: NSLocalizedString("Category Added", comment: "")
                                    )
                                    presentToast(toast)
                                }.present()
                            }
                        }
                        .offset(y: hideFloatingButton ? 100 : 0)
                        .animation(.spring(), value: hideFloatingButton)
                        .vSpacing(.bottom).hSpacing(.trailing)
                        .padding()
                    } else {
                        // Blocked View (User has no access)
                        blockedView
                    }
                }
                .navigationTitle("Spaces")
                .navigationTransition(
                    .zoom.combined(with: .fade(.in))
                )
                .sheet(isPresented: $showPaywallSheet) {
                    PaywallView()
                        .presentationDragIndicator(.visible)
                        .presentationCornerRadius(30) // Set the corner radius
                }
            }
            
        }
    }
    
    @ViewBuilder
    private var emptyView: some View {
        VStack {
            Text("No Spaces yet.")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding()
                .hSpacing(.center)
            Button {
                Task {
                    HapticManager.shared.trigger(.lightImpact)
                    await CentrePopup_AddCategory(modelContext: modelContext) {
                        let toast = ToastValue(
                            icon: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green),
                            message: NSLocalizedString("Category Added", comment: "")
                        )
                        presentToast(toast)
                    }
                    .present()
                }
            } label: {
                Image(systemName: "square.split.2x2")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
            }
        }
        .vSpacing(.center)
    }
    
    @ViewBuilder
    private func mainContent(columns: [GridItem]) -> some View {
        SwipeViewGroup {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(sortedCategories) { category in
                    SwipeView {
                        NavigationLink(destination: NavigationLazyView(ItemsView(category: category )
                            .installToast(position: .bottom))
                        ) {
                            CategoryCell(category: category)
                                .id(category.id)
                                .transition(.customBackInsertion)
                        }
                        .onTapHaptic(.lightImpact)
                    } trailingActions: { context in
                        VStack {
                            SwipeAction(
                                systemImage: "trash",
                                backgroundColor: .red
                            ) {
                                HapticManager.shared.trigger(.lightImpact)
                                DispatchQueue.main.async {
                                    context.state.wrappedValue = .closed
                                    Task {
                                        await CentrePopup_DeleteSpace(
                                            modelContext: modelContext,
                                            space: category
                                        ) {
                                            let toast = ToastValue(
                                                icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                                message: NSLocalizedString("Category Deleted", comment: "")
                                            )
                                            presentToast(toast)
                                        }.present()
                                    }
                                }
                            }
                            .font(.title.weight(.semibold))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            
                            SwipeAction(
                                systemImage: "pencil",
                                backgroundColor: Color.teal
                            ) {
                                HapticManager.shared.trigger(.lightImpact)
                                context.state.wrappedValue = .closed
                                Task {
                                    await CentrePopup_AddCategory(
                                        modelContext: modelContext,
                                        category: category
                                    ) { }.present()
                                }
                            }
                            .allowSwipeToTrigger()
                            .font(.title.weight(.semibold))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                    }
                    .swipeActionCornerRadius(20)
                    .swipeSpacing(5)
                    .swipeOffsetCloseAnimation(stiffness: 500, damping: 100)
                    .swipeOffsetExpandAnimation(stiffness: 500, damping: 100)
                    .swipeOffsetTriggerAnimation(stiffness: 500, damping: 100)
                    .swipeMinimumDistance(25)
                }
            }
            .animation(.spring(), value: sortedCategories)
            .padding()
        }
    }
    
    @ViewBuilder
    private var blockedView: some View {
        VStack(spacing: 24) {
            // Lock Icon
            Image(systemName: "lock.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // Title
            Text("Unlock Spaces")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Description
            Text("Access to Spaces requires a purchase. Unlock all features to continue.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            
            // Unlock Button
            Button(action: {
                Task {
                    PurchaseManager.shared.fetchProducts()
                    // Show a purchase sheet or navigate to a purchase view
                    showPaywallSheet = true
                }
            }) {
                Text("Unlock Now")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.blue.opacity(0.2))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.blue.opacity(0.8), lineWidth: 1)
                    )
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 16)
            .shadow(color: Color.gray.opacity(0.3), radius: 6, x: 0, y: 4)
        }
        .padding(16)
        .background(Color.secondarySystemBackground)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: Color.gray.opacity(0.3), radius: 10, x: 0, y: 5)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .vSpacing(.center)
        .padding()
    }
}

//MARK: - Delete Spaces

struct CentrePopup_DeleteSpace: CenterPopup {
    @State var modelContext: ModelContext
    @Environment(\.mainWindowSize) var mainWindowSize
    @Environment(\.colorScheme) var colorScheme
    
    var space: SpaceCategory
    var onDelete: () -> Void
    
    var body: some View {
        createContent()
    }
    
    func createContent() -> some View {
        VStack(spacing: 16) {
            // Title
            Text("Delete Space")
                .font(.headline)
                .padding(.bottom, 8)
            
            // Warning Message
            Text("Are you sure you want to delete this space? This action cannot be undone.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.bottom, 16)
            
            // Display space content for reference
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(space.color.color.opacity(0.8))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: space.icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.white)
                        )
                    
                    Text(space.name)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.horizontal, 16)
            
            // Action Buttons
            HStack(spacing: 16) {
                Button(action: {
                    HapticManager.shared.trigger(.lightImpact)
                    Task { await dismissLastPopup() }
                }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.gray.opacity(0.2))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray.opacity(0.8), lineWidth: 1)
                        )
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.gray.opacity(0.3), radius: 6, x: 0, y: 4)
                
                Button(action: {
                    HapticManager.shared.trigger(.lightImpact)
                    deleteSpace()
                    Task { await dismissLastPopup() }
                    
                    onDelete()
                }) {
                    Text("Delete")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.red.opacity(0.2))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.red.opacity(0.8), lineWidth: 1)
                        )
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.gray.opacity(0.3), radius: 6, x: 0, y: 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .padding(16)
        .background(Color.secondarySystemBackground)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    func deleteSpace() {
        modelContext.delete(space)
        do {
            try modelContext.save()
            HapticManager.shared.trigger(.success)
            print("Space deleted successfully.")
        } catch {
            HapticManager.shared.trigger(.error)
            print("Error deleting space: \(error)")
        }
    }
}

//MARK: - CategoryCell

struct CategoryCell: View {
    let category: SpaceCategory
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Background styling
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            category.color.color.opacity(0.2),
                            colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(borderColor, lineWidth: 1)
                )
                .shadow(color: shadowColor, radius: 6, x: 0, y: 4)

            VStack(spacing: 12) {
                // Icon section
                Circle()
                    .fill(category.color.color.opacity(0.8))
                    .frame(width: 80, height: 80) // Reduced circle size for better balance
                    .overlay(
                        Image(systemName: category.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                    )
                    .shadow(radius: 4)

                // Category name section
                Text(category.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2) // Limit to 2 lines for better balance
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - Helpers
    private var borderColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.4) : Color.gray.opacity(0.3)
    }

    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.2)
    }
}

//MARK: - Add Category Popup

struct CentrePopup_AddCategory: CenterPopup {
    @State var modelContext: ModelContext
    @Environment(\.mainWindowSize) var mainWindowSize
    @Environment(\.colorScheme) var colorScheme
    
    var onDone: () -> Void
    
    @State private var categoryName: String
    @State private var selectedIcon: String
    @State private var selectedColor: CategoryColor
    @State private var error: String?
    
    private var existingCategory: SpaceCategory?
    
    @FocusState private var focusedField: Field?
        
    enum Field {
        case name
    }
    
    init(modelContext: ModelContext, category: SpaceCategory? = nil, onDone: @escaping () -> Void) {
        self.modelContext = modelContext
        self.existingCategory = category
        self.onDone = onDone
        
        // Prepopulate fields if editing, otherwise leave them empty
        _categoryName = State(initialValue: category?.name ?? "")
        _selectedIcon = State(initialValue: category?.icon ?? "square.grid.2x2.fill")
        _selectedColor = State(initialValue: category?.color ?? .blue)
    }
    
    var body: some View {
        createContent()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
    }
    
    func createContent() -> some View {
        ZStack {
            VStack(spacing: 16) {
                // Dynamic Title
                Text(existingCategory == nil ? "Add Category" : "Edit Category")
                    .font(.headline)
                    .padding(.bottom, 8)
                
                // Name TextField
                VStack(alignment: .leading, spacing: 12) {
                    Text("Category Name")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    createStyledTextField(
                        "Enter category name",
                        text: $categoryName,
                        field: .name
                    )
                }
                
                // Icon Picker
                VStack(alignment: .leading, spacing: 8) {
                    IconPickerView(selectedIcon: $selectedIcon, selectedColor: $selectedColor)
                }
                
                // Color Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category Color")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ColorPickerView(selectedColor: $selectedColor)
                }
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button(action: {
                        HapticManager.shared.trigger(.lightImpact)
                        Task { await dismissLastPopup() }
                    }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.red.opacity(0.1)) // Subtle red tint
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.red.opacity(0.8), lineWidth: 1)
                            )
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.gray.opacity(0.3), radius: 6, x: 0, y: 4)
                    
                    Button(action: {
                        HapticManager.shared.trigger(.lightImpact)
                        Task {
                            let result = await saveCategory()
                            if result.isSuccess {
                                HapticManager.shared.trigger(.success)
                                await dismissLastPopup()
                                onDone()
                            } else {
                                HapticManager.shared.trigger(.error)
                                error = "Error saving category. Please try again."
                            }
                        }
                    }) {
                        Text(existingCategory == nil ? "Save" : "Update")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.blue.opacity(0.2))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.blue.opacity(0.8), lineWidth: 1)
                            )
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.gray.opacity(0.3), radius: 6, x: 0, y: 4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .padding(16)
            .background(Color.secondarySystemBackground)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .hideKeyboardOnDrag()
        }
    }
    
    @FocusState private var isFocused: Bool

    func createStyledTextField(_ placeholder: String, text: Binding<String>, field: Field) -> some View {
        TextField(placeholder, text: text)
            .focused($focusedField, equals: field)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(colorScheme == .dark ? 0.2 : 0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(text.wrappedValue.isEmpty ? Color.secondary.opacity(0.3) : Color.blue.opacity(0.8), lineWidth: 1)
            )
            .cornerRadius(20)
            .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.gray.opacity(0.3), radius: 6, x: 0, y: 4)
            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
    }
    
    func saveCategory() async -> Result<Void, Error> {
        guard !categoryName.isEmpty else {
            print("Cannot save: Category name is empty")
            return .failure(ValidationError.emptyName)
        }
        
        do {
            if let existingCategory = existingCategory {
                // Update the existing category
                existingCategory.name = categoryName
                existingCategory.icon = selectedIcon
                existingCategory.color = selectedColor
            } else {
                // Create a new category
                let newCategory = SpaceCategory(
                    name: categoryName,
                    icon: selectedIcon,
                    color: selectedColor
                )
                modelContext.insert(newCategory)
            }
            
            try modelContext.save()
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    enum ValidationError: Error {
        case emptyName
    }
    
    func configurePopup(config: CenterPopupConfig) -> CenterPopupConfig {
        config
            .tapOutsideToDismissPopup(true)
    }
}



//MARK: - Icon Picker

struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Binding var selectedColor: CategoryColor
    @State private var isPickerActive = false // Tracks whether the grid picker is active

    @Environment(\.colorScheme) var colorScheme
    
    // List of icons to choose from
    private let icons: [String] = [
        "folder.fill", "book.fill", "star.fill", "tag.fill", "calendar",
        "cloud.fill", "bell.fill", "bubble.left.fill", "lightbulb.fill",
        "heart.fill", "globe", "paperplane.fill", "flame.fill", "cart.fill",
        "wand.and.stars", "leaf.fill", "graduationcap.fill", "gift.fill",
        "doc.fill", "camera.fill"
    ]
    private let columns = [GridItem(.adaptive(minimum: 60))] // Adaptive grid layout

    var body: some View {
        VStack {
            if isPickerActive {
                // Grid Picker View
                VStack {
                    Text("Choose an Icon")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.bottom, 8)

                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(icons, id: \.self) { icon in
                                Button(action: {
                                    withAnimation(.spring()) {
                                        selectedIcon = icon
                                        isPickerActive = false
                                    }
                                }) {
                                    VStack {
                                        Image(systemName: icon)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20)
                                            .padding()
                                            .background(selectedIcon == icon ? selectedColor.color.opacity(0.3) : Color.gray.opacity(0.1))
                                            .foregroundStyle(selectedColor.color)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedIcon == icon ? selectedColor.color : Color.clear, lineWidth: 2)
                                            )
                                            .shadow(radius: selectedIcon == icon ? 4 : 2)
                                    }
                                }
                            }
                        }
                        .padding()
                    }

                    Button(action: {
                        HapticManager.shared.trigger(.lightImpact)
                        withAnimation(.spring()) {
                            isPickerActive = false
                        }
                    }) {
                        Text("Close")
                            .frame(maxWidth: 70)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.red.opacity(0.1)) // Subtle red tint
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.red.opacity(0.8), lineWidth: 1)
                            )
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.gray.opacity(0.3), radius: 6, x: 0, y: 4)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.9)).animation(.spring()),
                    removal: .opacity.animation(.easeOut)
                ))
            } else {
                // Selected Icon View
                VStack {
                    Text("Selected Icon")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            isPickerActive = true
                        }
                    }) {
                        VStack {
                            Image(systemName: selectedIcon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .padding()
                                .background(selectedColor.color.opacity(0.2))
                                .foregroundStyle(selectedColor.color)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor.color, lineWidth: 2)
                                )
                            
                            Text("Change Icon")
                                .font(.caption)
                                .foregroundColor(selectedColor.color)
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.animation(.easeIn),
                    removal: .opacity.combined(with: .scale(scale: 0.9)).animation(.spring())
                ))
            }
        }
    }
}

//MARK: - Color Picker

struct ColorPickerView: View {
    @Binding var selectedColor: CategoryColor
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(CategoryColor.allCases, id: \.self) { color in
                Circle()
                    .fill(color.color)
                    .frame(width: selectedColor == color ? 50 : 40, height: selectedColor == color ? 50 : 40)
                    .overlay(
                        Circle()
                            .stroke(selectedColor == color ? Color.blue : Color.clear, lineWidth: 3)
                    )
                    .scaleEffect(selectedColor == color ? 1.1 : 1.0)
                    .animation(.spring(), value: selectedColor == color)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            selectedColor = color
                        }
                    }
            }
        }
    }
}


//MARK: - MainButton

struct MainButton: View {
    
    var imageName: String
    var colorHex: String
    var width: CGFloat = 50
    var action: () -> Void
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        ZStack {
            //if StorageManager.shared.synchronized {
            
            ZStack {
                Color(hex: colorHex)
                    .frame(width: width, height: width)
                    .cornerRadius(width / 2)
                    .shadow(color: Color(hex: colorHex).opacity(0.3), radius: 15, x: 0, y: 15)
                Image(systemName: imageName)
                    .foregroundColor(.white)
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.2), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        HapticManager.shared.trigger(.lightImpact)
                        isPressed = true
                    }
                    .onEnded { _ in
                        isPressed = false
                        action()
                    }
            )
            //}
        }//.animation(.spring(), value: StorageManager.shared.synchronized)
    }
}
