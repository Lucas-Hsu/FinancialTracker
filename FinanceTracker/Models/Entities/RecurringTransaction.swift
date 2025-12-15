//
//  RecurringTransaction.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/14/25.
//

import Foundation
import SwiftData
import SwiftUI

/// Displays the patterns between `Transactions` that are grouped together
@Model
class RecurringTransaction: Equatable, CustomStringConvertible
{
    // MARK: - Read-Only Attributes
    @Attribute(.unique) private(set) var id: UUID
    private(set) var name: String
    private(set) var tag: String
    private(set) var pattern: String
    private(set) var interval: Int
    private(set) var startDate: Date

    // MARK: - Constructors
    init(name: String, tag: Tag, pattern: RecurringPattern, interval: Int, startDate: Date)
    {
        self.id = UUID()
        self.name = name
        self.tag = tag.rawValue
        self.pattern = pattern.rawValue
        self.interval = interval
        self.startDate = startDate
    }
    
    // MARK: - Mutators
    // Not needed
    
    // MARK: - Accessors
    // private(set) allows directly reading using dot notation without being able to mutate
    
    // MARK: - Public Methods
    // Find next valid occurrence of this RecurringTransaction after the given date.
    public func nextDate(after date: Date = Date()) -> Date
    {
        let calendar = Calendar.current
        var candidate = self.startDate
        let isStartEOM = isEndOfMonth(date: self.startDate, calendar: calendar)
        while candidate <= date
        {
            guard let next = advance(date: candidate, isStartEOM: isStartEOM, calendar: calendar) else
            {
                break
            }
            candidate = next
        }
        return candidate
    }
    // Excluding start date, check if the date conforms to the RecurringTransaction
    public func isRecursOn(date: Date) -> Bool
    {
        let calendar = Calendar.current
        let checkDate = calendar.startOfDay(for: date)
        let normalizedStartDate = calendar.startOfDay(for: self.startDate)
        return !calendar.isDate(checkDate, inSameDayAs: normalizedStartDate) && isOccursOn(date: date)
    }
    // Including start date, check if the date conforms to the RecurringTransaction
    public func isOccursOn(date: Date) -> Bool
    {
        let calendar = Calendar.current
        let checkDate = calendar.startOfDay(for: date)
        let normalizedStartDate = calendar.startOfDay(for: self.startDate)
        
        if checkDate < normalizedStartDate
        {
            return false
        }
        
        if calendar.isDate(checkDate, inSameDayAs: normalizedStartDate)
        {
            return true
        }

        let isStartEOM = isEndOfMonth(date: normalizedStartDate, calendar: calendar)
        
        if self.pattern == RecurringPattern.days.rawValue
        {
            // Check the difference in days is divisible by the interval.
            let components = calendar.dateComponents([.day], from: normalizedStartDate, to: checkDate)
            guard let totalDays = components.day, totalDays > 0 else
            { return false }
            return totalDays % self.interval == 0
        }
        else if self.pattern == RecurringPattern.months.rawValue
        {
            // Check the difference in months is divisible by the interval AND maintain end of month status
            let components = calendar.dateComponents([.month, .day], from: normalizedStartDate, to: checkDate)
            guard let totalMonths = components.month, totalMonths >= self.interval else
            { return false }
            if totalMonths % self.interval != 0
            {
                return false
            }
            guard let expectedDate = calendar.date(byAdding: .month, value: totalMonths, to: normalizedStartDate) else
            { return false }
            
            if isStartEOM
            {
                return isEndOfMonth(date: checkDate, calendar: calendar)
            }
            else
            {
                return calendar.isDate(checkDate, inSameDayAs: expectedDate)
            }
        }
        else // if self.pattern ==  RecurringPattern.years.rawValue
        {
            let components = calendar.dateComponents([.year, .month, .day], from: normalizedStartDate, to: checkDate)
            guard let totalYears = components.year, totalYears >= self.interval else
            { return false }
            if totalYears % self.interval != 0
            {
                return false
            }
            guard let expectedDate = calendar.date(byAdding: .year, value: totalYears, to: normalizedStartDate) else
            { return false }
            if isStartEOM
            {
                return isEndOfMonth(date: checkDate, calendar: calendar)
            }
            else
            {
                return calendar.isDate(checkDate, inSameDayAs: expectedDate)
            }
        }
    }
    
    // MARK: - Private Helpers
    // Using the pattern, advance one interval after a given date.
    private func advance(date: Date, isStartEOM: Bool, calendar: Calendar) -> Date?
    {
        if self.pattern == RecurringPattern.days.rawValue
        {
            return calendar.date(byAdding: .day, value: interval, to: date)
        }
        else if self.pattern == RecurringPattern.months.rawValue
        {
            if isStartEOM
            {
                // Feb 29 -> Mar 31
                guard let standardAdd = calendar.date(byAdding: .month, value: interval, to: date) else
                { return nil }
                // Force to end of that month
                return endOfMonth(for: standardAdd, calendar: calendar)
            }
            else
            {
                // Jan 30 -> Feb 29 -> Mar 30
                return calendar.date(byAdding: .month, value: interval, to: date)
            }
        }
        else // if self.pattern == RecurringPattern.years.rawValue
        {
            if isStartEOM
            {
                // Feb 29 2024 -> Feb 28 2025 -> Feb 28 2026
                guard let standardAdd = calendar.date(byAdding: .year, value: interval, to: date) else
                { return nil }
                return endOfMonth(for: standardAdd, calendar: calendar)
            }
            else
            {
                return calendar.date(byAdding: .year, value: interval, to: date)
            }
        }
    }
    // Is end of month, like Jan 31, Feb 29 (leap year), Feb 28 (non leap year), April 30, ...
    private func isEndOfMonth(date: Date, calendar: Calendar) -> Bool
    {
        guard let interval = calendar.dateInterval(of: .month, for: date),
              let lastDay = calendar.date(byAdding: .day, value: -1, to: interval.end) else
        {
            return false
        }
        return calendar.isDate(date, inSameDayAs: lastDay)
    }
    // returns the endOfMonth of the month that the given date is in.
    private func endOfMonth(for date: Date, calendar: Calendar) -> Date?
    {
        guard let interval = calendar.dateInterval(of: .month, for: date),
              let lastDay = calendar.date(byAdding: .day, value: -1, to: interval.end) else
        {
            return nil
        }
        return lastDay
    }

    var description: String
    {
        return 
            """
            [RecurringTransaction]
            id: \(self.id)
            name: \(self.name)
            name: \(self.tag)
            Start: \(self.startDate.formatted(date: .numeric, time: .omitted))
            Pattern: \(self.interval) \(self.pattern)
            """
    }
    
    static func == (lhs: RecurringTransaction, rhs: RecurringTransaction) -> Bool
    {
        lhs.name == rhs.name &&
        lhs.tag == rhs.tag &&
        lhs.pattern == rhs.pattern &&
        lhs.interval == rhs.interval &&
        Date.dayEquals(date1: lhs.startDate, date2: rhs.startDate)
    }
}


/// View for one `RecurringTransaction` record
struct RecurringTransactionView: View
{
    // MARK: - Read-Only Attributes
    private let recurringTransaction: RecurringTransaction
    
    // MARK: - Constructor
    init(recurringTransaction: RecurringTransaction)
    { self.recurringTransaction = recurringTransaction }
    
    // MARK: - UI
    var body: some View
    {
        HStack
        {
            Text("\(recurringTransaction.name): \(recurringTransaction.tag)")
            
            HStack
            {
                Text("Began on \(recurringTransaction.startDate.toMediumString())")
                Text("Recurs every \(recurringTransaction.interval) \(recurringTransaction.pattern)")
            }
        }
        .padding(.vertical, 8)
    }
}
