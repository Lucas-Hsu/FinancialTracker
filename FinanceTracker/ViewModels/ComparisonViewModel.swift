//
//  ComparisonViewModel.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/21/25.
//

import Foundation
import SwiftData
import SwiftUI
import Charts

/// Provide pie chart display logic and events
@Observable
final class ComparisonViewModel
{
    // MARK: - Observable Properties
    var chartData: [PieChartData] = []
    
    // MARK: - Private Properties
    private(set) var startMonth: Date = Date()
    private(set) var endMonth: Date = Date()
    private(set) var selectedTags: Set<Tag> = Set(Tag.allCases)
    
    @ObservationIgnored private var transactions: [Transaction] = []
    
    // MARK: - Init
    init()
    {
        let now = Date()
        self.endMonth = now.monthStart()
        self.startMonth = now.yearStart()
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
    func toggleTag(_ tag: Tag)
    {
        if selectedTags.contains(tag)
        { selectedTags.remove(tag) }
        else
        { selectedTags.insert(tag) }
    }
    // Create Pie Chart
    func generate()
    {
        let tagsToFilter = selectedTags.isEmpty ? Set(Tag.allCases) : selectedTags // Select all tags if selectedTags empty
        let dateFiltered = filterDate(data: transactions, startMonth: startMonth, endMonth: endMonth)
        let tagFiltered = filterTags(data: dateFiltered, tags: tagsToFilter)
        let groupedData = grouped(data: tagFiltered)
        let totalSum = groupedData.values.reduce(0) { $0 + $1.reduce(0) { $0 + $1.price } }
        var results: [PieChartData] = []
        // Clear empty arrays
        if totalSum > 0
        {
            for (tag, txs) in groupedData
            {
                let sum = txs.reduce(0) { $0 + $1.price }
                if sum > 0
                {
                    let percentage = sum / totalSum
                    results.append(PieChartData(tag: tag, value: sum, percentage: percentage))
                }
            }
        }
        self.chartData = results.sorted(by: { $0.value > $1.value })
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
    // Filter for contains tag that is in selectedTags.
    private func filterTags(data: [Transaction], tags: Set<Tag>) -> [Transaction]
    { return data.filter { tags.contains($0.tag) } }
    // Group by Tag
    private func grouped(data: [Transaction]) -> [Tag: [Transaction]]
    {
        return Dictionary(grouping: data, by: { $0.tag })
    }
}
