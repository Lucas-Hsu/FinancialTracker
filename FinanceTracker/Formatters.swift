//
//  Formatters.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 6/22/25.
//

import Foundation


// MARK: To String
func formatDateShort(_ date: Date) -> String
{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd" // "2025-01-12"
    return dateFormatter.string(from: date)
}

func formatPrice(_ price: Double) -> String
{
    let formatter = NumberFormatter()
    formatter.locale=Locale(identifier: "cn_CN")
    formatter.numberStyle = .currency
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2
    return formatter.string(from: NSNumber(value: price)) ?? "0.00"
}

// MARK: From String
func toDate(from dateString: String) -> Date
{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    return dateFormatter.date(from: dateString) ?? Date()
}
