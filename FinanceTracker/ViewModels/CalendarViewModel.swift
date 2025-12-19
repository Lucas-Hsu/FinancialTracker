//
//  CalendarViewModel.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/16/25.
//

import Foundation
import SwiftUI
import SwiftData

/// Provide calendar display logic and events
@Observable
final class CalendarViewModel
{
    // MARK: - Public Properties
    private(set) var selectedDay: Int? = nil
    private(set) var eventsForSelectedDay: [RecurringTransaction] = []
    private(set) var isLoading: Bool = true
    private(set) var currentMonth: Date = Date()
    
    // MARK: - Computed Properties
    var weekdays: [String]
    {
        let symbols = calendar.shortWeekdaySymbols
        let firstWeekday = calendar.firstWeekday
        return Array(symbols[firstWeekday-1..<symbols.count] + symbols[0..<firstWeekday-1])
    }
    
    // MARK: - Private Properties
    @ObservationIgnored private let calendar = Calendar.current
    @ObservationIgnored private let modelContext: ModelContext
    
    // MARK: - Initialization
    init(modelContext: ModelContext)
    {
        self.modelContext = modelContext
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
        { self.isLoading = false }
    }
    
    // MARK: - Public Methods
    // Return a 2D array representing days in the month grid
    func getMonthGrid() -> [[Int]]
    {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else
        { return [] }
        let startDate = monthInterval.start
        let numberOfDays = calendar.range(of: .day, in: .month, for: startDate)?.count ?? 0
        // (Sun or Mon)
        guard let firstWeekday = calendar.dateComponents([.weekday], from: startDate).weekday else
        { return [] }
        // Add padding at the start
        let firstWeekdayOfCalendar = calendar.firstWeekday
        let startPadding: Int
        if firstWeekday >= firstWeekdayOfCalendar
        { startPadding = firstWeekday - firstWeekdayOfCalendar }
        else
        { startPadding = 7 - (firstWeekdayOfCalendar - firstWeekday) }
        // Total cells needed (always 6 weeks)
        let totalCells = 6 * 7
        let daysArray = Array(1...numberOfDays)
        // Full array with padding
        var gridArray: [Int] = []
        gridArray.append(contentsOf: Array(repeating: 0, count: startPadding))
        gridArray.append(contentsOf: daysArray)
        gridArray.append(contentsOf: Array(repeating: 0, count: totalCells - gridArray.count))
        // To 2D array
        return gridArray.chunked(into: 7)
    }
    // Days of the month that have events
    func getDaysWithEvents() -> [Int]
    {
        var daysWithEvents: [Int] = []
        for day in daysInMonth()
        {
            if hasEvent(day: day)
            { daysWithEvents.append(day) }
        }
        return daysWithEvents
    }
    // Find a Transaction that matches RecurringTransaction
    func findTransaction(matches recurringTransaction: RecurringTransaction, selectedDate: Date) -> [Transaction: Bool]
    {
        let filteredTransaction = filterForTransactions(name: recurringTransaction.name, tag: Tag(recurringTransaction.tag))
        for transaction in filteredTransaction
        {
            if !recurringTransaction.isOccursOn(date: transaction.date)
            { continue }
            if selectedDate.startOfDay() != transaction.date.startOfDay()
            { continue }
            return [transaction: false]
        }
        guard let dayInt = selectedDay,
              let dayDate = getDateOfDay(dayInt) else
        {
            return [Transaction(date: Date(),
                               name: recurringTransaction.name,
                               price: 0,
                               tag: Tag(recurringTransaction.tag),
                               isPaid: false,
                               notes: [],
                                receiptImage: nil):
                        true]
        }
        return [Transaction(date: dayDate,
                           name: recurringTransaction.name,
                           price: 0,
                           tag: Tag(recurringTransaction.tag),
                           isPaid: false,
                           notes: [],
                            receiptImage: nil):
                    true]
    }
    // day is today's date
    func isToday(_ day: Int) -> Bool
    {
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        let currentComponents = calendar.dateComponents([.year, .month], from: currentMonth)
        
        guard let currentYear = currentComponents.year,
              let currentMonthNum = currentComponents.month,
              let todayYear = todayComponents.year,
              let todayMonth = todayComponents.month,
              let todayDay = todayComponents.day else
        { return false }
        
        return currentYear == todayYear &&
               currentMonthNum == todayMonth &&
               day == todayDay
    }
    
    // Controls
    func nextMonth()
    {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        selectedDay = nil
        eventsForSelectedDay = []
    }
    func previousMonth()
    {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        selectedDay = nil
        eventsForSelectedDay = []
    }
    func resetMonth()
    {
        currentMonth = Date()
        selectedDay = nil
        eventsForSelectedDay = []
    }
    
    // Selection
    func selectDay(_ day: Int)
    {
        selectedDay = day
        eventsForSelectedDay = getEvents(day: day)
    }
    func clearSelection()
    {
        selectedDay = nil
        eventsForSelectedDay = []
    }
    
    // MARK: - Helper Methods
    func isSelectedDay(_ day: Int) -> Bool
    {
        return selectedDay == day
    }
    func hasEventsOnDay(_ day: Int) -> Bool
    {
        return getDaysWithEvents().contains(day)
    }
    
    func getDateOfDay(_ day: Int) -> Date?
    {
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let year = components.year,
              let month = components.month else
        { return nil }
        
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        
        return calendar.date(from: dateComponents)
    }
    
    // MARK: - Private Helpers
    // Check if events do happen on a certain day
    private func hasEvent(day: Int) -> Bool
    {
        let year = calendar.component(.year, from: currentMonth)
        let month = calendar.component(.month, from: currentMonth)
        guard let selectedDay = calendar.date(from: DateComponents(year: year, month: month, day: day))?.startOfDay() else
        { return false }
        let recurringTransactions: [RecurringTransaction] = fetchRecurringTransactions()
        for recurringTransaction in recurringTransactions
        {
            if selectedDay.startOfDay() < recurringTransaction.startDate.startOfDay()
            { continue }
            else if selectedDay.startOfDay() == recurringTransaction.startDate.startOfDay()
            { return true }
            guard let rT = RecurringPatternRecognition.findRecurringTransaction(dates: [recurringTransaction.startDate, selectedDay]) else
            { continue }
            if rT.pattern != recurringTransaction.pattern
            { continue }
            if rT.interval < recurringTransaction.interval
            { continue }
            if rT.interval % recurringTransaction.interval != 0
            { continue }
            return true
        }
        return false
    }
    // Get recurringTransactions that occur on a certain day
    private func getEvents(day: Int) -> [RecurringTransaction]
    {
        let year = calendar.component(.year, from: currentMonth)
        let month = calendar.component(.month, from: currentMonth)
        guard let selectedDay = calendar.date(from: DateComponents(year: year, month: month, day: day))?.startOfDay() else
        { return [] }
        let recurringTransactions: [RecurringTransaction] = fetchRecurringTransactions()
        var matchingRecurringTransactions: [RecurringTransaction] = []
        for recurringTransaction in recurringTransactions
        {
            if selectedDay.startOfDay() < recurringTransaction.startDate.startOfDay()
            { continue }
            else if selectedDay.startOfDay() == recurringTransaction.startDate.startOfDay()
            {
                matchingRecurringTransactions.append(recurringTransaction)
                continue
            }
            guard let rT = RecurringPatternRecognition.findRecurringTransaction(dates: [recurringTransaction.startDate, selectedDay]) else
            { continue }
            if rT.pattern != recurringTransaction.pattern
            { continue }
            if rT.interval < recurringTransaction.interval
            { continue }
            if rT.interval % recurringTransaction.interval != 0
            { continue }
            matchingRecurringTransactions.append(recurringTransaction)
        }
        return matchingRecurringTransactions
    }
    // Get RecurringTransactions from ModelContext
    private func fetchRecurringTransactions() -> [RecurringTransaction]
    {
        do
        {
            let descriptor = FetchDescriptor<RecurringTransaction>()
            return try modelContext.fetch(descriptor)
        }
        catch
        {
            print("Failed to fetch RecurringTransactions: \(error)")
            return []
        }
    }
    // Filter for wanted transactions
    private func filterForTransactions(name: String, tag: Tag) -> [Transaction]
    {
        let transactions: [Transaction] = fetchTransactions()
        var filteredTransactions: [Transaction] = []
        for transaction in transactions
        {
            if transaction.name == name && transaction.tag == tag
            {
                filteredTransactions.append(transaction)
            }
        }
        return filteredTransactions
    }
    // Get Transactions from ModelContext
    private func fetchTransactions() -> [Transaction]
    {
        do
        {
            let descriptor = FetchDescriptor<Transaction>()
            return try modelContext.fetch(descriptor)
        }
        catch
        {
            print("Failed to fetch Transactions: \(error)")
            return []
        }
    }
    // Get days in month
    private func daysInMonth() -> Range<Int>
    {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth) else
        { return 0..<0 }
        return range
    }
}
