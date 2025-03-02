//
//  Suggestions.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 2/24/25.
//

import SwiftUI
import SwiftData
struct Suggestions: View {
    
    @Query(sort: \Transaction.name, order: .forward) var transactions: [Transaction]
    @Query(sort: \RecurringTransaction.name, order: .forward) var recurringTransactions: [RecurringTransaction]
    @State var categoree: [String:[Transaction]] = [:]
    
    // Update `categoree` when `transactions` changes
    var body: some View {
        
        HStack {
            
            Text(recurringTransactions.description)
            
            VStack {
                if transactions.isEmpty {
                    VStack {
                        Text("No transactions logged yet")
                        AddRecurringTile(transactions: [Transaction(date: Date()),
                                                        Transaction(date: Date().advanced(by: 24*3600*7)),
                                                        Transaction(date: Date().advanced(by: 24*3600*14))])
                    }
                } else if transactions.count < 3 {
                    Text ("Not enough transactions to suggest categories")
                } else {
                    Text(categoree.description)
                    ForEach(categoree.keys.sorted(), id: \.self) { key in
                        if RecurringTransaction.HasRelationship(transactions: categoree[key] ?? []) {
                            AddRecurringTile(transactions: categoree[key] ?? [])
                        }
                    }
                }
            }
            .onChange(of: transactions) {
                update()
            }
        }
    }
    
    // Update categoree with the latest categorize result
    public func update() {
        categoree = categorize()
        categoree = categoree.mapValues { transactions in
            transactions.sorted { $0.date < $1.date }
        }
        
        // Group your transactions first.
        let categorizedTransactions = categoree

        // Iterate over the dictionary and print the group key along with each transaction.
        for (groupKey, transactions) in categorizedTransactions {
            print("Group: \(groupKey)")
            for transaction in transactions {
                print("  - Name: \(transaction.name), Price: \(transaction.price), Tag: \(transaction.tag), Date: \(transaction.date)")
            }
        }
    }
    
    func categorize() -> [String: [Transaction]] {
        Dictionary(grouping: transactions) { transaction in
            "\(transaction.name)\(transaction.price)\(transaction.tag)"
        }
    }
    
    
}

private func getType(transactions: [Transaction]) -> String {
    return toType(str: RecurringTransaction.PrintRelationship(transactions: transactions))
}

private func getInterval(transactions: [Transaction]) -> Int {
    return toInterval(str: RecurringTransaction.PrintRelationship(transactions: transactions))
}

private func toDates(transactions: [Transaction]) -> [Date] {
    if transactions == [] {
        return []
    }
    var dates: [Date] = []
    for i in 0..<transactions.count {
        dates.append(transactions[i].date)
    }
    return dates
}

private func printDictionary(_ dictionary: [String:[Transaction]]) -> String {
    var output: String = ""
    for (key, value) in dictionary {
        output += "\(key):\n" + RecurringTransaction.PrintRelationship(transactions: value.sorted(by: {$0.date < $1.date}))
        for i in 0..<value.count {
            output += "\t\(value[i].toString())\n"
        }
    }
    return output
}

#Preview {
    Suggestions().modelContainer(for: RecurringTransaction.self, inMemory: true)
}



