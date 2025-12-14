//
//  RecurringPatternRecognition.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/14/25.
//

import Foundation
import SwiftData

/// Finds `RecurringPattern` and `RecurringTransaction` from `Transaction` objects
struct RecurringPatternRecognition
{
    // MARK: - Public Static Methods
    // Analyzes a list of transactions to find a recurring pattern.
    static func findRecurringTransaction(_ transactions: [Transaction]) -> RecurringTransaction?
    {
        guard transactions.count >= 3 else
        { return nil }
        let sorted = transactions.sorted { $0.date < $1.date }
        let dates = sorted.map { Calendar.current.startOfDay(for: $0.date) }

        if let interval = findYearlyPattern(dates: dates)
        {
            return RecurringTransaction(pattern: .years, interval: interval, startDate: sorted.first!.date)
        }
        
        if let interval = findMonthlyPattern(dates: dates)
        {
            return RecurringTransaction(pattern: .months, interval: interval, startDate: sorted.first!.date)
        }
        
        if let interval = findDailyPattern(dates: dates)
        {
            return RecurringTransaction(pattern: .days, interval: interval, startDate: sorted.first!.date)
        }
        
        return nil
    }
    
    // MARK: - Private Helpers
    private static func findYearlyPattern(dates: [Date]) -> Int?
    {
        let calendar = Calendar.current
        let first = dates[0]
        let second = dates[1]
        
        guard let diffYears = calendar.dateComponents([.year], from: first, to: second).year, diffYears > 0 else
        { return nil }

        let isEOMMode = isEndOfMonth(date: first, calendar: calendar) && isEndOfMonth(date: second, calendar: calendar)
        for i in 1..<dates.count
        {
            let expectedInterval = diffYears * i
            let targetDate = dates[i]
            if isEOMMode
            {
                if !isEndOfMonth(date: targetDate, calendar: calendar)
                { return nil }
                let currentDiff = calendar.dateComponents([.year], from: first, to: targetDate).year
                if currentDiff != expectedInterval
                { return nil }
                
            }
            else
            {
                guard let expectedDate = calendar.date(byAdding: .year, value: expectedInterval, to: first) else
                { return nil }
                if !calendar.isDate(targetDate, inSameDayAs: expectedDate)
                { return nil }
            }
        }
        return diffYears
    }
    
    private static func findMonthlyPattern(dates: [Date]) -> Int?
    {
        let calendar = Calendar.current
        let first = dates[0]
        let second = dates[1]
        
        guard let diffMonths = calendar.dateComponents([.month], from: first, to: second).month, diffMonths > 0 else
        { return nil }
        
        // "Jan 30 -> Feb 29" is not EOM mode because Jan 30 is not end of month.
        // "Jan 31 -> Feb 29" is EOM.
        let isEOMMode = isEndOfMonth(date: first, calendar: calendar) && isEndOfMonth(date: second, calendar: calendar)
        for i in 1..<dates.count
        {
            let expectedInterval = diffMonths * i
            let targetDate = dates[i]
            if isEOMMode
            {
                if !isEndOfMonth(date: targetDate, calendar: calendar)
                { return nil }
                let currentDiff = calendar.dateComponents([.month], from: first, to: targetDate).month
                if currentDiff != expectedInterval { return nil }
            }
            else
            {
                // Jan 30 + 1 month = Feb 29
                // Jan 30 + 2 month = Mar 30 not Mar 31
                guard let expectedDate = calendar.date(byAdding: .month, value: expectedInterval, to: first) else
                { return nil }
                if !calendar.isDate(targetDate, inSameDayAs: expectedDate)
                { return nil }
            }
        }
        return diffMonths
    }
    
    private static func findDailyPattern(dates: [Date]) -> Int?
    {
        let calendar = Calendar.current
        let first = dates[0]
        let second = dates[1]
        guard let diffDays = calendar.dateComponents([.day], from: first, to: second).day, diffDays > 0 else
        { return nil }
        
        for i in 1..<dates.count
        {
            let expectedInterval = diffDays * i
            guard let expectedDate = calendar.date(byAdding: .day, value: expectedInterval, to: first) else
            { return nil }
            if !calendar.isDate(dates[i], inSameDayAs: expectedDate)
            { return nil }
        }
        return diffDays
    }
    
    // MARK: - Helpers
    
    private static func isEndOfMonth(date: Date, calendar: Calendar) -> Bool
    {
        guard let interval = calendar.dateInterval(of: .month, for: date),
              let lastDay = calendar.date(byAdding: .day, value: -1, to: interval.end) else
        { return false }
        return calendar.isDate(date, inSameDayAs: lastDay)
    }
}
