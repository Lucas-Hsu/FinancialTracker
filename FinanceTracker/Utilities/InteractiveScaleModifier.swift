//
//  InteractiveScaleModifier.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/22/25.
//

import SwiftUI

struct InteractiveScaleModifier: ViewModifier
{
    let scaleAmount: CGFloat
    @State private var isPressed: Bool = false
    
    func body(content: Content) -> some View
    {
        content
        .scaleEffect(isPressed ? scaleAmount : 1.0)
        .brightness(isPressed ? 0.4 : 0.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
            .onChanged
            { _ in
                if !self.isPressed
                {
                    self.isPressed = true
                }
            }
            .onEnded
            { _ in
                self.isPressed = false
            }
        )
    }
}

extension View
{
    // Tap animations like the Liquid Glass .interactive()
    func interactive(scale: CGFloat = 1.1) -> some View
    {
        self.modifier(InteractiveScaleModifier(scaleAmount: scale))
    }
}
