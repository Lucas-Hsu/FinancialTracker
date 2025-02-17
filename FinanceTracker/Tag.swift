//
//  Tag.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 2/1/25.
//

// Define the Enum for the Tag
enum Tag: String, CaseIterable {
    case food, clothing, entertainment, commute, education, other
}

let symbolRepresentation = [Tag.clothing: "tshirt.fill",
                            Tag.commute: "car.fill",
                            Tag.education: "books.vertical.fill",
                            Tag.entertainment: "popcorn.fill",
                            Tag.food: "fork.knife",
                            Tag.other: "ellipsis"
                           ]
