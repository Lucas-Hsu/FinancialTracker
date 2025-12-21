//
//  CircleIconToggleButton.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/19/25.
//

import SwiftUI

// MARK: - Primitive Shapes
struct CircleIconToggleButton: View
{
    let icon: String
    var toggle: Bool
    var action: () -> Void
    var body: some View
    {
        Button(action: self.action)
        {
            Image(systemName: self.icon)
            .font(.title3)
            .foregroundColor(toggle ? .accentColor : Color(UIColor.systemBackground))
            .frame(width: 36, height: 36)
            .background(defaultPanelBackgroundColor)
            .clipShape(Circle())
        }
    }
}

// MARK: - Liquid Glass Themed
struct CircleIconToggleButtonGlass: View
{
    let icon: String
    let shadow: Bool = false
    var toggle: Bool = false
    var action: () -> Void
    var body: some View
    {
        if #available(iOS 26.0, *)
        {
            if shadow
            {
                CircleIconToggleButton(icon: self.icon, toggle: self.toggle, action: self.action)
                .glassEffect(.regular.interactive())
                .shadow(color: defaultPanelShadowColor, radius: 2, x: 0, y: 4)
            }
            else
            {
                CircleIconToggleButton(icon: self.icon, toggle: self.toggle, action: self.action)
                .glassEffect(.regular.interactive())
            }
        }
        else
        { CircleIconToggleButton(icon: self.icon, toggle: self.toggle, action: self.action) }
    }
}
