//
//  TransactionGroupHeader.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/10/25.
//

import Foundation

/// The `TransactionGroupHeader` struct allows easier comparison and sorting for Transaction objects
struct TransactionGroupHeader: Codable, Equatable, Hashable
{
    var name: String
    var price: Double
    var tagString: String

    init(name: String,
         price: Double,
         tag: Tag)
    {
        self.name = name
        self.price = price
        self.tagString = tag.rawValue
    }
}
