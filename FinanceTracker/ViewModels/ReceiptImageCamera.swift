//
//  ReceiptImageCamera.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/21/25.
//

import SwiftUI
import UIKit

/// Wrapper for `UIImagePickerController` to support using the Camera
struct ReceiptImageCamera: UIViewControllerRepresentable
{
    // MARK: - Attributes
    var sourceType: UIImagePickerController.SourceType = .camera
    var onImagePicked: (UIImage) -> Void
    
    // MARK: - Private Attributes
    @Environment(\.dismiss) private var dismiss

    // MARK: - Public Methods
    // Create a picker controller
    func makeUIViewController(context: Context) -> UIImagePickerController
    {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }
    // Required for protocol
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context)
    { return }
    // Makes a Coordinator object of the Image Coordinator class
    func makeCoordinator() -> Coordinator
    { Coordinator(parent: self) }

    // MARK: - Image Coordinator
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate
    {
        // MARK: Attributes
        let parent: ReceiptImageCamera
        // MARK: Constructors
        init(parent: ReceiptImageCamera)
        {
            self.parent = parent
        }
        // MARK: Public Methods
        // Controlling the picking of the image
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
        {
            if let image = info[.originalImage] as? UIImage
            {
                parent.onImagePicked(image)
            }
            parent.dismiss()
        }
        // Dismissing the picker
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
        {
            parent.dismiss()
        }
    }
}
