//
//  Calendar.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 2/1/25.
//


// Calendar recurring should pass date
// sign for recurring on calendar even before u cllick it.
// - sign should also register
// month should also recognize
// clear button for notes
// notes disappearing
// calendar jump to today


import SwiftUI
import SwiftData

// 好不容易可以熬夜休息

struct CalendarView: View {
    @Query(sort: \RecurringTransaction.name, order: .forward) var recurringTransactions: [RecurringTransaction]
    @Query(sort: \Transaction.date, order: .forward) var transactions: [Transaction] // Query for Transactions
        
    @State private var currentDate = Date()
    @State private var selectedDate: Date = Date()

    // Use the user's current calendar, which is configured according to locale
    private let calendar = Calendar.current
    
    // Formatter for the header (month and year)
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy" // e.g., "January 2025"
        return formatter
    }
    
    // Formatter for the full date shown when a day is selected
    private var fullDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full // e.g., "Wednesday, January 1, 2025"
        return formatter
    }
    
    // Compute the weekday header adjusted for the user's calendar settings.
    private var adjustedWeekdaySymbols: [String] {
        // Use the "standalone" weekday symbols provided by the calendar.
        // Many calendars always return an array in a fixed order (often starting with Sunday),
        // so we adjust it so that the first element matches the calendar's firstWeekday.
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let firstWeekdayIndex = calendar.firstWeekday - 1 // Convert to 0-based index.
        return Array(symbols[firstWeekdayIndex...]) + Array(symbols[..<firstWeekdayIndex])
    }
    
    private func getEvents(date: Date) -> [Events] {
    var events: [Events] = []

    for i in 0..<recurringTransactions.count {
        if recurringTransactions[i].occursOnDate(date: date) {
            let newEvent: Events = recurringTransactions[i].verboseDescriptionEvent()
            if recurringTransactions[i].occursOnDateButAfter(date: date, initialDate: newEvent.date) {
                events.append(newEvent)
            }
        }
    }
    
    return events
    }
    
    @State private var scaleEffect: CGFloat = 1.0
    
    @EnvironmentObject var sheetController: SheetController
    var body: some View {
        VStack {
            // Header with month/year and navigation buttons.
            HStack {
                Button(action: { currentDate = changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .padding()
                }
                
                Spacer()
                
                Text(monthYearFormatter.string(from: currentDate))
                    .font(.headline)
                
                Spacer()
                
                Button(action: { currentDate = changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .padding()
                }
            }
            .padding(.horizontal)
            
            // Weekday headers (adapted to the user's settings).
            HStack {
                ForEach(adjustedWeekdaySymbols, id: \.self) { weekday in
                    Text(weekday)
                        .frame(maxWidth: .infinity)
                        .font(.subheadline)
                }
            }
            
            // Calendar grid with days.
            let daysInMonth = generateDaysInMonth(for: currentDate)
            let rows = daysInMonth.chunked(into: 7)
            VStack {
                ForEach(rows.indices, id: \.self) { rowIndex in
                    HStack {
                        ForEach(rows[rowIndex].indices, id: \.self) { columnIndex in
                            let day = rows[rowIndex][columnIndex]
                            Group {
                                if let day = day {
                                    Text("\(calendar.component(.day, from: day))")
                                        .frame(maxWidth: .infinity, minHeight: 40)
                                        .padding(4)
                                        .accentButtonToggled(boolean: calendar.isDate(day, inSameDayAs: selectedDate), opacity2: 0.001)
                                        .cornerRadius(4)
                                        .scaleEffectToggled(boolean: calendar.isDate(day, inSameDayAs: selectedDate), scaleEffect: scaleEffect)
                                        .onTapGesture {
                                            scaleEffect = 1.2
                                            selectedDate = day
                                            withAnimation {
                                                scaleEffect = 1.0 // Return to normal size
                                            }
                                        }
                                } else {
                                    // Empty cell for days outside the current month.
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
            

                VStack(alignment: .leading, spacing: 10) {
                    Text(fullDateFormatter.string(from: selectedDate))
                        .font(.title2)
                        .padding(.bottom, 5)
                    
                    ForEach(getEvents(date: selectedDate), id: \.self) { event in
                        // Check for transactions that match the event
                        let relatedTransactions = transactions.filter { transaction in
                            recurringTransactions[0].isPartOfEvent(transaction: transaction, event: event) && calendar.isDate(transaction.date, inSameDayAs: selectedDate)
                        }
                        
                        // Find the first matching transaction, if any
                        let transaction = relatedTransactions.first
                        
                        // Apply the text color based on isPaid status
                        let textColor: Color = transaction?.paid == true ? .black : .red
                        
                        HStack {
                            Image(systemName: "calendar")
                            Text(event.toString())
                                .foregroundColor(textColor)//Look here!
                        }
                        .padding(.vertical, 4)
                        .onTapGesture {
                            sheetController.name = event.name
                            sheetController.tag = event.tag
                            sheetController.price = event.price
                            sheetController.toggleSheet()
                        }
                    }
                }
                .padding(.horizontal)
            
            
            Spacer()
        }
        .padding()
        .plainFill()
    }
    
    /// Advances or rewinds the current date by a number of months.
    private func changeMonth(by value: Int) -> Date {
        guard let newDate = calendar.date(byAdding: .month, value: value, to: currentDate) else {
            return currentDate
        }
        return newDate
    }
    
    /// Generates an array of optional Dates representing the layout of the month.
    /// `nil` values represent cells before the first day and after the last day of the month.
    private func generateDaysInMonth(for date: Date) -> [Date?] {
        var days: [Date?] = []
        
        // Get the first day of the month.
        guard let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let range = calendar.range(of: .day, in: .month, for: date)
        else {
            return days
        }
        
        
        // Determine the weekday index for the first day.
        let firstWeekdayOfMonth = calendar.component(.weekday, from: firstOfMonth)
        // Calculate the number of empty cells needed before the first day.
        let leadingEmpty = firstWeekdayOfMonth - calendar.firstWeekday
        let adjustedLeading = leadingEmpty >= 0 ? leadingEmpty : leadingEmpty + 7
        
        // Add nil placeholders for days before the first day.
        days.append(contentsOf: Array(repeating: nil, count: adjustedLeading))
        
        // Add each day of the month.
        for day in range {
            if let dayDate = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(dayDate)
            }
        }
        
        // Fill the remaining cells of the grid to complete the last week.
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    
    
    /// Returns the background color for a given day.
    /// Only the selected day is highlighted.
    private func backgroundColor(for day: Date) -> Color {
        if calendar.isDate(day, inSameDayAs: selectedDate) {
            return .accentColor.opacity(0.4)
        } else {
            return Color.clear
        }
    }
    
}

extension Array {
    /// Splits the array into chunks of a specified size.
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
            .modelContainer(for: [RecurringTransaction.self, Transaction.self], inMemory: true)
    }
}
