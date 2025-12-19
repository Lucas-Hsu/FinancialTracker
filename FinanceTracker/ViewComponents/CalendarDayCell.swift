//
//  CalendarDayCell.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/17/25.
//

import SwiftUI

// An individual cell in the calendar
struct CalendarDayCell: View
{
    // MARK: - Static Attributes
    let day: Int
    let isToday: Bool
    let isSelected: Bool
    let hasEvents: Bool
    
    // MARK: - UI
    var body: some View
    {
        if #available(iOS 26.0, *)
        {
            dayDigit
            .glassEffect(Glass.identity.interactive(), in: .rect(cornerRadius: .infinity))
            .shadow(color: Color(hue: 0.58, saturation: 0.5, brightness: 0.5, opacity: shadow), radius: 3, x: 0, y: 4.5)
            .offset(y: hasEvents ? 14.5 : 12)
        }
        else
        {
            dayDigit
            .offset(y: 12)
        }
    }
    
    // MARK: - Components
    private var dayDigit: some View
    {
        VStack(spacing: 0)
        {
            Text("\(day)")
            .frame(width: 60, height: 40)
            .background(backgroundColor)
            .font(.body)
            .fontWeight(isToday ? .bold : .regular)
            .foregroundColor(textColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            if hasEvents
            {
                Circle()
                .fill(Color.accentColor)
                .frame(width: 5, height: 5)
                .opacity(isSelected ? 0 : 1)
                .offset(y: -10)
            }
        }
    }
    
    // MARK: - Variables
    private var textColor: Color
    {
        if isSelected
        { return .white }
        else if isToday
        { return .accentColor }
        else
        { return .primary }
    }
    private var backgroundColor: some View
    {
        Group
        {
            if isSelected
            { Color.accentColor }
            else if isToday
            { Color(UIColor.systemBackground) }
            else
            { Color(UIColor.systemBackground).mix(with: .accentColor, by: 0.02) }
        }
    }
    private var shadow: Double
    {
        if isSelected
        { return 0.2 }
        else if isToday
        { return 0.075 }
        else
        { return 0.05 }
    }
}
