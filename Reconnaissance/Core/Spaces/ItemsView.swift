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
import Toasts

struct ItemsView: View {
    let category: SpaceCategory
    
    @Query private var items: [Item]
    
    var itemsOfCategory: [Item] {
        items.filter { $0.categoryID == category.id }
    }
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.presentToast) var presentToast
    
    @State private var hideFloatingButton = false
    
    @State private var currentScrollOffset: CGFloat = 0 // Track current offset for debounce
    @State var previousViewOffset: CGFloat = 0
    let minimumOffset: CGFloat = 60
    @State var backAnimation = false
    @State var progress: CGFloat = 0.0
    
    @State private var showImage = false
    @State private var selectedImage: UIImage?
    @State private var selectedItemId: UUID?
    
    @Namespace private var namespace
    
    var body: some View {
        GeometryReader { proxy in
            NavigationStack {
                ZStack {
                    ScrollView {
                        if itemsOfCategory.isEmpty {
                            VStack {
                                Text("No Items yet.")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .hSpacing(.center)
                                Button {
                                    Task {
                                        HapticManager.shared.trigger(.lightImpact)
                                        await CentrePopup_AddItem(
                                            modelContext: modelContext,
                                            categoryID: category.id
                                        ) {
                                            let toast = ToastValue(
                                                icon: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green),
                                                message: NSLocalizedString("Item Added", comment: "")
                                            )
                                            presentToast(toast)
                                        }.present()
                                    }
                                } label: {
                                    Image(systemName: "tray.circle")
                                        .font(.system(size: 60))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .vSpacing(.center)
                        } else {
                            SwipeViewGroup {
                                Spacer()
                                LazyVStack {
                                    ForEach(itemsOfCategory) { item in
                                        SwipeView {
                                            ItemCell(item: item, mainWindowSize: proxy.size)
                                                .onTapGesture {
                                                    handleItemTap(item: item)
                                                }
                                                .optionalViewModifier { content in
                                                    if #available(iOS 18.0, *) {
                                                        content
                                                            .matchedTransitionSource(id: item.id.uuidString, in: namespace)
                                                    } else {
                                                        content
                                                    }
                                                }
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
                                                        ) {
                                                            let toast = ToastValue(
                                                                icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                                                message: NSLocalizedString("Item Deleted", comment: "")
                                                            )
                                                            presentToast(toast)
                                                        }.present()
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
                    
                    MainButton(imageName: "plus", colorHex: "#1e6794", width: 60) {
                        Task {
                            await CentrePopup_AddItem(
                                modelContext: modelContext,
                                categoryID: category.id
                            ) {
                                let toast = ToastValue(
                                    icon: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green),
                                    message: NSLocalizedString("Item Added", comment: "")
                                )
                                presentToast(toast)
                            }.present()
                        }
                    }
                    .offset(y: hideFloatingButton ? 100 : 0)
                    .animation(.spring(), value: hideFloatingButton)
                    .vSpacing(.bottom).hSpacing(.trailing)
                    .padding()
                }
            }
            .navigationDestination(isPresented: $showImage) {
                if let selectedImage = selectedImage {
                    FullScreenImageView(image: selectedImage)
                        .optionalViewModifier { content in
                            if #available(iOS 18.0, *) {
                                content
                                    .navigationTransition(.zoom(sourceID: "zoom\(selectedItemId?.uuidString ?? UUID().uuidString)", in: namespace))
                            } else {
                                content
                            }
                        }
                }
            }
            .navigationTransition(
                .zoom.combined(with: .fade(.in))
            )
        }
    }
    
    struct FullScreenImageView: View {
        let image: UIImage
        
        @Environment(\.presentationMode) private var presentationMode
        
        @State var backAnimation = false
        @State var progress: CGFloat = 0.0
        
        var body: some View {
            NavigationStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .background(Color.black)
                    .ignoresSafeArea()
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
            }
        }
    }
    
    private func addItem() {
        // Logic to add a new item
    }
    
    private func handleItemTap(item: Item) {
        switch item.type {
        case .document:
            Task {
                if let url = item.dataURL {
                    let iCloudDirectory = ICloudManager.shared.getICloudDirectory()
                    let fileURL = iCloudDirectory?.appendingPathComponent(
                        url.lastPathComponent)
                    
                    if let fileURL = fileURL, FileManager.default.fileExists(atPath: fileURL.path) {
                        print("File exists in iCloud: \(fileURL)")
                        let documentController = UIDocumentInteractionController(url: fileURL)
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
                    } else {
                        print("File not found in iCloud.")
                    }
                    
                    
                }
            }
        case .image:
            Task {
                guard let icloudDirectory = ICloudManager.shared.getICloudDirectory(),
                      let url = item.dataURL else {
                    print("iCloud directory or dataURL is not available.")
                    return
                }

                let fileURL = icloudDirectory.appendingPathComponent(url.lastPathComponent)

                do {
                    let imageData = try await withCheckedThrowingContinuation { continuation in
                        DispatchQueue.global().async {
                            if let data = try? Data(contentsOf: fileURL) {
                                continuation.resume(returning: data)
                            } else {
                                continuation.resume(throwing: NSError(domain: "FileLoadError", code: -1))
                            }
                        }
                    }
                    if let image = UIImage(data: imageData) {
                        await MainActor.run {
                            selectedImage = image
                            selectedItemId = item.id
                            
                            showImage = true
                        }
                    }
                } catch {
                    print("Failed to load image from iCloud directory: \(error)")
                }
            }
        case .text:
            // Handle text if needed
            Task {
                await CentrePopup_TextPreview(text: item.text ?? "", title: item.name)
                    .present()
            }
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
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            backgroundColor(for: item.type).opacity(0.1),
                            Color.clear
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(borderColor, lineWidth: 1)
                )
                .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
            
            HStack(spacing: 12) {
                // Left Side: Details
                VStack(alignment: .leading, spacing: 8) {
                    // Type Tag
                    HStack {
                        Text(item.type.rawValue.capitalized)
                            .font(.caption)
                            .foregroundColor(typeColor(for: item.type))
                            .padding(6)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                            )
                        Spacer()
                    }
                    
                    // Name
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // Additional Details
                    switch item.type {
                    case .document:
                        Text(item.dataURL?.lastPathComponent ?? "Unknown Document")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    case .text:
                        Text(item.text ?? "Empty Text")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    case .image:
                        Text("Image File")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if item.type != .text {
                    // Right Side: Content Preview
                    contentPreview
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .frame(
            width: mainWindowSize.width * 0.9,
            height: 150
        )
    }
    
    // MARK: - Content Preview
    
    private var contentPreview: some View {
        Group {
            switch item.type {
            case .document:
                documentPreview
            case .image:
                imagePreview
            case .text:
                textPreview
            }
        }
    }
    
    private var documentPreview: some View {
        Group {
            if let url = item.dataURL,
               let thumbnail = generateThumbnail(for: url) {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "doc.text")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(typeColor(for: .document))
                    .padding(20)
            }
        }
    }
    
    private var imagePreview: some View {
        Group {
            if let icloudDirectory = ICloudManager.shared.getICloudDirectory(),
               let dataURL = item.dataURL,
               let imageData = try? Data(contentsOf: icloudDirectory.appendingPathComponent(dataURL.lastPathComponent, conformingTo: .image)),
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(typeColor(for: .image))
            }
        }
    }
    
    private var textPreview: some View {
        Image(systemName: "text.bubble")
            .resizable()
            .scaledToFit()
            .foregroundColor(typeColor(for: .text))
            .padding(20)
    }
    
    // MARK: - Helpers
    
    private var borderColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3)
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.4) : Color.gray.opacity(0.2)
    }
    
    private func typeColor(for type: ItemType) -> Color {
        switch type {
        case .document: return .blue
        case .image: return .green
        case .text: return .orange
        }
    }
    
    private func backgroundColor(for type: ItemType) -> Color {
        switch type {
        case .document: return .blue
        case .image: return .green
        case .text: return .orange
        }
    }
}

//MARK: - Text Popup

struct CentrePopup_TextPreview: CenterPopup {
    let text: String
    let title: String
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 8)
            
            ScrollView {
                Text(text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.secondarySystemBackground)
            )
            
            Button(action: {
                Task { await dismissLastPopup() }
            }) {
                Text("Close")
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
        .padding(16)
        .background(Color.secondarySystemBackground)
        .cornerRadius(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            
            // Error Message
            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .bold()
                    .multilineTextAlignment(.center)
                    .animation(.spring(), value: error)
            }
            
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
                    .hSpacing(.center)
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
        
        if itemType == .image {
            guard imageData != nil else {
                error = "Image must be selected!"
                HapticManager.shared.trigger(.error)
                return
            }
        } else if itemType == .document {
            guard fileURL != nil else {
                error = "File must be selected!"
                HapticManager.shared.trigger(.error)
                return
            }
        }
        
        let newItem = Item(
            name: itemName,
            type: itemType,
            categoryID: categoryID,
            dataURL: itemType == .document ? fileURL : nil,
            text: itemType == .text ? textContent : nil
        )
        
        // Save to local model context
        modelContext.insert(newItem)
        try? modelContext.save()
        
        // Save to app's iCloud container
        Task {
            if ICloudManager.shared.isICloudAvailable() {
                do {
                    if itemType == .document, let fileURL = newItem.dataURL {
                        // Handle document upload
                        let fileData = try Data(contentsOf: fileURL)
                        let fileName = fileURL.lastPathComponent
                        
                        let success = await ICloudManager.shared.uploadFile(named: fileName, contents: fileData)
                        if success {
                            print("Document uploaded successfully.")
                        } else {
                            print("Failed to upload document.")
                        }
                        
                    } else if itemType == .image, let imageData = imageData {
                        // Handle image upload
                        let fileName = "\(UUID().uuidString).jpg" // Generate a unique name for the image
                        
                        let success = await ICloudManager.shared.uploadFile(named: fileName, contents: imageData)
                        if success {
                            print("Image uploaded successfully.")
                            newItem.dataURL = ICloudManager.shared.getICloudDirectory()?.appendingPathComponent(fileName)
                            try? modelContext.save()
                        } else {
                            print("Failed to upload image.")
                        }
                    }
                } catch {
                    print("Error uploading file or image: \(error)")
                }
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
            Group {
                if let url = item.dataURL,
                   let thumbnail = generateThumbnail(for: url) {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "doc.text")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(typeColor(for: .document))
                        .padding(20)
                }
            }
        case .image:
            if let icloudDirectory = ICloudManager.shared.getICloudDirectory(),
               let dataURL = item.dataURL,
               let imageData = try? Data(contentsOf: icloudDirectory.appendingPathComponent(dataURL.lastPathComponent, conformingTo: .image)),
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
            Text(item.text ?? "No Content")
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundColor(.secondary)
        }
    }
    
    private func typeColor(for type: ItemType) -> Color {
        switch type {
        case .document: return .blue
        case .image: return .green
        case .text: return .orange
        }
    }
}


