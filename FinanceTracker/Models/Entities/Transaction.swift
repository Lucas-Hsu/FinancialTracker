//
//  Transaction.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 2/1/25.
//

import Foundation
import SwiftData

/// The `Transaction` class stores information about individual units of expenses.
@Model class Transaction: Equatable
{
    @Attribute(.unique) private(set) var id: UUID
    private(set) var date: Date
    private(set) var name: String
    private(set) var price: Double
    private(set) var tag: Tag
    private(set) var isPaid: Bool
    private(set) var notes: [String]?
    private(set) var receiptImage: Data?
    
    init(date: Date = Date(),
         name: String = "",
         price: Double = 9.9,
         tag: Tag = Tag.other,
         isPaid: Bool = true,
         notes: [String]? = nil,
         receiptImage: Data? = nil)
    {
        self.id = UUID()
        self.date = date
        self.name = name
        self.tag = tag
        self.price = price
        self.isPaid = isPaid
        self.notes = notes
        self.receiptImage = receiptImage
    }
    
    // Mutators
    public func setDate(date: Date)
    { self.date = date }
    public func setName(name: String)
    { self.name = name }
    public func setPrice(price: Double)
    { self.price = price }
    public func setTag(tag: Tag)
    { self.tag = tag }
    public func setIsPaid(isPaid: Bool)
    { self.isPaid = isPaid }
    public func setNotes(notes: [String]?)
    { self.notes = notes }
    public func setReceiptImage(receiptImage: Data?)
    { self.receiptImage = receiptImage }
    
    public func setId(id: UUID)
    { self.id = id }
    
    // Accessors are not needed because private(set) means read-only when outside of this class.
    
    /// `matchesFilter` checks if the the Transaction matches provided filter criteria.
    public func matchesFilter(notIsPaid: Bool = false,
                              selectedTags: Set<Tag>? = nil,
                              dateRangeBegin: Date? = nil,
                              dateRangeEnd: Date? = nil) -> Bool
    {
        // filter for self.isPaid is false
        if (notIsPaid && self.isPaid)                                           { return false }
        // filter for self.tag included in selectedTags
        if let tags = selectedTags, !tags.contains(self.tag)                    { return false }
        // filter for self.date newer or equals to dateRangeBegin
        if let dateRangeBegin = dateRangeBegin, dateRangeBegin > self.date      { return false }
        // filter for self.date older or equals to dateRangeEnd
        if let dateRangeEnd = dateRangeEnd, dateRangeEnd < self.date            { return false }
        return true
    }

    public func getTransactionGroupHeader() -> TransactionGroupHeader
    { return TransactionGroupHeader(name: self.name, price: self.price, tag: self.tag)   }
    
    public func toString() -> String
    {
        return
            """
            [Transaction Object]
            id: \(self.id)
            name: \(self.name)
            tag: \(self.tag)
            date: \(self.date)
            price: ¥\(self.price)
            isPaid: \(self.isPaid)
            notes: \(self.notes?.count ?? 0) lines
            receiptImage: \(self.receiptImage?.count ?? 0) bytes
            """
    }
    
    static func == (lhs: Transaction, rhs: Transaction) -> Bool
    {
        Date.minuteEquals(date1: lhs.date, date2: rhs.date) &&
        lhs.name == rhs.name &&
        lhs.tag == rhs.tag &&
        lhs.price == rhs.price &&
        lhs.isPaid == rhs.isPaid &&
        lhs.notes == rhs.notes &&
        lhs.receiptImage == rhs.receiptImage
    }
}
