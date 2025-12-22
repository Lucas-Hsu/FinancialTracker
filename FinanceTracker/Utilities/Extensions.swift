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
    // Returns the start of the year based on the Local time zone
    func yearStart() -> Date
    {
        let localComponents = Calendar.current.dateComponents([.year], from: self)
        return Calendar.current.date(from: localComponents) ?? self
    }
    // Returns the start of the month based on the Local time zone
    func monthStart() -> Date
    {
        let localComponents = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: localComponents) ?? self
    }
    // Returns the start of the day based on the Local time zone
    func dayStart() -> Date
    {
        let localComponents = Calendar.current.dateComponents([.year, .month, .day], from: self)
        return Calendar.current.date(from: localComponents) ?? self
    }
    // Returns the start of the minute based on the Local time zone
    func minuteStart() -> Date
    {
        let localComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        return Calendar.current.date(from: localComponents) ?? self
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
    static let ocrBubbleTapped = Notification.Name("OCRBubbleTappedNotification")
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

extension UIColor
{
    func mix(with other: UIColor, by amount: CGFloat) -> UIColor
    {
        let amount = max(0, min(1, amount))
        var r1: CGFloat = 0
        var g1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        var r2: CGFloat = 0
        var g2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0
        self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(red: r1 + (r2 - r1) * amount,
                       green: g1 + (g2 - g1) * amount,
                       blue: b1 + (b2 - b1) * amount,
                       alpha: a1 + (a2 - a1) * amount)
    }
}

extension View
{
    // Shows shadows on the inside of views
    func innerShadow<S: Shape>(shape: S, color: Color = .black, radius: CGFloat = 3, x: CGFloat = 0, y: CGFloat = 0) -> some View
    {
        self.overlay(shape
                    .stroke(color, lineWidth: radius)
                    .offset(x: x, y: y)
                    .blur(radius: radius)
                    .mask(shape))
    }
}
