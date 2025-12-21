//
//  PieChartData.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/21/25.
//

struct PieChartData: Identifiable, Equatable
{
    var id: Tag { tag }
    let tag: Tag
    let value: Double
    let percentage: Double
}
