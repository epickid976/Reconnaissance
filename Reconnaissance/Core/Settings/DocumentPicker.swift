//
//  DocumentPicker.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/13/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    var format: String // File format (e.g., "json" or "csv")
    var onDocumentPicked: (URL) -> Void // Callback for selected document

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let supportedTypes: [UTType]
        switch format {
        case "json":
            supportedTypes = [UTType.json]
        case "csv":
            supportedTypes = [UTType.commaSeparatedText]
        default:
            supportedTypes = [UTType.data]
        }

        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false // Only one file at a time
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(onDocumentPicked: onDocumentPicked)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onDocumentPicked: (URL) -> Void

        init(onDocumentPicked: @escaping (URL) -> Void) {
            self.onDocumentPicked = onDocumentPicked
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let selectedFileURL = urls.first else { return }
            onDocumentPicked(selectedFileURL)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("Document picker was cancelled")
        }
    }
}
