//
//  GenerateImageThumbnail.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/16/24.
//

import PDFKit
import AVKit
import WebKit

func generateThumbnail(for url: URL) -> UIImage? {
    guard let iCloudURL = ICloudManager.shared.getICloudDirectory()?.appendingPathComponent(url.lastPathComponent) else {
        print("Failed to locate iCloud directory.")
        return nil
    }
    
    let fileExtension = iCloudURL.pathExtension.lowercased()
    
    do {
        switch fileExtension {
        case "pdf":
            return generatePDFThumbnail(url: iCloudURL)
        
        case "jpg", "jpeg", "png", "gif", "heic", "webp":
            return generateImageThumbnail(url: iCloudURL)
        
        case "mov", "mp4", "avi", "m4v", "mpg", "mpeg", "m4p", "webm":
            return generateVideoThumbnail(url: iCloudURL)
        
        case "doc", "docx", "xls", "xlsx", "ppt", "pptx":
            return generateOfficeThumbnail(url: iCloudURL)
        
        default:
            return nil
        }
    }
}

private func generatePDFThumbnail(url: URL) -> UIImage? {
    guard let doc = PDFDocument(url: url),
          let page = doc.page(at: 0) else {
        return nil
    }
    return page.thumbnail(of: CGSize(width: 300, height: 300), for: .cropBox)
}

private func generateImageThumbnail(url: URL) -> UIImage? {
    guard let image = UIImage(contentsOfFile: url.path) else {
        return nil
    }
    
    let THUMB_WIDTH = 150.0
    let THUMB_HEIGHT = THUMB_WIDTH - 23.0
    
    return resizeImage(
        image: image,
        constraintSize: CGSize(width: THUMB_WIDTH, height: THUMB_HEIGHT)
    )
}

private func generateVideoThumbnail(url: URL) -> UIImage? {
    let asset = AVAsset(url: url)
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    
    let time = CMTime(seconds: 2, preferredTimescale: 1)
    
    do {
        let imageRef = try imageGenerator.copyCGImage(at: time, actualTime: nil)
        return UIImage(cgImage: imageRef)
    } catch {
        print("Error generating video thumbnail: \(error)")
        return nil
    }
}

private func generateOfficeThumbnail(url: URL) -> UIImage? {
    // For now, return nil or a default icon
    return nil
}

private func resizeImage(image: UIImage, constraintSize: CGSize) -> UIImage {
    let aspectWidth = constraintSize.width / image.size.width
    let aspectHeight = constraintSize.height / image.size.height
    let aspectRatio = min(aspectWidth, aspectHeight)
    
    let newSize = CGSize(
        width: image.size.width * aspectRatio,
        height: image.size.height * aspectRatio
    )
    
    UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
    image.draw(in: CGRect(origin: .zero, size: newSize))
    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return resizedImage ?? image
}

