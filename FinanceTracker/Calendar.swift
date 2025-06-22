//
//  Calendar.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 2/1/25.
//

import SwiftUI
import SwiftData

extension Array {
    /// Splits an array into chunks of a specified size.
    func chunked(into size: Int) -> [[Element]]
    {
        stride(from: 0, to: count, by: size)
            .map { Array(self[$0 ..< Swift.min($0 + size, count)]) }
    }
}

struct CalendarView: View
{
    @EnvironmentObject var addNewSheetController: SheetController
    @Query(sort: \Transaction.date, order: .forward) var transactions: [Transaction]
    @Query(sort: \RecurringTransaction.name, order: .forward) var recurringTransactions: [RecurringTransaction]
        
    @State private var scaleEffect: CGFloat = 1.0
    @State private var selectedDate: Date = Date()
    private let calendar = Calendar.current
    
    // e.g. "January 2025"
    private var monthYearFormatter: DateFormatter
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }
    
    // e.g. "Wednesday, January 1, 2025"
    private var fullDateFormatter: DateFormatter
    {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }
    
    /// For the header that displays Day of Week, adjusted to user's calendar settings
    private var adjustedWeekdaySymbols: [String] {
        let symbols = calendar.shortStandaloneWeekdaySymbols // Always in order ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let firstWeekdayIndex = calendar.firstWeekday - 1 // Convert to 0-based index.
        return Array(symbols[firstWeekdayIndex...]) + Array(symbols[..<firstWeekdayIndex])
    }
    
    /// Return Events that recur on this day
    private func getEvents(date: Date) -> [Events]
    {
        var events: [Events] = []
        for i in 0..<recurringTransactions.count
        {
            if recurringTransactions[i].occursOnDate(date: date)
            {
                let newEvent: Events = recurringTransactions[i].verboseDescriptionEvent()
                if recurringTransactions[i].occursOnDateButAfter(date: date, initialDate: newEvent.date)
                {
                    events.append(newEvent)
                }
            }
        }
        return events
    }
    
    var body: some View
    {
        VStack
        {
            HStack
            {
                Button(action: { selectedDate = changeMonth(by: -1) })
                {
                    Image(systemName: "chevron.left")
                        .padding()
                }
                
                Spacer()
                
                Text(monthYearFormatter.string(from: selectedDate))
                    .font(.headline)
                    .onTapGesture{ selectedDate = Date() }
                
                Spacer()
                
                Button(action: { selectedDate = changeMonth(by: 1) })
                {
                    Image(systemName: "chevron.right")
                        .padding()
                }
            }
                .padding(.horizontal)
            
            HStack
            {
                ForEach(adjustedWeekdaySymbols, id: \.self)
                { weekday in
                    Text(weekday)
                        .frame(maxWidth: .infinity)
                        .font(.subheadline)
                }
            }
            
            let daysInMonth = generateDaysInMonth(for: selectedDate)
            let calendarRows = daysInMonth.chunked(into: 7)
            VStack
            {
                ForEach(calendarRows.indices, id: \.self)
                { rowIndex in
                    HStack
                    {
                        ForEach(calendarRows[rowIndex].indices, id: \.self)
                        { columnIndex in
                            let day = calendarRows[rowIndex][columnIndex]
                            Group
                            {
                                if let day = day // day could be nil
                                {
                                    Text("\(calendar.component(.day, from: day))")
                                        .frame(maxWidth: .infinity, minHeight: 40)
                                        .cornerRadius(4)
                                        .padding(4)
                                        .accentButtonToggled(boolean: calendar.isDate(day, inSameDayAs: selectedDate),
                                                             opacity1: 0.6,
                                                             opacity2: 0.001) // Highlight selected
                                        .accentButtonToggled(boolean: calendar.isDate(day, inSameDayAs: Date()) &&
                                                                !calendar.isDate(day, inSameDayAs: selectedDate),
                                                             opacity1: 0.3,
                                                             opacity2: 0.001) // Highlight today
                                        .underline(hasRecurringTransaction(for: day),
                                                   color: Color.accentColor)  // Only underline if has Event
                                        .onTapGesture { selectedDate = day
                                                        scaleEffect = 1.2
                                                        withAnimation { scaleEffect = 1.0 } }
                                        .scaleEffectToggled(boolean: calendar.isDate(day, inSameDayAs: selectedDate),
                                                            scaleEffect: scaleEffect) // Only scale if selected
                                } else {
                                    Text("")
                                        .frame(maxWidth: .infinity, minHeight: 40)
                                }
                            }
                        }
                    }
                }
            }
                .padding(.vertical)
            
            Divider()
                .padding(.vertical)
            

            VStack(alignment: .leading, spacing: 10)
            {
                Text(fullDateFormatter.string(from: selectedDate))
                    .font(.title2)
                    .padding(.bottom, 5)
                
                ForEach(getEvents(date: selectedDate), id: \.self)
                { event in
                    let relatedTransaction = transactions.filter
                    { transaction in
                        transaction.isPartOf(event: event) &&
                        calendar.isDate(transaction.date,
                                        inSameDayAs: selectedDate)
                    }
                    
                    // nil == false returns false
                    let textColor: Color = relatedTransaction.first?.paid == false ? .red : .accentColor

                    HStack
                    {
                        Image(systemName: "calendar")
                        
                        Text(event.toString())
                            .foregroundColor(textColor)
                    }
                        .padding(.vertical, 4)
                        .onTapGesture { addNewSheetController.name = event.name
                                        addNewSheetController.tag = event.tag
                                        addNewSheetController.price = event.price
                                        addNewSheetController.date = selectedDate
                                        addNewSheetController.toggleSheet()}
                }
            }
                .padding(.horizontal)

            Spacer()
        }
            .padding()
            .plainFill()
    }
    
    /// Changes the current date by a number of months. (Negative values mean going back in time.)
    private func changeMonth(by value: Int) -> Date
    {
        if let newDate = calendar.date(byAdding: .month, value: value, to: selectedDate)
        { return newDate }
        return selectedDate
    }
    
    /// Generates an array of optional Dates representing the calendar layout of the month, padded with `nil` to fit rows of 7
    private func generateDaysInMonth(for date: Date) -> [Date?]
    {
        var paddedDays: [Date?] = []
        
        if let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
           let days = calendar.range(of: .day, in: .month, for: date)
        {
            let weekdayOfFirstDay = calendar.component(.weekday, from: firstDayOfMonth)
            let startingWeekday = calendar.firstWeekday
            let leadingNils = ( (weekdayOfFirstDay - startingWeekday) + 7 ) % 7
            
            paddedDays.append(contentsOf: Array(repeating: nil, count: leadingNils))
            for dayCount in days
            {
                if let day = calendar.date(byAdding: .day, value: dayCount - 1, to: firstDayOfMonth)
                { paddedDays.append(day) }
            }
            paddedDays.append(contentsOf: Array(repeating: nil, count: (7 - paddedDays.count % 7) % 7))
        }
        return paddedDays
    }
    
    private func hasRecurringTransaction(for day: Date) -> Bool
    {
        return recurringTransactions.contains
        { recurringTransaction in
            recurringTransaction.occursOnDate(date: day)
        }
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [RecurringTransaction.self, Transaction.self], inMemory: true)
}
