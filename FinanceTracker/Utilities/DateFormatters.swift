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
    
    private static let dMMMMyyyyFormatter: DateFormatter =
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        formatter.locale = Locale.current
        return formatter
    }()
    
    private static let MMMMyyyyFormatter: DateFormatter =
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale.current
        return formatter
    }()
    
    private static let MMMMddyyyyFormatter: DateFormatter =
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy"
        formatter.locale = Locale.current
        return formatter
    }()
    
    private static let MMMddyyyyFormatter: DateFormatter =
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
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
    
    private static let yyyyMMddhhmmFormatter: DateFormatter =
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd hh:mm"
        formatter.locale = Locale.current
        return formatter
    }()

    public static func medium(date: Date) -> String
    { return mediumDateFormatter.string(from: date) }
    
    public static func dMMMMyyyy(date: Date) -> String
    { return dMMMMyyyyFormatter.string(from: date) }
    
    public static func MMMMyyyy(date: Date) -> String
    { return MMMMyyyyFormatter.string(from: date) }
    
    public static func MMMMddyyyy(date: Date) -> String
    { return MMMMddyyyyFormatter.string(from: date) }
    
    public static func MMMddyyyy(date: Date) -> String
    { return MMMddyyyyFormatter.string(from: date) }
    
    public static func yyyyMMdd(date: Date) -> String
    { return yyyyMMddFormatter.string(from: date) }
    
    public static func yyyyMMddhhmm(date: Date) -> String
    { return yyyyMMddhhmmFormatter.string(from: date) }
}
