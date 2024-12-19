//
//  PrivacyPolicyView.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/13/24.
//

import SwiftUI
import WebKit

// MARK: - PrivacyPolicy
struct PrivacyPolicy: View {
    
    // MARK: - Properties
    var sheet: Bool
    
    @State private var progress: CGFloat = 0.0
    
    // MARK: - Environment
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Header
            if !sheet {
                HStack {
                    Button(action: {
                        HapticManager.shared.trigger(.lightImpact)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.blue)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                            )
                    }
                    .padding(.leading, 16)
                    
                    Spacer()
                    
                    Text("Privacy Policy")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Spacer() // Placeholder for symmetry
                }
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            // WebView
            WebView(url: URL(string: "https://servicemaps.ejvapps.online/privacy")!)
                .cornerRadius(sheet ? 20 : 0)
                .padding(sheet ? 16 : 0)
                .overlay(
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .padding(.horizontal, 16)
                        .opacity(progress < 1.0 ? 1.0 : 0.0),
                    alignment: .top
                )

            // Footer Dismiss Button
            if sheet {
                Button(action: {
                    HapticManager.shared.trigger(.lightImpact)
                    presentationMode.wrappedValue.dismiss()
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
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .navigationBarTitleDisplayMode(sheet ? .inline : .large)
        .background(Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all))
        
    }
}

// MARK: - WebView Component
struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.updateProgress(webView.estimatedProgress)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.updateProgress(1.0)
        }
    }
    
    func updateProgress(_ progress: Double) {
        DispatchQueue.main.async {
            // Update progress value if needed
        }
    }
}
