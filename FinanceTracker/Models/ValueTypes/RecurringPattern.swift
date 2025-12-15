//
//  RecurringPattern.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/14/25.
//

/// For categorizing transaction types
enum RecurringPattern: String, Identifiable, Codable
{
    var id: String { self.rawValue }
    case days,
         months,
         years
}
