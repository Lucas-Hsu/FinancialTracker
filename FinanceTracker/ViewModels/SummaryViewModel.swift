//
//  SummaryViewModel.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/21/25.
//

import Foundation
import SwiftData
import SwiftUI

/// Generates spending predictions using Holt-Winters (Level + Trend + Seasonality) smoothing.
@Observable
final class SummaryViewModel
{
    // MARK: - Observable Computed Attribute Wrappers
    private(set) var predictions: [Tag: Double]
    private(set) var aggregates: [Tag: Double]
    
    // MARK: - Private Attributes
    @ObservationIgnored private var transactions: [Transaction]
    @ObservationIgnored private var localCalendar: Calendar = Calendar.current
    @ObservationIgnored private var utcCalendar: Calendar
    {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone.current
        return calendar
    }
    
    // MARK: - Data Structure
    private struct MonthlyExpenditure: Identifiable
    {
        var id: Date { month }
        let month: Date
        var value: Double
    }
    
    // MARK: - Constructor
    init(transactions: [Transaction])
    {
        self.transactions = transactions
        self.aggregates = [:]
        self.predictions = [:]
    }
    
    // MARK: - Public Methods
    func refresh(transactions: [Transaction])
    {
        self.transactions = transactions
        self.aggregates = calculateMonthAggregates(data: transactions)
        self.predictions = calculatePredictions(data: transactions)
    }

    // MARK: - Compute Methods
    private func calculatePredictions(data: [Transaction], cutoff: Int = 24) -> [Tag: Double]
    {
        guard let startDate = localCalendar.date(byAdding: .month, value: -cutoff, to: Date()) else
        { return [:] }
        var predictions: [Tag: Double] = [:]
        let filteredByDateMap = filterByDate(start: startDate, data: data)
        for tag in Tag.allCases
        {
            let tagTransactions = filteredByDateMap[tag] ?? []
            let aggregatedData = aggregate(data: tagTransactions)
            let imputedData = imputation(data: aggregatedData)
            let timeSeriesData = timeseries(data: imputedData)
            let prediction = holtWinters(data: timeSeriesData)
            predictions[tag] = prediction
        }
        return predictions
    }
    
    private func calculateMonthAggregates(data: [Transaction]) -> [Tag: Double]
    {
        var aggregates: [Tag: Double] = [:]
        let currentMonthTransactions = getThisMonthTransactions(data: data)
        for tag in Tag.allCases
        {
            let tagTransactions = filterByTag(tag: tag, data: currentMonthTransactions)
            let sum = tagTransactions.reduce(0) { $0 + $1.price }
            aggregates[tag] = sum
        }
        return aggregates
    }
    
    // MARK: - Private Helper Methods
    private func filterByDate(start: Date, data: [Transaction]) -> [Tag: [Transaction]]
    {
        let components = localCalendar.dateComponents([.year, .month], from: Date())
        guard let startOfCurrentMonth = localCalendar.date(from: components) else { return [:] }
        
        let filteredList = data.filter { transaction in
            return transaction.date >= start && transaction.date < startOfCurrentMonth
        }
        
        var result: [Tag: [Transaction]] = [:]
        for tag in Tag.allCases {
            result[tag] = filterByTag(tag: tag, data: filteredList)
        }
        return result
    }
    
    private func filterByTag(tag: Tag, data: [Transaction]) -> [Transaction] {
        return data.filter { $0.tag == tag }
    }
    
    private func aggregate(data: [Transaction]) -> [MonthlyExpenditure] {
        var dict: [Date: Double] = [:]
        
        for transaction in data {
            let components = localCalendar.dateComponents([.year, .month], from: transaction.date)
            if let startOfMonth = utcCalendar.date(from: components)
            {
                dict[startOfMonth, default: 0] += transaction.price
            }
        }
        
        let sortedKeys = dict.keys.sorted()
        return sortedKeys.map { date in
            MonthlyExpenditure(month: date, value: dict[date]!)
        }
    }
    
    private func imputation(data: [MonthlyExpenditure]) -> [MonthlyExpenditure] {
        guard let firstEntry = data.first, let lastEntry = data.last else { return [] }
        
        var result: [MonthlyExpenditure] = []
        var currentMonth = firstEntry.month
        let endMonth = lastEntry.month
        var lastKnownValue: Double = firstEntry.value
        
        let existingData = Dictionary(uniqueKeysWithValues: data.map { ($0.month, $0.value) })
        
        while currentMonth <= endMonth {
            if let value = existingData[currentMonth] {
                lastKnownValue = value
                result.append(MonthlyExpenditure(month: currentMonth, value: value))
            } else {
                result.append(MonthlyExpenditure(month: currentMonth, value: lastKnownValue))
            }
            guard let next = localCalendar.date(byAdding: .month, value: 1, to: currentMonth) else { break }
            currentMonth = next
        }
        print(result)
        return result
    }
    
    private func timeseries(data: [MonthlyExpenditure]) -> [Double] {
        return data.map { $0.value }
    }
    
    private func holtWinters(data: [Double]) -> Double {
        let seasonLength = 12
        let n = data.count
        
        if n < seasonLength + 1 {
            guard !data.isEmpty else { return 0.0 }
            return data.reduce(0, +) / Double(n)
        }
        
        let alpha: Double = 0.3
        let beta: Double  = 0.1
        let gamma: Double = 0.1
        
        var level: Double = 0
        for i in 0..<seasonLength { level += data[i] }
        level /= Double(seasonLength)
        
        var trend: Double = 0
        for i in 0..<seasonLength {
            trend += (data[seasonLength + i] - data[i]) / Double(seasonLength)
        }
        trend /= Double(seasonLength)
        
        var seasonalIndices: [Double] = []
        for i in 0..<seasonLength {
            seasonalIndices.append(data[i] - level)
        }
        
        var currentLevel = level
        var currentTrend = trend
        
        for i in seasonLength..<n {
            let actualValue = data[i]
            let lastLevel = currentLevel
            let lastTrend = currentTrend
            let seasonalIndex = seasonalIndices[i % seasonLength]
            
            currentLevel = alpha * (actualValue - seasonalIndex) + (1 - alpha) * (lastLevel + lastTrend)
            currentTrend = beta * (currentLevel - lastLevel) + (1 - beta) * lastTrend
            let newSeasonalIndex = gamma * (actualValue - currentLevel) + (1 - gamma) * seasonalIndex
            seasonalIndices[i % seasonLength] = newSeasonalIndex
        }
        
        let forecastIndex = (n) % seasonLength
        let prediction = currentLevel + currentTrend + seasonalIndices[forecastIndex]
        
        return max(0, prediction)
    }
    
    private func getThisMonthTransactions(data: [Transaction]) -> [Transaction] {
        let now = Date()
        let components = localCalendar.dateComponents([.year, .month], from: now)
        
        guard let startOfMonth = localCalendar.date(from: components),
              let nextMonth = localCalendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
            return []
        }
        
        return data.filter { $0.date >= startOfMonth && $0.date < nextMonth }
    }
}
