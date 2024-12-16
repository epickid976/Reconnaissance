//
//  ItemsView.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/15/24.
//
import SwiftUI
import SwiftData
import NavigationTransitions
import MijickPopups
import SwipeActions

struct ItemsView: View {
    let category: SpaceCategory
    
    @Query private var items: [Item]
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var hideFloatingButton = false
    
    @State private var currentScrollOffset: CGFloat = 0 // Track current offset for debounce
    @State var previousViewOffset: CGFloat = 0
    let minimumOffset: CGFloat = 60
    @State var backAnimation = false
    @State var progress: CGFloat = 0.0
    
    @State private var showImage = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        GeometryReader { proxy in
            NavigationStack {
                ZStack {
                    ScrollView {
                        if items.isEmpty {
                            VStack {
                                Text("No Items yet.")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .hSpacing(.center)
                                Button {
                                    Task {
                                        HapticManager.shared.trigger(.lightImpact)
                                        //TODO: Add Item
                                    }
                                } label: {
                                    Image(systemName: "tray.circle")
                                        .font(.system(size: 60))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .vSpacing(.center)
                        }
                        SwipeViewGroup {
                            LazyVStack {
                                ForEach(items.filter { $0.categoryID == category.id }) { item in
                                    SwipeView {
                                        ItemCell(item: item, mainWindowSize: proxy.size)
                                            .onTapGesture { handleItemTap(item: item)}
                                    } trailingActions: { context in
                                        SwipeAction(
                                            systemImage: "trash",
                                            backgroundColor: .red
                                        ) {
                                            HapticManager.shared.trigger(.lightImpact)
                                            DispatchQueue.main.async {
                                                context.state.wrappedValue = .closed
                                                Task {
                                                    await CentrePopup_DeleteItem(
                                                        modelContext: modelContext,
                                                        item: item
                                                    ) { }.present()
                                                }
                                            }
                                        }
                                        .font(.title.weight(.semibold))
                                        .foregroundColor(.white)
                                    }
                                    .swipeActionCornerRadius(20)
                                    .swipeSpacing(5)
                                    .swipeOffsetCloseAnimation(stiffness: 500, damping: 100)
                                    .swipeOffsetExpandAnimation(stiffness: 500, damping: 100)
                                    .swipeOffsetTriggerAnimation(stiffness: 500, damping: 100)
                                    .swipeMinimumDistance(25)
                                }
                            }
                        }
                    }
                    .background(GeometryReader {
                        Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                    }).onPreferenceChange(ViewOffsetKey.self) { currentOffset in
                        Task { @MainActor in
                            let offsetDifference: CGFloat = self.previousViewOffset - currentOffset
                            if ( abs(offsetDifference) > minimumOffset) {
                                if offsetDifference > 0 {
                                    DispatchQueue.main.async {
                                        hideFloatingButton = false
                                    }
                                } else {
                                    hideFloatingButton = true
                                }
                                
                                currentScrollOffset = currentOffset
                                self.previousViewOffset = currentOffset
                            }
                        }
                    }
                    .navigationTitle(category.name)
                    .navigationTitle("Items")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden()
                    .toolbar {
                        ToolbarItemGroup(placement: .topBarLeading) {
                            HStack {
                                Button("", action: {withAnimation { backAnimation.toggle(); HapticManager.shared.trigger(.lightImpact) };
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        Task { await dismissAllPopups() }
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                })
                                .buttonStyle(CircleButtonStyle(imageName: "arrow.backward", background: .white.opacity(0), width: 40, height: 40, progress: $progress, animation: $backAnimation))
                            }
                        }
                    }
                    .optionalViewModifier { content in
                        if #available(iOS 18.0, *) {
                            content
                        } else {
                            content
                                .navigationTransition(
                                    .zoom.combined(with: .fade(.in))
                                )
                        }
                    }
                    
                    MainButton(imageName: "plus", colorHex: "#1e6794", width: 60) {
                        Task {
                            //TODO: Add Item
                            await CentrePopup_AddItem(
                                modelContext: modelContext,
                                categoryID: category.id
                            ) { }.present()
                        }
                    }
                    .offset(y: hideFloatingButton ? 100 : 0)
                    .animation(.spring(), value: hideFloatingButton)
                    .vSpacing(.bottom).hSpacing(.trailing)
                    .padding()
                }
            }
            .fullScreenCover(isPresented: $showImage) {
                if let image = selectedImage {
                    VStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .edgesIgnoringSafeArea(.all)
                        
                        Button("Close") {
                            showImage = false
                        }
                        .padding()
                    }
                }
            }
        }
    }
    
    private func addItem() {
        // Logic to add a new item
    }
    
    private func handleItemTap(item: Item) {
        switch item.type {
        case .document:
            if let url = item.dataURL {
                let documentController = UIDocumentInteractionController(url: url)
                documentController.delegate = DocumentInteractionDelegate.shared
                
                DispatchQueue.main.async {
                    let rootVC = DocumentInteractionDelegate.shared.documentInteractionControllerViewControllerForPreview(documentController)
                    
                    if rootVC.presentedViewController == nil {
                        documentController.presentPreview(animated: true)
                    } else {
                        rootVC.presentedViewController?.dismiss(animated: true) {
                            documentController.presentPreview(animated: true)
                        }
                    }
                }
            }
        case .image:
            if let url = item.dataURL, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                selectedImage = image
                showImage = true
            }
        case .text:
            // Handle text if needed
            break
        }
    }
}

//MARK: - Item Cell

struct ItemCell: View {
    let item: Item
    let mainWindowSize: CGSize
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(borderColor, lineWidth: 1)
                )
                .shadow(color: shadowColor, radius: 6, x: 0, y: 4)
                .overlay(
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            itemDateView(for: Date()) // Placeholder date for now
                            Spacer()
                            Text(item.type.rawValue.capitalized)
                                .font(dynamicFont(for: .caption))
                                .foregroundColor(typeColor(for: item.type))
                                .padding(6)
                                .background(
                                    Capsule()
                                        .fill(.thinMaterial)
                                )
                                .background(
                                    Capsule()
                                        .fill(colorScheme == .light ? Color.gray.opacity(0.1) : Color.black.opacity(0.4))
                                )
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                contentPreview(for: item)
                                    .frame(width: 40, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                Text(item.name)
                                    .font(dynamicFont(for: .headline))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                            }
                            if let additionalInfo = additionalInfo(for: item) {
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.blue)
                                    Text(additionalInfo)
                                        .font(dynamicFont(for: .subheadline))
                                        .foregroundColor(.primary.opacity(0.8))
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                        .padding()
                )
            
        }
        .frame(
            width: mainWindowSize.width * 0.9,
            height: 140
        )
    }
    
    // MARK: - Helpers
    
    private var borderColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3)
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.4) : Color.gray.opacity(0.3)
    }
    
    private func dynamicFont(for textStyle: Font.TextStyle) -> Font {
        Font.system(textStyle)
    }
    
    @ViewBuilder
    private func contentPreview(for item: Item) -> some View {
        switch item.type {
        case .document:
            if let url = item.dataURL {
                Text(url.lastPathComponent)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "doc.text")
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            }
        case .image:
            if let imageData = try? Data(contentsOf: item.dataURL!),
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            }
        case .text:
            if let text = item.text {
                Text(text)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "text.bubble")
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            }
        }
    }
    
    private func typeColor(for type: ItemType) -> Color {
        switch type {
        case .document: return .blue
        case .image: return .green
        case .text: return .orange
        }
    }
    
    private func additionalInfo(for item: Item) -> String? {
        switch item.type {
        case .document:
            return item.dataURL?.lastPathComponent
        case .image:
            return "Image File"
        case .text:
            return item.text
        }
    }
    
    private func detailsForFlip(for item: Item) -> String? {
        switch item.type {
        case .document:
            return "File Path: \(item.dataURL?.path ?? "Unknown")"
        case .image:
            return "Image File: \(item.dataURL?.lastPathComponent ?? "Unknown")"
        case .text:
            return "Text Content:\n\(item.text ?? "No Content")"
        }
    }
    
    @ViewBuilder
    private func itemDateView(for date: Date) -> some View {
        let dateString = date.formatted(date: .abbreviated, time: .omitted)
        Text(dateString)
            .font(dynamicFont(for: .caption))
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(.thinMaterial)
            )
            .background(
                Capsule()
                    .fill(colorScheme == .light ? Color.gray.opacity(0.1) : Color.black.opacity(0.4))
            )
    }
}

//MARK: -Add Item Popup

struct CentrePopup_AddItem: CenterPopup {
    @State var modelContext: ModelContext
    @Environment(\.mainWindowSize) var mainWindowSize
    @Environment(\.colorScheme) var colorScheme
    
    var categoryID: UUID
    var onDone: () -> Void
    
    @State private var itemName: String = ""
    @State private var itemType: ItemType = .text
    @State private var textContent: String = ""
    @State private var fileURL: URL? = nil
    @State private var imageData: Data? = nil
    @State private var showFilePicker = false
    @State private var showImagePicker = false
    @State private var error: String?
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name
        case textContent
    }
    
    var body: some View {
        createContent()
    }
    
    func createContent() -> some View {
        VStack(spacing: 16) {
            // Title
            Text("Add Item")
                .font(.headline)
                .padding(.bottom, 8)
            
            // Item Name
            VStack(alignment: .leading, spacing: 12) {
                Text("Item Name")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                createStyledTextField("Enter item name", text: $itemName, field: .name)
            }
            
            // Item Type Picker
            VStack(alignment: .leading, spacing: 12) {
                Text("Item Type")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    ForEach([ItemType.document, ItemType.image, ItemType.text], id: \.self) { type in
                        Button(action: {
                            withAnimation(.spring()) {
                                itemType = type
                            }
                        }) {
                            Text(type.rawValue.capitalized)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(itemType == type ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(itemType == type ? Color.blue : Color.clear, lineWidth: 1)
                                )
                                .foregroundColor(itemType == type ? .blue : .secondary)
                        }
                    }
                }
            }
            
            // Type-Specific Input
            ZStack {
                if itemType == .text {
                    textTypeInput
                        .transition(.opacity)
                } else if itemType == .document {
                    documentTypeInput
                        .transition(.opacity)
                } else if itemType == .image {
                    imageTypeInput
                        .transition(.opacity)
                }
            }
            .animation(.spring(), value: itemType)
            
            // Action Buttons
            HStack(spacing: 16) {
                cancelButton
                saveButton
            }
        }
        .padding(16)
        .background(Color.secondarySystemBackground)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .hideKeyboardOnDrag()
    }
    
    private var textTypeInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Content")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            createStyledTextField("Enter text content", text: $textContent, isMultiline: true, field: .textContent)
        }
    }
    
    private var documentTypeInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("File")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                showFilePicker = true
            }) {
                HStack {
                    Image(systemName: "doc.fill")
                    Text(fileURL == nil ? "Choose File" : fileURL?.lastPathComponent ?? "")
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
            .sheet(isPresented: $showFilePicker) {
                ItemDocumentPicker(fileURL: $fileURL)
            }
        }
    }
    
    private var imageTypeInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Image")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                showImagePicker = true
            }) {
                HStack {
                    Image(systemName: "photo.fill")
                    Text("Select Image")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(imageData: $imageData)
            }
            
            if let imageData {
                Image(uiImage: UIImage(data: imageData)!)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .cornerRadius(10)
            }
        }.id("image")
    }
    
    private var cancelButton: some View {
        Button(action: {
            HapticManager.shared.trigger(.lightImpact)
            Task { await dismissLastPopup() }
        }) {
            Text("Cancel")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.red.opacity(0.1))
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
    
    private var saveButton: some View {
        Button(action: saveItem) {
            Text("Save")
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
        .disabled(itemName.isEmpty || (itemType == .text && textContent.isEmpty))
    }
    
    // Modified save method
    private func saveItem() {
        HapticManager.shared.trigger(.impact)
        
        guard !itemName.isEmpty else {
            error = "Name cannot be empty!"
            HapticManager.shared.trigger(.error)
            return
        }
        
        if itemType == .image || itemType == .document {
            guard fileURL != nil else {
                error = "File or image must be selected!"
                HapticManager.shared.trigger(.error)
                return
            }
        }
        
        let newItem = Item(
            name: itemName,
            type: itemType,
            categoryID: categoryID,
            dataURL: fileURL,
            text: itemType == .text ? textContent : nil
        )
        
        // Save to local model context
        modelContext.insert(newItem)
        try? modelContext.save()
        
        // Save to app's iCloud container
        if AppFileManager.shared.isICloudAvailable() {
            let iCloudSaveSuccessful = AppFileManager.shared.saveToiCloudContainer(item: newItem)
            
            if !iCloudSaveSuccessful {
                print("Failed to save to iCloud container")
                // Optionally handle iCloud save failure
            }
        }
        
        HapticManager.shared.trigger(.success)
        onDone()
        Task { await dismissLastPopup() }
    }
    
    func createStyledTextField(_ placeholder: String, text: Binding<String>, isMultiline: Bool = false, field: Field) -> some View {
        Group {
            if isMultiline {
                TextField(placeholder, text: text, axis: .vertical)
                    .lineLimit(3...6)
                    .focused($focusedField, equals: field)
            } else {
                TextField(placeholder, text: text)
                    .focused($focusedField, equals: field)
            }
        }
        .padding(12)
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
}

//MARK: - Delete Popup

struct CentrePopup_DeleteItem: CenterPopup {
    @State var modelContext: ModelContext
    @Environment(\.mainWindowSize) var mainWindowSize
    @Environment(\.colorScheme) var colorScheme
    
    var item: Item
    var onDelete: () -> Void
    
    var body: some View {
        createContent()
    }
    
    func createContent() -> some View {
        VStack(spacing: 16) {
            // Title
            Text("Delete Item")
                .font(.headline)
                .padding(.bottom, 8)
            
            // Warning Message
            Text("Are you sure you want to delete this item? This action cannot be undone.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.bottom, 16)
            
            // Display item content for reference
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    // Icon or Thumbnail
                    contentPreview(for: item)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .background(Color.gray.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    // Item Details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Text(item.type.rawValue.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
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
                    deleteItem()
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
    
    private func deleteItem() {
        if let dataURL = item.dataURL {
            // Attempt to delete file if it exists
            try? FileManager.default.removeItem(at: dataURL)
        }
        
        modelContext.delete(item)
        do {
            try modelContext.save()
            HapticManager.shared.trigger(.success)
            print("Item deleted successfully.")
        } catch {
            HapticManager.shared.trigger(.error)
            print("Error deleting item: \(error)")
        }
    }
    
    @ViewBuilder
    private func contentPreview(for item: Item) -> some View {
        switch item.type {
        case .document:
            Text(item.dataURL?.lastPathComponent ?? "Unknown File")
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundColor(.secondary)
        case .image:
            if let imageData = try? Data(contentsOf: item.dataURL!),
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
            }
        case .text:
            Text(item.text ?? "No Content")
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundColor(.secondary)
        }
    }
}
