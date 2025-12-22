//
//  GrayBox.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/22/25.
//

import SwiftUI

struct GrayBox: View
{
    let text: String
    
    init(text: String = "")
    {
        self.text = text
    }
    
    var body: some View
    {
        Text(text)
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color.primary.opacity(0.05))
        .cornerRadius(12)
    }
}
