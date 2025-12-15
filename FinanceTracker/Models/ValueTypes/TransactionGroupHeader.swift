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
    var tagString: String

    init(name: String,
         tag: Tag)
    {
        self.name = name
        self.tagString = tag.rawValue
    }
}
