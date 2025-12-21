//
//  ReceiptImagePickerViewModel.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/21/25.
//

import SwiftUI
import PhotosUI

/// Manage selecting images from a picker
@Observable
final class ReceiptImagePickerViewModel
{
    // MARK: - Observable Attributes
    var selectedItem: PhotosPickerItem? = nil
    
    // MARK: - Public Methods
    @MainActor
    func loadTransferable(from item: PhotosPickerItem?, completion: @escaping (UIImage?) -> Void)
    {
        guard let item = item else
        { return }
        Task
        {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data)
            { completion(uiImage) }
            else
            {
                print("[ERROR] Failed to load image from picker")
                completion(nil)
            }
        }
    }
}
