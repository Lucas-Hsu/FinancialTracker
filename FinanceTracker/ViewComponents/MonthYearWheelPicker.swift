//
//  MonthYearWheelPicker.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/21/25.
//

import SwiftUI

// Custom Wheel Picker for Month and Year only
struct MonthYearWheelPicker: View
{
    // MARK: - Binding Attributes
    @Binding var date: Date
    
    // MARK: - Private Attributes
    private var years: [Int]
    {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 20)...(currentYear + 2))
    }
    
    // MARK: - UI
    var body: some View
    {
        HStack(spacing: 0)
        {
            // Month Picker
            Picker("Month", selection: Binding( get: { Calendar.current.component(.month, from: date) },
                                                set: { newMonth in
                                                    var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                                                    components.month = newMonth
                                                    if let newDate = Calendar.current.date(from: components)
                                                    { assignDate(newDate.monthStart()) } }))
            {
                ForEach(1...12, id: \.self)
                { month in
                    Text(Calendar.current.shortMonthSymbols[month - 1]).tag(month)
                }
            }
            .pickerStyle(.wheel)
            .clipped()
            .frame(width: 120)
            // Year Picker
            Picker("Year", selection: Binding( get: { Calendar.current.component(.year, from: date) },
                                               set: { newYear in
                                                    var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                                                    components.year = newYear
                                                    if let newDate = Calendar.current.date(from: components)
                                                    { assignDate(newDate.monthStart()) } }))
            {
                ForEach(years, id: \.self)
                { year in
                    Text(String(format: "%d", year)).tag(year)
                }
            }
            .pickerStyle(.wheel)
            .clipped()
            .frame(width: 80)
        }
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - Private Helpers
    // Validates selected date (Prevent selecting the future)
    private func assignDate(_ newDate: Date)
    {
        let now = Date()
        if newDate > now
        { self.date = now }
        else
        { self.date = newDate }
    }
}
