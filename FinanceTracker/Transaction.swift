//
//  Transaction.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 2/1/25.
//

import SwiftData
import Foundation

@Model class Transaction
{
    @Attribute(.unique) private(set) var id: UUID
    var date: Date
    var name: String
    var tag: String // Store enum Tag as String
    var price: Double
    var paid: Bool
    var notes: [String]?
    var image: Data?
    
    var priceFormatter: NumberFormatter
    {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }
    
    init(date: Date = Date(),
         name: String = "Transaction",
         tag: String = Tag.other.rawValue,
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
                              tags: Set<String>? = nil,
                              minDate: Date? = nil,
                              maxDate: Date? = nil) -> Bool
    {
        if (onlyUnpaid && self.paid)                    { return false }
        if let tags = tags, !tags.contains(self.tag)    { return false }
        if let minDate = minDate, minDate > self.date   { return false }
        if let maxDate = maxDate, maxDate < self.date   { return false }
        return true
    }
    
    public func isPartOf(event: Events) -> Bool
    {
        if (self.name != event.name ||
            self.price != event.price ||
            self.tag != event.tag.rawValue)
        { return false }
        
        if self.date < event.date
        { return false }
        
        switch event.intervalType
        {
        case TypesOfRecurringTransaction.Yearly.rawValue: // Yearly: Exact same month and day
            if !isExactSameDayAndMonth(date1: self.date, date2: event.date)
            { return false }
            
        case TypesOfRecurringTransaction.Monthly.rawValue: // Monthly: Either exactly match, or each last day of month
            if !isExactSameDay(date1: self.date,
                              date2: event.date) &&
               !canMapDown(dateInitial: event.date,
                          dateNow: self.date)
            { return false }
            
        default: // Custom: Exact multiple of the interval days
            if !isDaysAfter(dateInitial: event.date,
                           interval: event.interval,
                           dateNow: self.date)
            { return false }
        }
        return true
    }
    
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

}
