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
        if !transactions.isEmpty
        { self.refresh(transactions: transactions) }
    }
    
    // MARK: - Public Methods
    func refresh(transactions: [Transaction])
    {
        self.transactions = transactions
        self.aggregates = calculateMonthAggregates(data: transactions)
        self.predictions = calculatePredictions(data: transactions)
    }

    // MARK: - Compute Methods
    // Update the prediction for this month of transactions of each tag
    private func calculatePredictions(data: [Transaction], cutoff: Int = 24) -> [Tag: Double]
    {
        guard let startDate = localCalendar.date(byAdding: .month, value: -cutoff, to: Date()) else
        { return [:] }
        var predictions: [Tag: Double] = [:]
        let filteredByDateMap = filterByDate(start: startDate, data: data)
        let nowComponents = localCalendar.dateComponents([.year, .month], from: Date())
        guard let targetDate = utcCalendar.date(from: nowComponents) else
        { return [:] }
        for tag in Tag.allCases
        {
            let tagTransactions = filteredByDateMap[tag] ?? []
            let aggregatedData = aggregate(data: tagTransactions)
            let imputedData = imputation(data: aggregatedData)
            let timeSeriesData = timeseries(data: imputedData)
            let lastDate = imputedData.last?.month ?? targetDate
            let componentsDiff = utcCalendar.dateComponents([.month], from: lastDate, to: targetDate)
            let monthsInBetween = max(1, componentsDiff.month ?? 1)
            let prediction = holtWintersPredict(data: timeSeriesData, h: monthsInBetween)
            predictions[tag] = prediction
        }
        return predictions
    }
    // Update the monthly total for each tag transactions
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
    
    // MARK: - Private Methods
    // MARK: Helper Methods
    // Filter for transactions newer than start date.
    private func filterByDate(start: Date, data: [Transaction]) -> [Tag: [Transaction]]
    {
        let components = localCalendar.dateComponents([.year, .month], from: Date())
        guard let startOfCurrentMonth = localCalendar.date(from: components) else
        { return [:] }
        let filteredList = data.filter
        { transaction in
            return transaction.date >= start && transaction.date < startOfCurrentMonth
        }
        var result: [Tag: [Transaction]] = [:]
        for tag in Tag.allCases
        { result[tag] = filterByTag(tag: tag, data: filteredList) }
        return result
    }
    // Filter for only transactions with selected tag
    private func filterByTag(tag: Tag, data: [Transaction]) -> [Transaction]
    { return data.filter { $0.tag == tag } }
    // Groups transactions by month and get monthly sum of transaction prices.
    private func aggregate(data: [Transaction]) -> [MonthlyExpenditure]
    {
        var dict: [Date: Double] = [:]
        for transaction in data
        {
            let components = localCalendar.dateComponents([.year, .month], from: transaction.date)
            if let startOfMonth = utcCalendar.date(from: components)
            { dict[startOfMonth, default: 0] += transaction.price }
        }
        let sortedKeys = dict.keys.sorted()
        return sortedKeys.map
        { date in
            MonthlyExpenditure(month: date, value: dict[date]!)
        }
    }
    // Impute months with no data by carrying-over
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
            guard let next = utcCalendar.date(byAdding: .month, value: 1, to: currentMonth) else
            { break }
            currentMonth = next
        }
        return result
    }
    // Converts structured data into plain timeseries
    private func timeseries(data: [MonthlyExpenditure]) -> [Double]
    { return data.map { $0.value } }
    // Filter for only transactions that were made this month
    private func getThisMonthTransactions(data: [Transaction]) -> [Transaction]
    {
        let now = Date()
        let components = localCalendar.dateComponents([.year, .month], from: now)
        guard let startOfMonth = localCalendar.date(from: components),
              let nextMonth = localCalendar.date(byAdding: .month, value: 1, to: startOfMonth) else
        { return [] }
        return data.filter { $0.date >= startOfMonth && $0.date < nextMonth }
    }
    // Predicts the value at n + h using Additive Holt-Winters.
    private func holtWintersPredict(data: [Double], h: Int) -> Double
    {
        let seasonLength = 12
        let n = data.count
        if n < seasonLength + 1 // At least one full season + 1 data point to start smoothing prediction
        {
            guard !data.isEmpty else { return 0.0 }
            return data.reduce(0, +) / Double(n) // Fallback to simple averaging
        }
        // Hyperparameters
        let alpha: Double = 0.3 // Level
        let beta: Double  = 0.1 // Trend
        let gamma: Double = 0.1 // Seasonality
        
        // Initialize based on first season
        // Calculate Average(Level)
        var level: Double = 0
        for i in 0..<seasonLength
        { level += data[i] }
        level /= Double(seasonLength)
        // Calculate Slope(Trend)
        var trend: Double = 0
        for i in 0..<seasonLength
        { trend += (data[seasonLength + i] - data[i]) / Double(seasonLength) }
        trend /= Double(seasonLength)
        // Calculate Additive Seasonality
        var seasonalIndices: [Double] = []
        for i in 0..<seasonLength
        { seasonalIndices.append(data[i] - level) }
        
        // Process Remaining Data
        // y_t: Actual value at month t
        // s_prev: Seasonality of this month from previous cycle (t-s)
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
            seasonalIndices[i % seasonLength] = nextSeasonality // Overwrites seasonality indices because we only need most recent
        }
        
        // Holt-Winters Seasonal Model
        // prediction_{n + h} = L_t + h*T_t + S_{t+h-s}
        let forecastSeasonalIndex = (n + h - 1) % seasonLength
        let prediction = holtWinters(h: Double(h), L: currentLevel, T: currentLevel, S: seasonalIndices[forecastSeasonalIndex])
        return max(0, prediction)
    }
    // MARK: Math Formulas
    // prediction_{n + h} = L_t + h*T_t + S_{t+h-s}
    private func holtWinters(h: Double, L: Double, T: Double, S: Double) -> Double
    { return L + h*T + S}
    // L_t (Base) = alpha(Y_t - S_{t-s}) + (1-alpha)(L_{t-1} + T_{t-1})
    private func calculateLevel(alpha: Double, y: Double, s: Double, l_prev: Double, t_prev: Double) -> Double
    { return alpha * (y - s) + (1 - alpha) * (l_prev + t_prev) }
    // T_t (Trend) = beta(L_t - L_{t-1}) + (1-beta)T_{t-1}
    private func calculateTrend(beta: Double, l: Double, l_prev: Double, t_prev: Double) -> Double
    { return beta * (l - l_prev) + (1 - beta) * t_prev }
    // S_t (Seasonality) = gamma(Y_t - L_t) + (1-gamma)S_{t-s}
    private func calculateSeasonality(gamma: Double, y: Double, l: Double, s_prev: Double) -> Double
    { return gamma * (y - l) + (1 - gamma) * s_prev }
}
