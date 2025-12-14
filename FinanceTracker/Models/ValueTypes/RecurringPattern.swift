//
//  RecurringPattern.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/14/25.
//

/// For categorizing transaction types
enum RecurringPattern: String, Codable
{
    case days,
         months,
         years
}
