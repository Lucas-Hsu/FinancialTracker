//
//  TransactionListView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 2/1/25.
//

import SwiftUI
import SwiftData

import Foundation



struct TransactionListView: View {
    // Assuming you have a @Query to fetch your transactions from the SwiftData store
    @Query(sort: \Transaction.date, order: .reverse) var transactions: [Transaction]

    var groupedTransactions: [String: [Transaction]] {
        // Group transactions by the same date (year-month-day)
        Dictionary(grouping: transactions) { transaction in
            let calendar = Calendar.current
            let dateString = calendar.dateComponents([.year, .month, .day], from: transaction.date)
            return "\(dateString.year!) \(dateString.month!) \(dateString.day!)" // Format as "YEAR MONTH DAY"
        }
    }

    var body: some View {
        HStack {
            
            AddNew()
            
            List {
                // Iterate over the grouped transactions
                ForEach(groupedTransactions.keys.sorted(by: >), id: \.self) { key in
                    Section(header: Text(key).font(.headline)) {
                        // For each group of transactions, display a list of transactions
                        ForEach(groupedTransactions[key]!, id: \.id) { transaction in
                            TransactionView(transaction: transaction)
                        }
                    }
                }
            }
            .navigationTitle("Transactions")
        }
    }
}

struct TransactionListView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionListView()
            .modelContainer(for: Transaction.self, inMemory: true)
    }
}
