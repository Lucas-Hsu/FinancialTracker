//
//  CustomModifiers.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 3/22/25.
//

import SwiftUI

struct BlurredBackground: ViewModifier {
    var color: Color
    var opacity: Double
    var blurRadius: CGFloat

    func body(content: Content) -> some View {
        ZStack {
            color
                .opacity(opacity)
                .blur(radius: blurRadius)
                .edgesIgnoringSafeArea(.all)
            content
        }
    }
}

extension View {
    func accentButton(color: Color = .accentColor, opacity: Double = 0.6, blurRadius: CGFloat = 10) -> some View {
        self.background(
            color
                .opacity(opacity)
                .blur(radius: blurRadius)
        )
    }
}

extension View {
    func accentButtonToggled(boolean: Bool = true, color: Color = .accentColor, opacity1: Double = 0.6, blurRadius: CGFloat = 10, material: Material = .thinMaterial, cornerRadius: CGFloat = 10, opacity2: Double = 1) -> some View {
        self.background(
            Group {
                if boolean {
                    color
                        .opacity(opacity1)
                        .blur(radius: blurRadius)
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(material)
                        .blur(radius: blurRadius)
                        .opacity(opacity2)
                }
            }
        )
    }
}

extension View {
    func scaleEffectToggled(boolean: Bool = true, scaleEffect: CGFloat = 1.2) -> some View {
        if boolean {
            self.scaleEffect(scaleEffect)
        } else {
            self.scaleEffect(1)
        }
    }
}
    

extension View {
    func plainFill(material: Material = .thinMaterial, opacity: Double = 1, cornerRadius: CGFloat = 10, blurRadius: CGFloat = 4) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(material)
                .blur(radius: blurRadius)
                .opacity(opacity)
        )
    }
}

extension View {
    func clearBackground() -> some View {
        self.listRowBackground(Color.clear)
            .scrollContentBackground(.hidden)
    }
}

extension View {
    func colorfulAccentBackground(colors: [Color]) -> some View {
        self.background {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: colors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                RadialGradient(
                    gradient: Gradient(colors: [.accentColor, .white, .accentColor, .white]),
                    center: .bottom,
                    startRadius: 0,
                    endRadius: 1000
                ).opacity(0.4)
            }
            .edgesIgnoringSafeArea(.all)
            .blur(radius: 10)
        }
    }
}
    
