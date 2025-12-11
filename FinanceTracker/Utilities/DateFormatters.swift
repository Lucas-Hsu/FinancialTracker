//
//  DateFormatters.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/11/25.
//

import Foundation

/// Conver `Date` to `String`s of various formats.
public class DateFormatters {
    
    private static let mediumDateFormatter: DateFormatter =
    {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    public static func medium(date: Date) -> String
    {
        return mediumDateFormatter.string(from: date)
    }
    
}
