//
//  SelectedRecurringTransactionIDs.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 7/9/25.
//


import Foundation
import SwiftData

@Model class SelectedRecurringTransactionIDs: Equatable
{
    @Attribute(.unique) var id: UUID
    var selectedID: UUID
    
    init(selectedID: UUID)
    {
        self.id = UUID()
        self.selectedID = selectedID
    }
    
    // Conformance to Equatable
    static func == (lhs: SelectedRecurringTransactionIDs, rhs: SelectedRecurringTransactionIDs) -> Bool {
        return lhs.selectedID == rhs.selectedID
    }
}
