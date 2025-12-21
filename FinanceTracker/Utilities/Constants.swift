//
//  Constants.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/10/25.
//

import Foundation
import SwiftUI

let tagSymbols: [Tag: String] = [Tag.clothing: "tshirt.fill",
                                 Tag.commute: "car.fill",
                                 Tag.education: "books.vertical.fill",
                                 Tag.entertainment: "popcorn.fill",
                                 Tag.food: "fork.knife",
                                 Tag.other: "ellipsis"]

let defaultPanelBackgroundColor: Color = Color(UIColor.systemBackground).mix(with: .accentColor, by: 0.02)
let defaultPanelShadowColor: Color = Color(hue: 0.58, saturation: 0.5, brightness: 0.5, opacity: 0.1)
