//
//  ModifyOld.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 6/22/25.
//

import SwiftUI

/// A class that handles modifying existing new transactions.
struct ModifyOld: View
{
    @Binding var transaction: Transaction
    
    init(transaction: Binding<Transaction>)
    { _transaction = transaction }
    
    var body: some View
    { TransactionDetailsView(transaction: $transaction, type: .modify) }
}

#Preview
{ ModifyOld(transaction: .constant(Transaction(date: Date(),
                                               name: "Test",
                                               tag: Tag.food.rawValue,
                                               price: 1.00, paid: true))) }
