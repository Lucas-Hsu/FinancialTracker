//
//  ReceiptImageViewModel.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/21/25.
//

import SwiftUI
import Vision
import UIKit

/// Manage OCR and saving of receipt image
@Observable
final class ReceiptImageViewModel
{
    // MARK: - Observable
    // Attributes
    var uiImage: UIImage? = nil
    var ocrBubbles: [OCRBubbleGlass] = []
    var isProcessing: Bool = false
    // Transform
    var scale: CGFloat = 1.0
    var lastScale: CGFloat = 1.0
    var offset: CGSize = .zero
    var lastOffset: CGSize = .zero
    
    // MARK: - Public Methods
    // Set an image to perform OCR on
    func setImage(_ image: UIImage?)
    {
        guard let image = image else { return }
        // Fix orientation so Vision and UI coords match
        self.uiImage = fixOrientation(img: image)
        self.resetTransformations()
        self.performOCR()
    }
    // Clear image
    func clear()
    {
        self.uiImage = nil
        self.ocrBubbles = []
        self.resetTransformations()
    }
    // Reset image transform
    func resetTransformations()
    {
        self.scale = 1.0
        self.lastScale = 1.0
        self.offset = .zero
        self.lastOffset = .zero
    }
    
    // MARK: - Image Processing (Save Logic)
    // Compresses image to JPEG approx 24kb.
    func getCompressedData() -> Data?
    {
        guard let image = uiImage else
        { return nil }
        let targetSizeBytes = 24 * 1024
        var bestData: Data? = nil
        var smallestSizeFound = Int.max
        // (Max Dimension, JPEG Quality)
        let compressionSteps: [(CGFloat, CGFloat)] = [(1000, 0.5),
                                                      (900,  0.4),
                                                      (800,  0.4),
                                                      (700,  0.3),
                                                      (600,  0.3),
                                                      (500,  0.2),
                                                      (400,  0.2),
                                                      (300,  0.2),
                                                      (200,  0.1)]
        for (index, (dim, qual)) in compressionSteps.enumerated()
        {
            let resized = resizeImage(image: image, targetSize: CGSize(width: dim, height: dim))
            if let data = resized.jpegData(compressionQuality: qual)
            {
                let size = data.count
                print("Attempt \(index + 1): Dim \(Int(dim))px, Q \(qual) -> \(size) bytes")
                if size < smallestSizeFound
                {
                    smallestSizeFound = size
                    bestData = data
                }
                if size <= targetSizeBytes
                {
                    print("Success: Compressed to \(size) bytes.")
                    return data
                }
            }
        }
        print("Best effort compression result: \(smallestSizeFound) bytes.")
        return bestData
    }
    
    // MARK: - Private Helpers
    // Resize an image (for compression)
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage
    {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        var newSize: CGSize
        if(widthRatio > heightRatio)
        { newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio) }
        else
        { newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio) }
        if size.width <= targetSize.width && size.height <= targetSize.height
        { return image }
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? image
    }
    // OCR
    private func performOCR()
    {
        guard let cgImage = uiImage?.cgImage else
        { return }
        self.isProcessing = true
        self.ocrBubbles = []
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest
        { [weak self] request, error in
            guard let self = self else
            { return }
            if let error = error
            {
                print("[ERROR] OCR Failed: \(error)")
                DispatchQueue.main.async { self.isProcessing = false }
                return
            }
            guard let observations = request.results as? [VNRecognizedTextObservation] else
            { return }
            var newBubbles: [OCRBubbleGlass] = []
            for observation in observations
            {
                guard let topCandidate = observation.topCandidates(1).first else
                { continue }
                newBubbles.append(OCRBubbleGlass(text: topCandidate.string, rect: observation.boundingBox))
            }
            DispatchQueue.main.async
            {
                self.ocrBubbles = newBubbles
                self.isProcessing = false
            }
        }
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["zh-CN", "en-US"]
        Task.detached(priority: .userInitiated)
        {
            do
            { try requestHandler.perform([request]) }
            catch
            {
                print("[ERROR] Failed to perform OCR request: \(error)")
                await MainActor.run { self.isProcessing = false }
            }
        }
    }
    // Orient Image Upright
    private func fixOrientation(img: UIImage) -> UIImage
    {
        if img.imageOrientation == .up
        { return img }
        UIGraphicsBeginImageContextWithOptions(img.size, false, img.scale)
        img.draw(in: CGRect(origin: .zero, size: img.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage ?? img
    }
}
