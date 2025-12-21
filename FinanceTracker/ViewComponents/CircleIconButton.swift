//
//  CircleIconButton.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/17/25.
//

import SwiftUI

// MARK: - Primitive Shapes
struct CircleIconButton: View
{
    let icon: String
    var action: () -> Void
    var body: some View
    {
        Button(action: self.action)
        {
            Image(systemName: self.icon)
            .font(.title3)
            .foregroundColor(.accentColor)
            .frame(width: 36, height: 36)
            .background(defaultPanelBackgroundColor)
            .clipShape(Circle())
        }
    }
}

// MARK: - Liquid Glass Themed
struct CircleIconButtonGlass: View
{
    let icon: String
    var shadow: Bool = false
    var action: () -> Void
    var body: some View
    {
        if #available(iOS 26.0, *)
        {
            if shadow
            {
                CircleIconButton(icon: self.icon, action: self.action)
                    .glassEffect(.regular.interactive())
                    .shadow(color: defaultPanelShadowColor, radius: 2, x: 0, y: 4)
            }
            else
            {
                CircleIconButton(icon: self.icon, action: self.action)
                    .glassEffect(.regular.interactive())
            }
        }
        else
        { CircleIconButton(icon: self.icon, action: self.action) }
    }
}
