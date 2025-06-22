//
//  Tag.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 2/1/25.
//

enum Tag: String, CaseIterable, Identifiable
{
    var id: String { self.rawValue }
    case clothing,
         commute,
         education,
         entertainment,
         food,
         other
}

let tagSymbol = [Tag.clothing: "tshirt.fill",
                 Tag.commute: "car.fill",
                 Tag.education: "books.vertical.fill",
                 Tag.entertainment: "popcorn.fill",
                 Tag.food: "fork.knife",
                 Tag.other: "ellipsis"]
