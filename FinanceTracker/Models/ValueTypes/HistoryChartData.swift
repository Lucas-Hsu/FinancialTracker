//
//  HistoryChartData.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/23/25.
//

import Foundation

struct HistoryChartData: Identifiable, Equatable
{
    let id = UUID()
    let date: Date
    let value: Double
}
