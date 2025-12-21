//
//  FloatingButton.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/21/25.
//

import SwiftUI

struct FloatingButton: View
{
    let icon: String
    var color: Color = .accentColor
    var action: () -> Void
    
    var body: some View
    {
        Image(systemName: icon)
        .font(.title3)
        .foregroundColor(.white)
        .frame(width: 44, height: 44)
        .background(color)
        .clipShape(Circle())
        .shadow(radius: 4)
        .onTapGesture
        { action() }
    }
}

struct FloatingButtonGlass: View
{
    let icon: String
    var color: Color = .accentColor
    var action: () -> Void
    
    var body: some View
    {
        if #available(iOS 26.0, *)
        {
            FloatingButton(icon: self.icon, color: self.color, action: self.action)
            .background(.clear)
            .glassEffect(.regular.tint(color).interactive())
        }
        else
        {
            FloatingButton(icon: self.icon, color: self.color, action: self.action)
        }
    }
}
