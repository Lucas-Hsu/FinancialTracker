//
//  Transaction.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 2/1/25.
//

import Foundation
import SwiftData
import SwiftUI

struct TransactionSignature: Codable, Equatable, Hashable
{
    var name: String
    var price: Double
    var tag: String
    
    init(name: String,
         price: Double,
         tag: String)
    {
        self.name = name
        self.price = price
        self.tag = tag
    }
    
    init(name: String,
         price: Double,
         tag: Tag)
    {
        self.name = name
        self.price = price
        self.tag = tag.rawValue
    }
}


/// A transaction record
@Model class Transaction: Equatable
{
    @Attribute(.unique) private(set) var id: UUID
    var date: Date
    var name: String
    var tag: Tag
    var price: Double
    var paid: Bool
    var notes: [String]?
    var image: Data?
    var signature: TransactionSignature { TransactionSignature(name: self.name, price: self.price, tag: self.tag) }
    var priceFormatter: NumberFormatter
    {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }
    
    init(date: Date = Date(),
         name: String = "",
         tag: Tag = Tag.other,
         price: Double = 19.99,
         paid: Bool = true,
         notes: [String]? = nil,
         image: Data? = nil)
    {
        self.id = UUID()
        self.date = date
        self.name = name
        self.tag = tag
        self.price = price
        self.paid = paid
        self.notes = notes
        self.image = image
    }
    
    /// Checks if the this Transaction matches provided filter criteria.
    /// - Parameters:
    ///  - onlyUnpaid:  If true,            filter for self.paid is false
    ///  - tags:        if provided,    filter for self.tag is contained in tags
    ///  - minDate:     if provided,    filter for self.date newer or equals to minDate
    ///  - maxDate:     if provided,    filter for self.date older or equals to maxDate
    public func matchesFilter(onlyUnpaid: Bool = false,
                              tags: Set<Tag>? = nil,
                              minDate: Date? = nil,
                              maxDate: Date? = nil) -> Bool
    {
        if (onlyUnpaid && self.paid)                    { return false }
        if let tags = tags, !tags.contains(self.tag)    { return false }
        if let minDate = minDate, minDate > self.date   { return false }
        if let maxDate = maxDate, maxDate < self.date   { return false }
        return true
    }
    
    public func isPartOf(recurringTransaction: RecurringTransaction) -> Bool
    {
        if (self.name != recurringTransaction.name ||
            self.price != recurringTransaction.price ||
            self.tag != recurringTransaction.tag)
        { return false }
        
        return recurringTransaction.occursOn(date: self.date)
    }
    
    public func sameDayAs(_ other: Transaction) -> Bool
    { return Calendar.current.startOfDay(for: other.date) == Calendar.current.startOfDay(for: self.date) }
    
    public func sameDayAs(date: Date) -> Bool
    { return Calendar.current.startOfDay(for: date) == Calendar.current.startOfDay(for: self.date) }
    
    public func setId(id: UUID)
    {
        self.id = id
    }
    
    public func toString() -> String
    {
        return
            """
            [Transaction Object]
            Name: \(self.name)
            Tag: \(self.tag)
            Date: \(self.date)
            Price: ¥\(self.price)
            Paid: \(paid)
            Notes Count: \(self.notes?.count ?? 0) lines
            Image Size: \(self.image?.count ?? 0) bytes
            """
    }
    
    static func == (lhs: Transaction, rhs: Transaction) -> Bool
    {
        abs(lhs.date.timeIntervalSince(rhs.date)) < 0.1 &&
        lhs.name == rhs.name &&
        lhs.tag == rhs.tag &&
        lhs.price == rhs.price &&
        lhs.paid == rhs.paid &&
        lhs.notes == rhs.notes &&
        lhs.image == rhs.image
    }
}

/// Simple view for `Transaction`s
struct TransactionView: View {
    var transaction: Transaction

    var body: some View
    {
        HStack
        {
            VStack(alignment: .leading)
            {
                Text(transaction.name)
                    .font(.body)
                
                Text(transaction.tag.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(transaction.price.toPriceString())
                .font(.body)
                .bold()
                .foregroundColor(transaction.paid ? .black : .red)
        }
            .padding()
    }
}
