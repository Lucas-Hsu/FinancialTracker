//
//  RecurringTransactionsTestView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 2/27/25.
//

import SwiftUI
import SwiftData
import Foundation

func daysInYear(year: Int) -> [Date] {
    let calendar = Calendar.current
    
    // Create the start and end dates for the year
    guard let startDate = calendar.date(from: DateComponents(year: year-1, month: 1, day: 1)),
          let endDate = calendar.date(from: DateComponents(year: year+1, month: 12, day: 31)) else {
        return []
    }
    
    var dates: [Date] = []
    var currentDate = startDate
    
    // Loop from the start date until the end date (inclusive)
    while currentDate <= endDate {
        dates.append(currentDate)
        // Advance by one day using the calendar to handle all calendar-specific adjustments
        guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
            break
        }
        currentDate = nextDate
    }
    
    return dates
}

func more365(date: Date) -> [Date] {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month, .day], from: date)
    
    // Create the start and end dates for the year
    guard let startDate = calendar.date(from: DateComponents(year: components.year, month: components.month, day: components.day)),
          let endDate = calendar.date(from: DateComponents(year: (components.year ?? 2025)+1, month: components.month, day: components.day)) else {
        return []
    }
    
    var dates: [Date] = []
    var currentDate = startDate
    
    // Loop from the start date until the end date (inclusive)
    while currentDate <= endDate {
        dates.append(currentDate)
        // Advance by one day using the calendar to handle all calendar-specific adjustments
        guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
            break
        }
        currentDate = nextDate
    }
    
    return dates
}

struct RecurringTransactionsTestView: View {
    
    @State var date1 : Date = Date()
    @State var date2 : Date = Date()
    @State var date3 : Date = Date()
    
    var body: some View {
        HStack {
            Form{
                DatePicker(selection: $date1)
                {
                    Text("H")
                }
                
                DatePicker(selection: $date2)
                {
                    Text("B")
                }
                
                DatePicker(selection: $date3)
                {
                    Text("C")
                }
            }
            Text(determinePattern(from: [Transaction(date:date1), Transaction(date:date2), Transaction(date:date3)]))
            
        }
    }
    
    /// returns exactly one patternGroup
    private func determinePattern(from transactions: [Transaction]) -> String
    {
        // Ignore repeated transactions
        let sortedTransactions = transactions.sorted { $0.date < $1.date }
            .reduce(into: [Transaction]())
            { result, transaction in
                if !result.contains(where: { $0.sameDayAs(transaction) })
                { result.append(transaction) }
            }
        guard sortedTransactions.count > 1 else
        { return "" }
        let pattern = RelationshipBetween(date1: sortedTransactions[0].date,
                                          date2: sortedTransactions[1].date)
        print(pattern.getTypeInternal() == .None)
        var patterns : [TransactionPattern] = [pattern]
        for i in 2..<sortedTransactions.count
        {
            let otherPattern = RelationshipBetween(date1: sortedTransactions[0].date,
                                                  date2: sortedTransactions[i].date)
            patterns.append(otherPattern)
            print(otherPattern.getType() != pattern.getType())
            print("Occurs on pattern", sortedTransactions[i].date, patternOccursOn(date: sortedTransactions[i].date, pattern: pattern))
        }
        print(patterns)
        return patterns.first!.getType().rawValue
    }
    
    private func patternOccursOn(date: Date, pattern: TransactionPattern) -> Bool
    {
        let beginDate = pattern.getBeginDate()
        if Calendar.current.startOfDay(for: pattern.getBeginDate()) > Calendar.current.startOfDay(for: date)
        { return false }
        switch (pattern.getType())
        {
        case .Yearly:
            var i : Int = 0
            var dateRunner : Date = beginDate
            while dateRunner <= date.addingTimeInterval(365*24*3600)
            {
                if dateRunner.sameDayAs(date)
                {
                    return i % pattern.getInterval() == 0
                }
                i += 1
                dateRunner = Calendar.current.date(byAdding: .year, value: i, to: beginDate)!
                print(dateRunner, date, dateRunner.sameDayAs(date))
            }
        case .Monthly:
            var i : Int = 0
            var dateRunner : Date = beginDate
            while dateRunner <= date.addingTimeInterval(30*24*3600)
            {
                if dateRunner.sameDayAs(date)
                {
                    return i % pattern.getInterval() == 0
                }
                i += 1
                dateRunner = Calendar.current.date(byAdding: .month, value: i, to: beginDate)!
                print(dateRunner, date, dateRunner.sameDayAs(date))
            }
        case .Weekly:
            let interval : Int = beginDate.amountOfDays(from: date)
            return interval % 7 == 0
                    && interval/7 % pattern.getInterval() == 0
        case .Custom:
            let interval : Int = beginDate.amountOfDays(from: date)
            return interval % pattern.getInterval() == 0
        }
        return false
    }
}



#Preview {
    RecurringTransactionsTestView()
}
