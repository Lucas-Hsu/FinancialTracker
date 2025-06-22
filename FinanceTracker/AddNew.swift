//
//  AddNew.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 1/31/25.
//

import SwiftUI

/// A class that handles adding new transactions.
struct AddNew: View
{
    @State private var transaction: Transaction = Transaction()

    init(date: Date = Date(),
         name: String = "",
         tag: String = Tag.other.rawValue,
         price: Double = 19.99,
         paid: Bool = true,
         notes: [String]? = nil,
         image: Data? = Data())
    {
        transaction = Transaction(date: date,
                                  name: name,
                                  tag: tag,
                                  price: price,
                                  paid: paid,
                                  notes: notes,
                                  image: image)
    }
    
    var body: some View
    { TransactionDetailsView(transaction: $transaction) }
}

#Preview
{ AddNew() }
