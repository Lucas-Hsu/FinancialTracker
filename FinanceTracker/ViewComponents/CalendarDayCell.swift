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
    let day: String
    var toggle: Bool
    var state: Bool
    var mark: Bool
    var action: () -> Void
    
    private var textColor: Color
    {
        if state
        { return Color.accentColor }
        else
        { return Color.primary }
    }
    
    private var bgColor: Color
    {
        return Color(UIColor.systemBackground).mix(with: .accentColor, by: 0.02)
    }
    
    private var textWeight: Font.Weight
    {
        if state || toggle
        { return .bold }
        else
        { return .regular }
    }
    
    var body: some View
    {
        Text(self.day)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(toggle ? .accentColor : bgColor)
        .font(.title3)
        .fontWeight(textWeight)
        .underline(mark, color: .accentColor)
        .foregroundColor(toggle ? .white : textColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color(hue: 0.58, saturation: 0.5, brightness: 0.5, opacity: 0.1), radius: 2, x: 0, y: 4)
        .onTapGesture
        { self.action() }
    }
}
struct CalendarDayCellGlass: View
{
    let day: String
    var toggle: Bool = false
    var state: Bool
    var mark: Bool
    var action: () -> Void
    
    var body: some View
    {
        if #available(iOS 26.0, *)
        {
            CalendarDayCell(day: self.day, toggle: self.toggle, state: self.state, mark: self.mark, action: self.action)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
        }
        else
        { CalendarDayCell(day: self.day, toggle: self.toggle, state: self.state, mark: self.mark, action: self.action) }
    }
}
