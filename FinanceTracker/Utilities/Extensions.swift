//
//  Extensions.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/10/25.
//

import Foundation
import SwiftData
import SwiftUI

public extension Date
{
    func toMediumString() -> String
    {
        return DateFormatters.medium(date: self)
    }
    
    static func dayEquals(date1: Date, date2: Date) -> Bool
    { return Calendar.current.startOfDay(for: date1) == Calendar.current.startOfDay(for: date2) }
    
    static func minuteEquals(date1: Date, date2: Date) -> Bool
    { return Calendar.current.isDate(date1, equalTo: date2, toGranularity: .minute) }
    
    func startOfDay(in timeZone: TimeZone = .current) -> Date
    {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        return calendar.startOfDay(for: self)
    }
    // Returns the start of the month based on the Local time zone, but in UTC 00:00:00.
    func monthStart() -> Date
    {
        let localComponents = Calendar.current.dateComponents([.year, .month], from: self)
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone.current
        return utcCalendar.date(from: localComponents) ?? self
    }
    // Returns the start of the day based on the Local time zone, but in UTC 00:00:00.
    func dayStart() -> Date
    {
        let localComponents = Calendar.current.dateComponents([.year, .month, .day], from: self)
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone.current
        return utcCalendar.date(from: localComponents) ?? self
    }
    // Returns the start of the minute based on the Local time zone, but in UTC 00:00:00.
    func minuteStart() -> Date
    {
        let localComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone.current
        return utcCalendar.date(from: localComponents) ?? self
    }
}

extension String
{
    func truncate(to characters: Int, trailing: String = "...") -> String
    {
        if (self.count > characters)
        { return String(self.prefix(characters)) + trailing }
        return self
    }
    
    func strip() -> String
    { return self.trimmingCharacters(in: .whitespacesAndNewlines) }
    
    func strip(_ characters: String = " ") -> String
    {
        let set = CharacterSet(charactersIn: characters)
        return self.trimmingCharacters(in: set)
    }
}

extension ModelContext
{
    func saveSuccess() -> Bool
    {
        do
        {
            try self.save()
            return true
        }
        catch
        {
            print("[ERROR] Failed to save context: \(error)")
            return false
        }
    }
}

extension Notification.Name
{
    static let transactionBSTUpdated = Notification.Name("TransactionBSTDidSaveNotification")
    static let transactionsUpdated = Notification.Name("TransactionsDidSaveNotification")
}

private struct TransactionBSTKey: EnvironmentKey
{
    static let defaultValue: TransactionBST? = nil
}

extension EnvironmentValues
{
    var transactionBST: TransactionBST?
    {
        get { self[TransactionBSTKey.self] }
        set { self[TransactionBSTKey.self] = newValue }
    }
}

extension Array
{
    func chunked(into size: Int) -> [[Element]]
    {
        stride(from: 0, to: count, by: size)
        .map { Array(self[$0 ..< Swift.min($0 + size, count)]) }
    }
}
