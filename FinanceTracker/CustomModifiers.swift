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
    func plainFill(material: Material = .thinMaterial, opacity: Double = 0.9, cornerRadius: CGFloat = 10, blurRadius: CGFloat = 4) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(material)
                .blur(radius: blurRadius)
                .opacity(opacity)
        )
    }
}

extension View {
    func colorFill(material: Material = .thinMaterial, opacity: Double = 0.9, cornerRadius: CGFloat = 10, blurRadius: CGFloat = 4) -> some View {
        self.background {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.clear, lineWidth: 0)
                .background(.yellow)
                .blur(radius: 2)
        }
    }
}
    

extension View {
    func clearBackground() -> some View {
        self.listRowBackground(Color.clear)
            .scrollContentBackground(.hidden)
    }
}

extension View {
    func colorfulAccentBackground(colorLinear: [Color] = [.white, .white], colorRadial: [Color] = [.accentColor, .white]) -> some View {
        self.background {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: colorLinear),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                RadialGradient(
                    gradient: Gradient(colors: colorRadial),
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
    

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.2 : 1)
    }
}

struct GlassmorphismToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
            HStack {
                configuration.label // The label that is part of the toggle
                
                Spacer()
                
                ZStack {
                    // Background circle for toggle button
                    RoundedRectangle(cornerRadius: 20)
                        .fill(configuration.isOn ? Color.accentColor.opacity(0.2) : Color.primary.opacity(0.2))
                        .frame(width: 50, height: 30) // Elongated rounded rectangle
                        .blur(radius: 2)
                                        
                    
                    // Circle that moves with the toggle
                    Circle()

                        .fill(.white)
                        .frame(width: 24, height: 24)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.4), value: configuration.isOn)
                        .shadow(color: configuration.isOn ? Color.accentColor : Color.secondary, radius: 2)
                        .blur(radius: 1)
                }.padding(.trailing, 10)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            }
    }
}

struct CustomSegmentedEnumControl<EnumType: RawRepresentable & Hashable>: View where EnumType.RawValue == String {
    let segments: [EnumType] // Array of enum values
    @Binding var selected: EnumType // Selected segment as enum
    var highlightColor: Color = .blue
    var backgroundColor: Color = .gray.opacity(0.2)

    var body: some View {
        HStack(spacing: 0) {
            ForEach(segments, id: \.self) { segment in
                Button(action: {
                    withAnimation {
                        selected = segment // Update the selected segment directly
                    }
                }) {
                    Text(segment.rawValue) // Display the raw value of the enum
                        .frame(maxWidth: .infinity, maxHeight: 6)
                        .padding()
                        .background(
                            selected == segment ? highlightColor : backgroundColor
                        )
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
    }
}

struct CustomModifier_Previews: PreviewProvider {
    static var previews: some View {
        AddNew()
    }
}
