//
//  OCRBubble.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/21/25.
//

import SwiftUI

struct OCRBubble: View, Identifiable
{
    // MARK: - Attributes
    let id: UUID
    let text: String
    let rect: CGRect // Normalized
    
    // MARK: - Constructor
    init(id: UUID = UUID(), text: String, rect: CGRect)
    {
        self.id = id
        self.text = text
        self.rect = rect
    }
    
    // MARK: - UI
    var body: some View
    {
        Text(text)
        .font(.system(size: 12, weight: .medium))
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .onTapGesture
        {
            print("OCRBubble tapped: \(text)")
            NotificationCenter.default.post(name: .ocrBubbleTapped, object: text)
        }
    }
}

struct OCRBubbleGlass: View, Identifiable
{
    // MARK: - Attributes
    let id = UUID()
    let text: String
    let rect: CGRect
    
    // MARK: - UI
    var body: some View
    {
        OCRBubble(id: self.id, text: self.text, rect: self.rect)
        .background(defaultPanelBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
            .stroke(Color(UIColor.systemBackground), lineWidth: 1.5)
        )
        .interactive()
    }
}
