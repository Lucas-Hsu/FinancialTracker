//
//  Transaction.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 2/1/25.
//

import Foundation
import SwiftData
import SwiftUI

/// The `Transaction` class stores information about individual units of expenses.
@Model
class Transaction: Equatable
{
    // MARK: - Read-Only Attributes
    @Attribute(.unique) private(set) var id: UUID
    private(set) var date: Date
    private(set) var name: String
    private(set) var price: Double
    private(set) var tag: Tag
    private(set) var isPaid: Bool
    private(set) var notes: [String]?
    private(set) var receiptImage: Data?
    
    // MARK: - Constructors
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
    
    // MARK: - Boundary Case Checkers
    public func isDateValid(date: Date) -> Bool
    { return date <= Date() }
    public func isNameValid(name: String) -> Bool
    { return name.strip().count > 0 }
    public func isPriceValid(price: Double) -> Bool
    { return price >= 0 }
    // The following mutators do not need to do validation (for now)
    public func isTagValid(tag: Tag) -> Bool
    { return true }
    public func isIsPaidValid(isPaid: Bool) -> Bool
    { return true }
    public func isNotesValid(notes: [String]?) -> Bool
    { return true }
    public func isReceiptImageValid(receiptImage: Data?) -> Bool
    { return true }
    public func isIdValid(id: UUID) -> Bool
    { return true }
    
    // MARK: - Mutators
    public func setDate(date: Date)
    {
        if isDateValid(date: date)
        { self.date = date }
        else
        { self.date = Date() }
    }
    public func setName(name: String)
    {
        if isNameValid(name: name)
        { self.name = name }
        else
        { self.name = "Transaction at \(Date().toMediumString())" }
    }
    public func setPrice(price: Double)
    {
        if isPriceValid(price: price)
        { self.price = price }
        else
        { self.price = abs(price) }
    }
    // The following mutators do not need to do validation (for now)
    public func setTag(tag: Tag)
    {
        if isTagValid(tag: tag)
        { self.tag = tag }
        else
        { self.tag = tag }
    }
    public func setIsPaid(isPaid: Bool)
    {
        if isIsPaidValid(isPaid: isPaid)
        { self.isPaid = isPaid }
        else
        { self.isPaid = isPaid }
    }
    public func setNotes(notes: [String]?)
    {
        if isNotesValid(notes: notes)
        { self.notes = notes }
        else
        { self.notes = notes }
    }
    public func setReceiptImage(receiptImage: Data?)
    {
        if isReceiptImageValid(receiptImage: receiptImage)
        { self.receiptImage = receiptImage }
        else
        { self.receiptImage = receiptImage }
    }
    public func setId(id: UUID)
    {
        if isIdValid(id: id)
        { self.id = id }
        else
        { self.id = id }
    }
    
    // MARK: - Accessors
    // Accessors are not needed because private(set) means read-only when outside of this class.
    
    // MARK: - Public Methods
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

    // For grouping same transactions occuring at different dates
    public func getTransactionGroupHeader() -> TransactionGroupHeader
    { return TransactionGroupHeader(name: self.name, tag: self.tag)   }
    
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
    // MARK: - Public Attributes accessed by SwiftData system
    var id: UUID
    var date: Date
    var name: String
    var price: Double
    var tag: Tag
    var isPaid: Bool
    var notes: [String]?
    var receiptImage: Data?

    // MARK: - Constructor
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
    
    // MARK: - Public Methods
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

/// View for one `Transaction` record
struct TransactionView: View
{
    // MARK: - Read-Only Attributes
    private let transaction: Transaction
    
    // MARK: - Constructor
    init(transaction: Transaction)
    { self.transaction = transaction }
    
    // MARK: - UI
    var body: some View
    {
        VStack(alignment: .leading, spacing: 4)
        {
            HStack
            {
                Text(transaction.name)
                .font(.headline)
                .lineLimit(1)
                
                Spacer()
                
                Text("¥\(transaction.price, specifier: "%.2f")")
                .font(.headline)
                .foregroundColor(transaction.price < 0 ? .red : .primary)
            }
            
            HStack
            {
                Text(transaction.date, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
                
                Spacer()
                
                Text(transaction.tag.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .cornerRadius(4)
            }

            HStack
            {
                if !transaction.isPaid
                {
                    Text("UNPAID")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(3)
                }
                
                if let notes = transaction.notes, !notes.isEmpty
                {
                    Spacer()
                    Image(systemName: "note.text")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
