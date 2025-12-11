//
//  Extensions.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/10/25.
//

import Foundation

/// Extensions for more convenient and intuitive `Date` methods.
public extension Date
{
    static func dayEquals(date1: Date, date2: Date) -> Bool
    { return Calendar.current.startOfDay(for: date1) == Calendar.current.startOfDay(for: date2) }
    
    static func minuteEquals(date1: Date, date2: Date) -> Bool
    { return Calendar.current.isDate(date1, equalTo: date2, toGranularity: .minute) }
}
