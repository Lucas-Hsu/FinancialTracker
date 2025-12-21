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
    // MARK: - Observable Properties
    private(set) var predictions: [Tag: Double] = [:]
    private(set) var aggregates: [Tag: Double] = [:]
    private(set) var isLoading: Bool = false
    
    // MARK: - Private Attributes
    @ObservationIgnored private var transactions: [Transaction] = []
    @ObservationIgnored private var localCalendar: Calendar = Calendar.current
    
    // MARK: - Data Structure
    private struct MonthlyExpenditure: Identifiable
    {
        var id: Date { month }
        let month: Date
        var value: Double
    }
    
    // MARK: - Public Methods
    // Clears data when view is hidden to save memory/state
    func clear()
    {
        self.predictions = [:]
        self.aggregates = [:]
        self.transactions = []
        self.isLoading = false
    }
    // Async refresh to allow UI to show loading state
    @MainActor
    func refresh(transactions: [Transaction]) async
    {
        self.isLoading = true
        self.transactions = transactions
        let (newAggregates, newPredictions) = await Task.detached(priority: .userInitiated)
        {
            return (self.calculateMonthAggregates(data: transactions),
                    self.calculatePredictions(data: transactions))
        }.value
        self.aggregates = newAggregates
        self.predictions = newPredictions
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s delay
        self.isLoading = false
    }

    // MARK: - Private Helpers
    // Predictions for the transaction categories, only choosing months recent enough (after the cutoff)
    private func calculatePredictions(data: [Transaction], cutoff: Int = 24) -> [Tag: Double]
    {
        guard let startDate: Date = localCalendar.date(byAdding: .month, value: -cutoff, to: Date()) else
        { return [:] }
        var predictions: [Tag: Double] = [:]
        let filteredByDate: [Transaction] = filterByDate(start: startDate, data: data)
        let filteredByDateMap: [Tag:[Transaction]] = mapTransactionByTag(data: filteredByDate)
        let nowComponents: DateComponents = localCalendar.dateComponents([.year, .month], from: Date())
        guard let targetDate: Date = localCalendar.date(from: nowComponents) else
        { return [:] }
        for tag in Tag.allCases
        {
            let tagTransactions: [Transaction] = filteredByDateMap[tag] ?? []
            let aggregatedData: [MonthlyExpenditure] = aggregate(data: tagTransactions)
            let imputedData: [MonthlyExpenditure] = imputation(data: aggregatedData)
            let timeSeriesData: [Double] = timeseries(data: imputedData)
            let lastDate: Date = imputedData.last?.month ?? targetDate
            let componentsDiff: DateComponents = localCalendar.dateComponents([.month], from: lastDate, to: targetDate)
            let monthsInBetween: Int = max(1, componentsDiff.month ?? 1)
            let prediction: Double = holtWintersPredict(data: timeSeriesData, h: monthsInBetween)
            predictions[tag] = prediction
        }
        return predictions
    }
    // Calculate the total expenditure for the current month of each Tag
    private func calculateMonthAggregates(data: [Transaction]) -> [Tag: Double]
    {
        var aggregates: [Tag: Double] = [:]
        let currentMonthTransactions: [Transaction] = getThisMonthTransactions(data: data)
        for tag in Tag.allCases
        {
            let tagTransactions: [Transaction] = filterByTag(tag: tag, data: currentMonthTransactions)
            let sum: Double = tagTransactions.reduce(0) { $0 + $1.price }
            aggregates[tag] = sum
        }
        return aggregates
    }
    // Filter Transactions by date and then group into tags.
    private func filterByDate(start: Date, data: [Transaction]) -> [Transaction]
    {
        let components = localCalendar.dateComponents([.year, .month], from: Date())
        guard let startOfCurrentMonth = localCalendar.date(from: components) else
        { return [] }
        let filteredList = data.filter { $0.date >= start && $0.date < startOfCurrentMonth }
        return filteredList
    }
    // Group transactions by Tag
    private func mapTransactionByTag(data: [Transaction]) -> [Tag: [Transaction]]
    {
        var result: [Tag: [Transaction]] = [:]
        for tag in Tag.allCases { result[tag] = [] }
        for tx in data
        { result[tx.tag]?.append(tx) }
        return result
    }
    // Filter for only ones that have tags contained in selectedTags
    private func filterByTag(tag: Tag, data: [Transaction]) -> [Transaction]
    { return data.filter { $0.tag == tag } }
    // Sum of Tranasactions by month
    private func aggregate(data: [Transaction]) -> [MonthlyExpenditure]
    {
        var dict: [Date: Double] = [:]
        for transaction in data
        {
            let components = localCalendar.dateComponents([.year, .month], from: transaction.date)
            if let startOfMonth = localCalendar.date(from: components)
            { dict[startOfMonth, default: 0] += transaction.price }
        }
        let sortedKeys = dict.keys.sorted()
        return sortedKeys.map
        { date in
            MonthlyExpenditure(month: date, value: dict[date]!)
        }
    }
    // Fill in nil values by carrying-over
    private func imputation(data: [MonthlyExpenditure]) -> [MonthlyExpenditure]
    {
        guard let firstEntry = data.first, let lastEntry = data.last else
        { return [] }
        var result: [MonthlyExpenditure] = []
        var currentMonth = firstEntry.month
        let endMonth = lastEntry.month
        var lastKnownValue: Double = firstEntry.value
        let existingData = Dictionary(uniqueKeysWithValues: data.map { ($0.month, $0.value) })
        while currentMonth <= endMonth
        {
            if let value = existingData[currentMonth]
            {
                lastKnownValue = value
                result.append(MonthlyExpenditure(month: currentMonth, value: value))
            }
            else
            {
                result.append(MonthlyExpenditure(month: currentMonth, value: lastKnownValue))
            }
            guard let next = localCalendar.date(byAdding: .month, value: 1, to: currentMonth) else
            { break }
            currentMonth = next
        }
        return result
    }
    // Simplify structured data into time series
    private func timeseries(data: [MonthlyExpenditure]) -> [Double]
    { return data.map { $0.value } }
    // Get transactions from this month
    private func getThisMonthTransactions(data: [Transaction]) -> [Transaction]
    {
        let now = Date()
        let components = localCalendar.dateComponents([.year, .month], from: now)
        guard let startOfMonth = localCalendar.date(from: components),
              let nextMonth = localCalendar.date(byAdding: .month, value: 1, to: startOfMonth) else
        { return [] }
        return data.filter { $0.date >= startOfMonth && $0.date < nextMonth }
    }
    
    // MARK: - Holt-Winters Logic
    // Predict for one time series h months into the future from the end of time series
    private func holtWintersPredict(data: [Double], h: Int) -> Double
    {
        let seasonLength = 12
        let n = data.count
        if n < seasonLength * 2
        {
            guard !data.isEmpty else { return 0.0 }
            return data.reduce(0, +) / Double(n)
        }
        let alpha: Double = 0.3
        let beta: Double  = 0.1
        let gamma: Double = 0.1
        var level: Double = 0
        for i in 0..<seasonLength
        { level += data[i] }
        level /= Double(seasonLength)
        var trend: Double = 0
        for i in 0..<seasonLength
        { trend += (data[seasonLength + i] - data[i]) / Double(seasonLength) }
        trend /= Double(seasonLength)
        var seasonalIndices: [Double] = []
        for i in 0..<seasonLength
        { seasonalIndices.append(data[i] - level) }
        var currentLevel = level
        var currentTrend = trend
        for i in seasonLength..<n
        {
            let y_t = data[i]
            let s_prev = seasonalIndices[i % seasonLength]
            let nextLevel = calculateLevel(alpha: alpha, y: y_t, s: s_prev, l_prev: currentLevel, t_prev: currentTrend)
            let nextTrend = calculateTrend(beta: beta, l: nextLevel, l_prev: currentLevel, t_prev: currentTrend)
            let nextSeasonality = calculateSeasonality(gamma: gamma, y: y_t, l: nextLevel, s_prev: s_prev)
            currentLevel = nextLevel
            currentTrend = nextTrend
            seasonalIndices[i % seasonLength] = nextSeasonality
        }
        let forecastSeasonalIndex = (n + h - 1) % seasonLength
        let prediction = holtWinters(h: Double(h), L: currentLevel, T: currentLevel, S: seasonalIndices[forecastSeasonalIndex])
        return max(0, prediction)
    }
    // Holt Winters Formula
    private func holtWinters(h: Double, L: Double, T: Double, S: Double) -> Double
    { return L + h*T + S}
    // Holt Winters Level Update Formula
    private func calculateLevel(alpha: Double, y: Double, s: Double, l_prev: Double, t_prev: Double) -> Double
    { return alpha * (y - s) + (1 - alpha) * (l_prev + t_prev) }
    // Holt Winters Trend Update Formula
    private func calculateTrend(beta: Double, l: Double, l_prev: Double, t_prev: Double) -> Double
    { return beta * (l - l_prev) + (1 - beta) * t_prev }
    // Holt Winters Seasonality Update Formula
    private func calculateSeasonality(gamma: Double, y: Double, l: Double, s_prev: Double) -> Double
    { return gamma * (y - l) + (1 - gamma) * s_prev }
}
