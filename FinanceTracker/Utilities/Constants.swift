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

func tagColors(_ tag: Tag) -> Color
{
    switch tag
    {
    case .clothing:
        return .purple.mix(with: .white, by: 0.25)
    case .commute:
        return .green
    case .education:
        return .blue
    case .entertainment:
        return DynamicColors.red
    case .food:
        return .orange
    case .other:
        return Color(UIColor.systemGray).mix(with: .white, by: 0.25)
    }
}
