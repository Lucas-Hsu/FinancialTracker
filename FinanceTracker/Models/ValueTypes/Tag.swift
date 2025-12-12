//
//  Tag.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 2/1/25.
//

/// For categorizing transaction types
enum Tag: String, CaseIterable, Identifiable, Codable
{
    var id: String { self.rawValue }
    case clothing,
         commute,
         education,
         entertainment,
         food,
         other
}
