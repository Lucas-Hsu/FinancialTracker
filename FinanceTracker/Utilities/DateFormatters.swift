//
//  DateFormatters.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/11/25.
//

import Foundation

/// Conver `Date` to `String`s of various formats.
public class DateFormatters
{
    private static let mediumDateFormatter: DateFormatter =
    {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    private static let MMMMyyyyFormatter: DateFormatter =
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale.current
        return formatter
    }()
    
    private static let yyyyMMddFormatter: DateFormatter =
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale.current
        return formatter
    }()

    public static func medium(date: Date) -> String
    { return mediumDateFormatter.string(from: date) }
    
    public static func MMMMyyyy(date: Date) -> String
    { return MMMMyyyyFormatter.string(from: date) }
    
    public static func yyyyMMdd(date: Date) -> String
    { return yyyyMMddFormatter.string(from: date) }
}
