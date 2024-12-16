//
//  ItemDocumentPicker.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/16/24.
//

import SwiftUI
import PhotosUI
import UIKit
import UniformTypeIdentifiers
// MARK: - Document Picker

struct ItemDocumentPicker: UIViewControllerRepresentable {
    @Binding var fileURL: URL?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Specify the allowed file types
        
        let allowedTypes: [UTType] = [
            .image,        // Images (e.g., png, jpg, etc.)
            .pdf,          // PDFs
            .plainText,    // Plain text files
            .rtf,          // Rich text files
            .content,
            .spreadsheet   // Spreadsheets (e.g., Excel)
        ]
        
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedTypes, asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: ItemDocumentPicker

        init(_ parent: ItemDocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.fileURL = urls.first
        }
    }
}

// MARK: - DocumentDelegate
final class DocumentInteractionDelegate: NSObject, UIDocumentInteractionControllerDelegate, Sendable {
    static let shared = DocumentInteractionDelegate()
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        // Try to get the root view controller safely
        if let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController {
            return rootVC
        }

        // Fallback: return a dummy UIViewController to prevent crashes
        let fallbackVC = UIViewController()
        fallbackVC.view.backgroundColor = .clear // Make it invisible
        return fallbackVC
    }
}
