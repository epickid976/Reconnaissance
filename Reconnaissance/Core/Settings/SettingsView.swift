//
//  SettingsView.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/13/24.
//

import SwiftUI
import SwiftData
import StoreKit
import MijickPopups
import Toasts
import UniformTypeIdentifiers

struct SettingsView: View {
    
    //MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.sizeCategory) private var sizeCategory
    @Environment(\.requestReview) private var requestReview
    @Environment(\.presentToast) private var presentToast
    
    //MARK: - Dependencies
    
    @State private var viewModel = SettingsViewModel()
    @StateObject private var preferencesViewModel = ColumnViewModel()
    
    //MARK: - Properties
    @Query var gratitudes: [DailyGratitude]
    
    var body: some View {
        GeometryReader { proxy in
            NavigationStack {
                ScrollView {
                    LazyVStack {
                        //Ad
                        paywallAdSection()
                        // Top Header
                        headerView(name: preferencesViewModel.name)
                        
                        // Preferences
                        preferencesView(mainWindowSize: proxy.size)
                    }
                    .vSpacing(.top)
                    .padding(.horizontal, 5)
                    .navigationTitle("Settings")
                    .sheet(isPresented: $viewModel.showPaywallSheet) {
                        PaywallView()
                            .presentationDragIndicator(.visible)
                            .presentationCornerRadius(30) // Set the corner radius
                    }
                    .sheet(isPresented: $viewModel.showPurchasesOverview) {
                        PurchaseOverviewView()
                            .presentationDragIndicator(.visible)
                            .presentationCornerRadius(30)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func headerView(name: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                // Decorative Gradient Background
                LinearGradient(
                    colors: [.blue.opacity(0.7), .purple.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        // Welcome Text
                        Text("Hello, \(name) 👋")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Edit Button
                        Button(action: {
                            HapticManager.shared.trigger(.lightImpact)
                            Task {
                                await CentrePopup_EditName(
                                    name: $preferencesViewModel.name,
                                    onSave: { newName in
                                        preferencesViewModel.name = newName
                                    },
                                    usingLargeText: sizeCategory.isAccessibilityCategory
                                ).present()
                            }
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Circle().fill(Color.white.opacity(0.2)))
                        }
                    }
                    
                    // Subtitle
                    Text("Here are your preferences")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10)
            .fixedSize(horizontal: false, vertical: true)
            
            Divider()
                .padding(.horizontal)
                .background(Color.primary.opacity(0.2))
        }
    }
    
    @ViewBuilder
    func preferencesView(mainWindowSize: CGSize) -> some View {
        VStack(spacing: 24) {
            
            // Preferences Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Settings")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                
                GroupedPreferenceRow(preferences: {
                    var preferences: [GroupedPreferenceRow.Preference] = [
                        GroupedPreferenceRow.Preference(
                            icon: "globe",
                            title: "Language",
                            action: {
                                HapticManager.shared.trigger(.lightImpact)
                                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                            }
                        ),
                        //FUTURE
                        //                        GroupedPreferenceRow.Preference(
                        //                            icon: "bell.fill",
                        //                            title: "Custom Reminder",
                        //                            iconColor: .orange,
                        //                            action: {
                        //                                HapticManager.shared.trigger(.lightImpact)
                        //                                Task {
                        ////                                    let currentReminderTime = preferencesViewModel.customReminderTime ?? Date()
                        ////                                    await CentrePopup_CustomReminder(
                        ////                                        reminderTime: .constant(currentReminderTime),
                        ////                                        onSave: { newTime in
                        ////                                            preferencesViewModel.customReminderTime = newTime
                        ////                                            viewModel.scheduleCustomReminderNotification(for: newTime)
                        ////                                        },
                        ////                                        usingLargeText: sizeCategory.isAccessibilityCategory
                        ////                                    ).present()
                        //                                }
                        //                            }
                        //                        )
                        //FUTURE
                        //                        GroupedPreferenceRow.Preference(
                        //                            icon: "arrow.trianglehead.clockwise.icloud.fill",
                        //                            title: "iCloud Sync",
                        //                            toggleValue: $preferencesViewModel.hapticFeedback
                        //                        )
                    ]
                    
                    // Add Haptics for iPhone only
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        preferences.append(
                            GroupedPreferenceRow.Preference(
                                icon: "iphone.homebutton.radiowaves.left.and.right",
                                title: "Haptics",
                                iconColor: .green,
                                toggleValue: $preferencesViewModel.hapticFeedback
                            )
                        )
                    }
                    
                    //                    // Add iPad Column View for iPad only
                    //                    if UIDevice.current.userInterfaceIdiom == .pad {
                    //                        preferences.append(
                    //                            GroupedPreferenceRow.Preference(
                    //                                icon: "text.word.spacing",
                    //                                title: "iPad Column View",
                    //                                iconColor: .purple,
                    //                                toggleValue: $preferencesViewModel.isColumnViewEnabled
                    //                            )
                    //                        )
                    //                    }
                    
                    return preferences
                }(), foregroundColor: .green)
            }
            
            // Preferences Section
            VStack(alignment: .leading, spacing: 8) {
                Text("App")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                
                GroupedPreferenceRow(preferences: {
                    let preferences: [GroupedPreferenceRow.Preference] = [
                        GroupedPreferenceRow.Preference(
                            icon: "star.fill",
                            title: "Review App",
                            iconColor: .yellow,
                            action: {
                                HapticManager.shared.trigger(.lightImpact)
                                requestReview()
                            }
                        ),
                        GroupedPreferenceRow.Preference(
                            icon: "lock.doc",
                            title: "Privacy Policy",
                            iconColor: .pink,
                            action: {
                                HapticManager.shared.trigger(.lightImpact)
                                viewModel.presentPolicy = true
                            }
                        ),
                        GroupedPreferenceRow.Preference(
                            icon: "square.and.arrow.up",
                            title: "Share App",
                            action: {
                                HapticManager.shared.trigger(.lightImpact)
                                shareApp()
                            }
                        ),
                        GroupedPreferenceRow.Preference(
                            icon: "info.circle.fill",
                            title: "About App",
                            iconColor: .indigo,
                            action: {
                                HapticManager.shared.trigger(.lightImpact)
                                Task {
                                    await CentrePopup_AboutApp(usingLargeText: sizeCategory.isAccessibilityCategory)
                                        .present()
                                }
                            }
                        ),
                        GroupedPreferenceRow.Preference(
                            icon: "cart.fill",
                            title: "Purchase Overview",
                            iconColor: .blue,
                            action: {
                                HapticManager.shared.trigger(.lightImpact)
                                viewModel.showPurchasesOverview = true // Toggle sheet presentation
                            }
                        ),
                        GroupedPreferenceRow.Preference(
                            icon: "numbers.rectangle.fill",
                            title: "App Version - \(getAppVersion())",
                            iconColor: .teal,
                            action: {
                                HapticManager.shared.trigger(.lightImpact)
                                do {
                                    try isUpdateAvailable { [self] (update, error) in
                                        if let update {
                                            if update {
                                                DispatchQueue.main.async {
                                                    let toast = ToastValue(
                                                        icon: Image(systemName: "123.rectangle.fill").foregroundStyle(.green),
                                                        message: "Update available!",
                                                        button: ToastButton(title: "Update", color: .green, action: {
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                                UIApplication.shared.open(URL(string: "https://apps.apple.com/us/app/service-maps/id1664309103")!)
                                                            }
                                                        })
                                                    )
                                                    presentToast(toast)
                                                }
                                                
                                            } else {
                                                DispatchQueue.main.async {
                                                    let toast = ToastValue(
                                                        icon: Image(systemName: "123.rectangle.fill").foregroundStyle(.green),
                                                        message: "App is up to date!"
                                                    )
                                                    presentToast(toast)
                                                }
                                            }
                                        }
                                        
                                        if let error {
                                            DispatchQueue.main.async {
                                                let toast = ToastValue(
                                                    icon: Image(systemName: "exclamationmark.warninglight.fill").foregroundStyle(.red),
                                                    message: error.localizedDescription == NSLocalizedString("The operation couldn’t be completed. (NSURLErrorDomain error -1009.)", comment: "") ? "No internet connection" : "Error Checking for Updates"
                                                )
                                                presentToast(toast)
                                            }
                                        }
                                    }
                                } catch {
                                    HapticManager.shared.trigger(.error)
                                    let toast = ToastValue(
                                        icon: Image(systemName: "exclamationmark.warninglight.fill").foregroundStyle(.red),
                                        message:"Error Checking for Updates"
                                    )
                                    presentToast(toast)
                                }
                            }
                        )
                    ]
                    
                    return preferences
                }())
                
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Other")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                
                GroupedPreferenceRow(
                    preferences: {
                        let preferences: [GroupedPreferenceRow.Preference] = [
                            GroupedPreferenceRow.Preference(
                                icon: "folder.fill",
                                title: "Import / Export Data",
                                iconColor: .orange,
                                action: {
                                    HapticManager.shared.trigger(.lightImpact)
                                    Task {
                                        await CentrePopup_ImportExport(
                                            usingLargeText: false,
                                            onImport: {
                                                url,
                                                format in
                                                print("Importing as \(format.uppercased()) from \(url)")
                                                
                                                // Handle Import Logic
                                                Task {
                                                    do {
                                                        if format == "json" {
                                                            await viewModel
                                                                .importDataFromJSON(
                                                                    fileURL: url,
                                                                    modelContext: modelContext
                                                                )
                                                        } else if format == "csv" {
                                                            await viewModel
                                                                .importDataFromCSV(
                                                                    fileURL: url,
                                                                    modelContext: modelContext
                                                                )
                                                        }
                                                    }
                                                }
                                            },
                                            onExport: { url, format in
                                                Task {
                                                    if format == "json" {
                                                        await viewModel
                                                            .exportDataAsJSON(data: gratitudes)
                                                    } else if format == "csv" {
                                                        await viewModel
                                                            .exportDataAsCSV(data: gratitudes)
                                                    }
                                                }
                                            }
                                        ).present()
                                    }
                                }
                            ),
                            GroupedPreferenceRow.Preference(
                                icon: "trash",
                                title: "Delete Data",
                                iconColor: .red,
                                action: {
                                    HapticManager.shared.trigger(.lightImpact)
                                    Task {
                                        await CentrePopup_DeleteAllData(usingLargeText: false) { types in
                                            Task {
                                                await viewModel
                                                    .deleteAllData(
                                                        modelContext: modelContext,
                                                        for: types
                                                    ) // Call your SwiftData deletion logic
                                            }
                                        }
                                        .present()
                                    }
                                }
                            )
                        ]
                        
                        return preferences
                    }())
            }
        }
        .padding()
        .sheet(isPresented: $viewModel.presentPolicy) {
            PrivacyPolicy(sheet: true)
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(30) // Set the corner radius
        }
    }
    
    @ViewBuilder
    private func paywallAdSection() -> some View {
        if PurchaseManager.shared.purchasedProductIdentifiers.isEmpty {
            VStack(spacing: 12) {
                // Ad Title
                Text("Support & Unlock Premium")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.top, 8)

                // Ad Description
                Text("Access advanced features like Spaces and support the development of this app.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                // Unlock Button
                Button(action: {
                    viewModel.showPaywallSheet = true
                }) {
                    Text("Unlock Premium")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                }
                .padding(.horizontal, 16)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.secondarySystemBackground)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
            )
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
    }
}

//MARK: - About App Popup

struct CentrePopup_AboutApp: CenterPopup {
    var usingLargeText: Bool
    
    var body: some View {
        createContent().padding(12)
    }
    
    func createContent() -> some View {
        VStack(spacing: 20) {
            // Title
            Text("About This App")
                .font(.system(size: usingLargeText ? 22 : 18, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // Icon
            Image(systemName: "heart.text.square.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue.opacity(0.8))
                .padding(.bottom, 10)
            
            // Description
            Text("""
            This app is designed to help you cultivate gratitude and prioritize self-care by reflecting on three things you're grateful for every day. We hope it becomes a tool for fostering positivity, mindfulness, and joy in your daily life.
            
            Created with care and love, this app is meant to serve as a reminder of the many blessings in your life, big or small. Thank you for choosing this app to be part of your journey.
            """)
            .font(usingLargeText ? .footnote : .body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .lineSpacing(5)
            
            Button(action: {
                HapticManager.shared.trigger(.lightImpact)
                Task { await  dismissLastPopup() }
            }) {
                Text("Dismiss")
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
            .shadow(color: Color.gray.opacity(0.3), radius: 6, x: 0, y: 4)
        }
        .padding(16)
        .background(Color.secondarySystemBackground)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    func configurePopup(config: CenterPopupConfig) -> CenterPopupConfig {
        config
            .tapOutsideToDismissPopup(true)
    }
}

//MARK: - Edit Name

struct CentrePopup_EditName: CenterPopup {
    @Binding var name: String
    var onSave: (String) -> Void
    var usingLargeText: Bool
    
    @State private var editedName: String
    
    @FocusState private var textfieldFocus: Bool
    
    @Environment(\.mainWindowSize) var mainWindowSize
    @Environment(\.colorScheme) var colorScheme
    
    init(name: Binding<String>, onSave: @escaping (String) -> Void, usingLargeText: Bool) {
        self._name = name
        self.onSave = onSave
        self.usingLargeText = usingLargeText
        self._editedName = State(initialValue: name.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Edit Name")
                .font(.system(size: usingLargeText ? 22 : 18, weight: .bold))
                .foregroundColor(.primary)
            
            // Text Field for Name
            createStyledTextField("Enter your name", text: $editedName)
            
            // Buttons
            HStack(spacing: 12) {
                Button(action: {
                    HapticManager.shared.trigger(.lightImpact)
                    Task { await dismissLastPopup() }
                }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(12)
                        .foregroundColor(.red)
                }
                
                Button(action: {
                    HapticManager.shared.trigger(.success)
                    onSave(editedName)
                    Task { await dismissLastPopup() }
                }) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(12)
                        .foregroundColor(.blue)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(Color.secondarySystemBackground)
        .cornerRadius(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    func configurePopup(config: CenterPopupConfig) -> CenterPopupConfig {
        config
            .tapOutsideToDismissPopup(true)
    }
    
    func createStyledTextField(_ placeholder: String, text: Binding<String>, isMultiline: Bool = false) -> some View {
        Group {
            if isMultiline {
                TextField(placeholder, text: text, axis: .vertical)
                    .lineLimit(3...6)
                    .focused( $textfieldFocus) // Use appropriate field enum
            } else {
                TextField(placeholder, text: text)
                    .focused($textfieldFocus) // Use appropriate field enum
            }
        }
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
        .onTapGesture {
            textfieldFocus = true // Use appropriate field enum
        }
    }
}

//MARK: - Delete Data Popup

struct CentrePopup_DeleteAllData: CenterPopup {
    var usingLargeText: Bool
    var onDeleteConfirmed: ([DataType]) -> Void // Callback for delete confirmation with selected types
    
    @State private var selectedTypes: Set<DataType> = [] // Track selected types
    
    var body: some View {
        createContent().padding(12)
    }
    
    func createContent() -> some View {
        VStack(spacing: 20) {
            // Title
            Text("Confirm Deletion")
                .font(.system(size: usingLargeText ? 22 : 18, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // Icon
            Image(systemName: "trash.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.red.opacity(0.8))
                .padding(.bottom, 10)
            
            // Description
            Text("""
            Choose which data to delete. This action cannot be undone, and all selected entries will be permanently removed.
            """)
            .font(usingLargeText ? .footnote : .body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .lineSpacing(5)
            
            // Checkmark Options
            VStack(spacing: 12) {
                ForEach(DataType.allCases, id: \.self) { type in
                    HStack {
                        Text(type.rawValue)
                            .foregroundColor(.primary)
                            .font(.body)
                        
                        Spacer()
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedTypes.contains(type) ? Color.red.opacity(0.2) : Color.gray.opacity(0.1))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedTypes.contains(type) ? Color.red.opacity(0.8) : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .animation(.easeInOut, value: selectedTypes)
                            
                            if selectedTypes.contains(type) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.red)
                                    .transition(.scale)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleSelection(for: type)
                    }
                    .animation(.spring(), value: selectedTypes)
                    .padding(.horizontal)
                    
                }
            }
            .padding(.vertical, 10)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
            // Confirm Button
            Button(action: {
                HapticManager.shared.trigger(.warning)
                Task {
                    onDeleteConfirmed(Array(selectedTypes))
                    await dismissLastPopup()
                }
            }) {
                Text("Delete Selected Data")
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
            .shadow(color: Color.gray.opacity(0.3), radius: 6, x: 0, y: 4)
            .disabled(selectedTypes.isEmpty) // Disable button if no types selected
            
            // Dismiss Button
            Button(action: {
                HapticManager.shared.trigger(.lightImpact)
                Task { await dismissLastPopup() }
            }) {
                Text("Cancel")
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
            .shadow(color: Color.gray.opacity(0.3), radius: 6, x: 0, y: 4)
        }
        .padding(16)
        .background(Color.secondarySystemBackground)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Toggle selection for a data type
    private func toggleSelection(for type: DataType) {
        if selectedTypes.contains(type) {
            selectedTypes.remove(type)
        } else {
            selectedTypes.insert(type)
        }
    }
    
    func configurePopup(config: CenterPopupConfig) -> CenterPopupConfig {
        config.tapOutsideToDismissPopup(true)
    }
}

// Enum to represent data types
enum DataType: String, CaseIterable {
    case dailyGratitude = "Daily Gratitude"
    case spaceCategory = "Space Category"
    case item = "Item"
}

//MARK: - Import / Export Data Popup

struct CentrePopup_ImportExport: CenterPopup {
    var usingLargeText: Bool
    var onImport: (URL, String) -> Void // Callback for importing
    var onExport: (URL, String) -> Void // Callback for exporting
    
    @Query var gratitudes: [DailyGratitude]
    
    @State private var showDocumentPicker = false
    @State private var documentPickerFormat: String = ""
    @State private var fileURLToExport: URL? = nil
    @State private var showShareSheet = false
    @State private var isProcessingExport = false
    @State private var isProcessingImport = false
    @State private var selectedImportFormat = ""
    @State private var selectedExportFormat = ""
    @State private var errorMessage: String?
    
    var body: some View {
        createContent().padding(12)
    }
    
    func createContent() -> some View {
        VStack(spacing: 20) {
            // Title
            Text("Import / Export")
                .font(.system(size: usingLargeText ? 22 : 18, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // Icon
            Image(systemName: "square.and.arrow.up.on.square.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue.opacity(0.8))
                .padding(.bottom, 10)
            
            if isProcessingImport {
                // Importing View
                VStack(spacing: 16) {
                    ProgressView("Importing...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                    
                    Text("Please wait while your data is being imported.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .font(usingLargeText ? .headline : .body)
                }
                .transition(.opacity)
            }  else {
                // Description
                Text("""
            Choose your preferred file format for importing or exporting your gratitude data. You can select either JSON or CSV.
            """)
                .font(usingLargeText ? .footnote : .body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                
                // Import and Export Options
                VStack(spacing: 16) {
                    // Import Section
                    Text("Import")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 16) {
                        // JSON Import Button
                        Button(action: {
                            importData(format: "json")
                        }) {
                            formatButton(
                                title: "JSON",
                                isProcessing: isProcessingImport && selectedImportFormat == "json",
                                color: .green
                            )
                        }
                        .disabled(isProcessingImport)
                        
                        // CSV Import Button
                        Button(action: {
                            importData(format: "csv")
                        }) {
                            formatButton(
                                title: "CSV",
                                isProcessing: isProcessingImport && selectedImportFormat == "csv",
                                color: .green
                            )
                        }
                        .disabled(isProcessingImport)
                    }
                    
                    // Export Section
                    Text("Export")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 16) {
                        // JSON Export Button
                        Button(action: {
                            exportData(format: "json")
                        }) {
                            formatButton(
                                title: "JSON",
                                isProcessing: isProcessingExport && selectedExportFormat == "json",
                                color: .blue
                            )
                        }
                        .disabled(isProcessingExport)
                        
                        // CSV Export Button
                        Button(action: {
                            exportData(format: "csv")
                        }) {
                            formatButton(
                                title: "CSV",
                                isProcessing: isProcessingExport && selectedExportFormat == "csv",
                                color: .blue
                            )
                        }
                        .disabled(isProcessingExport)
                    }
                }
            }
            // Error Message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            
            // Dismiss Button
            Button(action: {
                HapticManager.shared.trigger(.lightImpact)
                Task { await dismissLastPopup() }
            }) {
                Text("Dismiss")
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
                    .foregroundColor(.primary)
            }
            .buttonStyle(PlainButtonStyle())
            .shadow(color: Color.gray.opacity(0.3), radius: 6, x: 0, y: 4)
        }
        //.animation(.spring(), value: isProcessingImport)
        .padding(16)
        .background(Color.secondarySystemBackground)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(format: documentPickerFormat) { url in
                Task {
                    await MainActor.run { isProcessingImport = true}
                    onImport(url, documentPickerFormat)
                    await MainActor.run {
                        isProcessingImport = false
                        selectedImportFormat = ""
                    }
                    Task { await dismissLastPopup() }
                }
            }
        }
        .onChange(of: showDocumentPicker) { newValue, _ in
            if !newValue {
                // The sheet was dismissed, reset import processing state
                isProcessingImport = false
                selectedImportFormat = ""
            }
        }
    }
    
    func configurePopup(config: CenterPopupConfig) -> CenterPopupConfig {
        config
            .tapOutsideToDismissPopup(true)
    }
    
    @ViewBuilder
    private func formatButton(title: String, isProcessing: Bool, color: Color) -> some View {
        ZStack {
            if isProcessing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: color))
            } else {
                Text(title)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isProcessing ? Color.gray.opacity(0.2) : color.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isProcessing ? Color.gray.opacity(0.5) : color.opacity(0.8), lineWidth: 1)
        )
        .foregroundColor(isProcessing ? .gray : color)
        .animation(.easeInOut, value: isProcessing)
    }
    
    private func exportData(format: String) {
        guard !isProcessingExport else { return }
        selectedExportFormat = format
        isProcessingExport = true
        Task {
            let fileURL = await createFileToExport(format: format)
            await MainActor.run {
                isProcessingExport = false
                selectedExportFormat = ""
                onExport(fileURL, format)
            }
        }
    }
    
    private func importData(format: String) {
        guard !isProcessingImport else { return }
        selectedImportFormat = format
        documentPickerFormat = format
        showDocumentPicker = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isProcessingImport = true
        }
    }
    
    private func createFileToExport(format: String) async -> URL {
        let exportURL = FileManager.default.temporaryDirectory.appendingPathComponent("Gratitudes.\(format)")
        do {
            if format == "json" {
                let data = try JSONEncoder().encode(gratitudes)
                try data.write(to: exportURL)
            } else if format == "csv" {
                let csvString = generateCSV(from: gratitudes)
                try csvString.write(to: exportURL, atomically: true, encoding: .utf8)
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to export data. Please try again."
            }
        }
        return exportURL
    }
    
    func generateCSV(from gratitudes: [DailyGratitude]) -> String {
        var csvString = "id,date,entry1,entry2,entry3,streak,notes\n"
        for gratitude in gratitudes {
            let sanitizedNotes = gratitude.notes
                .replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: ",", with: " ")
            let row = """
            \(gratitude.id.uuidString),\(ISO8601DateFormatter().string(from: gratitude.date)),\(gratitude.entry1),\(gratitude.entry2),\(gratitude.entry3),\(gratitude.streak),\(sanitizedNotes)
            """
            csvString += row + "\n"
        }
        return csvString
    }
}

//MARK: - Preview

#Preview {
    SettingsView()
}
