//
//  MorphingToggleGlass.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/22/25.
//

import SwiftUI

struct MorphingToggleButtonGlass: View
{
    // MARK: - Private Attributes
    @Namespace private var glassNamespace
    
    // MARK: - Attributes
    @Binding var toggle: Bool
    let onText: String
    let offText: String

    // MARK: - UI
    var body: some View
    {
        if #available(iOS 26.0, *)
        {
            GlassEffectContainer
            {
                Button(action:
                {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8))
                    { toggle.toggle() }
                })
                {
                    HStack
                    {
                        Image(systemName: toggle ? "checkmark.circle.fill" : "circle")
                        .contentTransition(.symbolEffect(.replace))
                        Text(toggle ? onText : offText)
                        .fontWeight(.semibold)
                        .contentTransition(.numericText())
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .foregroundStyle(toggle ? .green : .gray)
                }
                .glassEffect(.regular.tint(toggle ? .green.opacity(0.15) : .gray.opacity(0.15)).interactive(), in: .capsule)
                .glassEffectID("morphingToggleButton", in: glassNamespace)
            }
        }
        else
        { Toggle("togglee", isOn: $toggle) }
    }
}
