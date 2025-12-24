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
    @State var transaction: Transaction
    
    init(transaction: Transaction)
    { self.transaction = transaction }
    
    var body: some View
    { TransactionDetailsView(transaction: $transaction, type: .modify) }
}

#Preview
{ ModifyOld(transaction: Transaction(date: Date(),
                                               name: "Test",
                                               tag: Tag.food,
                                               price: 1.00, paid: true)) }
