//
//  Extensions.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/10/25.
//

import Foundation
import SwiftData

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

extension ModelContext {
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
    static let transactionDidSave = Notification.Name("TransactionDidSaveNotification")
}
