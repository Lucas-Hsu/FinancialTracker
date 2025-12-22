//
//  HistoryViewModel.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/22/25.
//

import Foundation
import SwiftData
import SwiftUI
import Charts

/// The bar chart calculation logic
@Observable
final class HistoryViewModel
{
    // MARK: - Observable Properties
    var chartData: [HistoryChartData] = []
    
    // MARK: - Private Properties
    @ObservationIgnored private var transactions: [Transaction] = []
    private(set) var startMonth: Date = Date()
    private(set) var endMonth: Date = Date()
    private(set) var timestep: Timestep = .months
    
    // MARK: - Init
    init()
    {
        let now = Date()
        self.endMonth = now.monthStart()
        if let lastYear = Calendar.current.date(byAdding: .year, value: -1, to: now)
        { self.startMonth = lastYear.monthStart() }
        else
        { self.startMonth = now.yearStart() }
    }
    
    // MARK: - Public Methods
    // Refresh the Transaction array
    func refreshTransactions(transactions: [Transaction])
    {
        self.transactions = transactions
    }
    // Setters with validation
    func setStartMonth(_ date: Date)
    {
        let normalized = date.monthStart()
        if normalized > endMonth
        { self.endMonth = normalized }
        self.startMonth = normalized
    }
    func setEndMonth(_ date: Date)
    {
        let normalized = date.monthStart()
        if normalized < startMonth
        { self.startMonth = normalized }
        self.endMonth = normalized
    }
    func setTimestep(_ step: Timestep)
    {
        self.timestep = step
    }
    // Generate Bar Chart Data
    func generate()
    {
        let dateFiltered = filterDate(data: transactions, startMonth: startMonth, endMonth: endMonth)
        let groupedData = group(data: dateFiltered, by: timestep)
        var results: [HistoryChartData] = []
        for (date, txs) in groupedData
        {
            let sum = txs.reduce(0) { $0 + $1.price }
            results.append(HistoryChartData(date: date, value: sum))
        }
        self.chartData = results.sorted(by: { $0.date < $1.date }) // x-axis chronological
    }
    
    // MARK: - Private Logic
    // Filter out date, range: [StartMonth, EndMonth] inclusive.
    private func filterDate(data: [Transaction], startMonth: Date, endMonth: Date) -> [Transaction]
    {
        guard let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: endMonth) else
        { return [] }
        return data.filter
        { transaction in
            let tDate = transaction.date.monthStart()
            return tDate >= startMonth.monthStart() && tDate < nextMonth.monthStart()
        }
    }
    // Group transactions by selected timestep
    private func group(data: [Transaction], by step: Timestep) -> [Date: [Transaction]]
    {
        return Dictionary(grouping: data)
        { transaction in
            let components: DateComponents
            if step == .years
            { components = Calendar.current.dateComponents([.year], from: transaction.date) }
            else
            { components = Calendar.current.dateComponents([.year, .month], from: transaction.date) }
            return Calendar.current.date(from: components) ?? transaction.date
        }
    }
}
