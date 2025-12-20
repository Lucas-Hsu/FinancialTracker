//
//  IconToggleButton.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/19/25.
//

import SwiftUI

// MARK: - Primitive Shapes
struct IconToggleButton: View
{
    let icon: String
    var toggle: Bool
    var action: () -> Void
    var body: some View
    {
        Image(systemName: self.icon)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground).mix(with: .accentColor, by: 0.02))
        .font(.title3)
        .foregroundColor(toggle ? .accentColor : .secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture
        {
            self.action()
        }
    }
}

// MARK: - Liquid Glass Themed
struct IconToggleButtonGlass: View
{
    let icon: String
    var shadow: Bool = false
    var toggle: Bool = false
    var action: () -> Void
    var body: some View
    {
        if #available(iOS 26.0, *)
        {
            IconToggleButton(icon: self.icon, toggle: self.toggle, action: self.action)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
            .shadow(color: Color(hue: 0.58, saturation: 0.5, brightness: 0.5, opacity: shadow ? 0.1 : 0), radius: 2, x: 0, y: 4)
        }
        else
        { IconToggleButton(icon: self.icon, toggle: self.toggle, action: self.action) }
    }
}
