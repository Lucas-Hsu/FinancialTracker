//
//  ImagePicker.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 2/2/25.
//

import SwiftUI

/// A class that handles choosing images, from either camera or photo library.
/// This class passes the selected image back through the binding variable.
///
struct ImagePicker: UIViewControllerRepresentable
{
    @Environment(\.presentationMode) private var presentationMode
    @Binding private var selectedImage: UIImage
    private var sourceType: UIImagePickerController.SourceType
    
    init(selectedImage: Binding<UIImage>,
         sourceType: UIImagePickerController.SourceType = .photoLibrary)
    {
        _selectedImage = selectedImage
        self.sourceType = sourceType
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate
    {
        var parent: ImagePicker

        init(_ parent: ImagePicker)
        { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
        {
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
            { parent.selectedImage = image }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator
    { return Coordinator(self) }

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController
    {
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator
        return imagePicker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController,
                                context: UIViewControllerRepresentableContext<ImagePicker>)
    { /* Definition needed to conform to protocol UIViewControllerRepresentable */ }
}
