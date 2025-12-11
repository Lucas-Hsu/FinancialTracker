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
    { // Ensure Date is not in the future.
        if date > Date()
        {
            self.date = Date()
            self.notes?.append("Warning: \(date.toMediumString())) is in the future. Set as  \(self.date.toMediumString()).")
        }
        else
        { self.date = date }
    }
    public func setName(name: String)
    { self.name = name }
    public func setPrice(price: Double)
    { // Ensure Price is not negative
        if price < 0
        {
            self.price = abs(price)
            self.notes?.append("Warning: \(price) is negative. Set as absolute value.")
        }
        else
        { self.price = price }
    }
    public func setTag(tag: Tag)
    { self.tag = tag }
    public func setIsPaid(isPaid: Bool)
    { self.isPaid = isPaid }
    public func setNotes(notes: [String]?)
    { self.notes = notes }
    public func setReceiptImage(receiptImage: Data?) // [TODO] Might want to limit filesize
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


/// For serializing `Transaction` into JSON when exporting.
struct TransactionCodable: Codable, Identifiable
{
    var id: UUID
    var date: Date
    var name: String
    var price: Double
    var tag: Tag
    var isPaid: Bool
    var notes: [String]?
    var receiptImage: Data?

    init(from transaction: Transaction)
    {
        self.id = transaction.id
        self.date = transaction.date
        self.name = transaction.name
        self.price = transaction.price
        self.tag = transaction.tag
        self.isPaid = transaction.isPaid
        self.notes = transaction.notes
        self.receiptImage = transaction.receiptImage
    }

    public func toModel() -> Transaction
    {
        let transaction = Transaction(date: self.date,
                                      name: self.name,
                                      price: self.price,
                                      tag: self.tag,
                                      isPaid: self.isPaid,
                                      notes: self.notes,
                                      receiptImage: self.receiptImage)
        transaction.setId(id: self.id)
        return transaction
    }
}


/// For additional funcitonality that are not core Model methods.
extension Transaction
{
    static func exportAll(from context: ModelContext) throws -> Data
    {
        let fetchDescriptor = FetchDescriptor<Transaction>()
        let transactions = try context.fetch(fetchDescriptor)
        
        let codables = transactions.map { CodableTransaction(from: $0) }
        return try JSONEncoder().encode(codables)
    }
    
    static func importFrom(data: Data, into context: ModelContext) throws -> Int
    {
        let codables = try JSONDecoder().decode([CodableTransaction].self, from: data)
        
        for codable in codables
        {
            let transaction = codable.toModel()
            context.insert(transaction)
        }
        
        try context.save()
        return codables.count
    }
}
