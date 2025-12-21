//
//  Colors.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/21/25.
//

import SwiftUI

let defaultPanelBackgroundColor: Color = Color(UIColor.systemBackground).mix(with: Color.accentColor, by: 0.02)
let defaultPanelShadowColor: Color = Color(hue: 0.58, saturation: 0.5, brightness: 0.5, opacity: 0.1)
let defaultButtonShadowColor: Color = Color(hue: 0.58, saturation: 0.5, brightness: 0.1, opacity: 0.4)

enum DynamicColors
{
    static let red = dynamic(light: UIColor.red.mix(with: UIColor.white, by: 0.2), dark: UIColor.red.mix(with: UIColor.gray, by: 0.3).mix(with: UIColor.blue, by: 0.1))
    
    static func accent(_ accentColor: Color) -> Color
    {
        return dynamic(light: UIColor(accentColor).mix(with: UIColor.white, by: 0.2), dark: UIColor(accentColor).mix(with: UIColor.gray, by: 0.1).mix(with: UIColor.red, by: 0.1))
    }
    
    private static func dynamic(light: UIColor, dark: UIColor) -> Color
    {
        Color(UIColor
        { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}
