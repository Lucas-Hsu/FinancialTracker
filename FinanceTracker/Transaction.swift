//
//  Transaction.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 2/1/25.
//

import SwiftData
import Foundation

// Define the Transaction model as a class
@Model class Transaction{
    @Attribute(.unique) var id: UUID   // Unique identifier
    var date: Date
    var name: String
    var tag: String // Storing Enum as String
    var price: Double
    var paid: Bool
    var notes: [String]?  // Optional list of strings
    var image: Data? // Optional image as Data
    
    // Provide a custom initializer
    init(date: Date, name: String, tag: String, price: Double, paid: Bool, notes: [String]? = nil, image: Data? = nil) {
        self.id = UUID()
        self.date = date
        self.name = name
        self.tag = tag
        self.price = price
        self.paid = paid
        self.notes = notes
        self.image = image
    }
    
    init() {
        self.id = UUID()
        self.date = Date()
        self.name = "Transaction"
        self.tag = Tag.other.rawValue
        self.price = 64.00
        self.paid = true
        self.notes = nil
        self.image = nil
    }
    
    init(date: Date) {
        self.id = UUID()
        self.date = date
        self.name = "Transaction"
        self.tag = Tag.other.rawValue
        self.price = 64.00
        self.paid = true
        self.notes = nil
        self.image = nil
    }
    
    
    
    public func matchesFilter (tags: Set<String>, isUnpaid: Bool) -> Bool {
        if (!tags.contains(self.tag)) {
            return false
        }
        if (isUnpaid && self.paid == true) {
            return false
        }
        return true
    }
    
    public func toString() -> String {
        return "\(self.name), \(self.price), \(self.date)"
    }

}
