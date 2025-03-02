//
//  AddRecurring.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 3/2/25.
//

import SwiftUI
import SwiftData
 
struct AddRecurringTile: View {
    @Environment(\.modelContext) private var modelContext

    @State var transactions: [Transaction] = []
    @State var date: Date = Date()
    @State var name: String = "Recurring Transaction"
    @State var type: String = "Custom"
    @State var interval: Int = 0
    @State var tag: String = "Other"
    @State var price: Double = 0.00

    let patterns: [(type: String, interval: Int)] = [
    ("Daily", 1),
    ("Weekly", 7),
    ("Monthly", 30),
    ("Yearly", 365)
    ]
    var body: some View {
    HStack {
        Text(transactions.first?.name ?? "Recurring Transaction")
        .padding()
        Spacer()
        Text(transactions.first?.date.formatted(.dateTime.year().month(.abbreviated).day(.twoDigits)) ?? "0000/MMM./00")
        .padding()
        Spacer()
        Text(getType(transactions: transactions))
        .padding()
        Spacer()
        Text(getInterval(transactions: transactions).description)
        .padding()
        Spacer()
        Button("Add") {
            addRecurringTransaction()
        }
        .buttonStyle(.bordered)
        .padding()
    }
    .frame(minWidth: 0, maxWidth: 600, maxHeight: 80)
    .background(Color.gray.opacity(0.1))
    .cornerRadius(20)
    }

    private func addRecurringTransaction() {
        print("Adding Recurring Transaction")
    let newTransaction = RecurringTransaction(
        date: transactions.first?.date ?? Date(),
        intervalType: getType(transactions: transactions),
        interval: getInterval(transactions: transactions),
        name: transactions.first?.name ?? "Recurring Transaction",
        tag: transactions.first?.tag ?? "Other",
        price: transactions.first?.price ?? 0.00
    )

    modelContext.insert(newTransaction)
    }
}


private func getType(transactions: [Transaction]) -> String {
    return toType(str: RecurringTransaction.PrintRelationship(transactions: transactions))
}

private func getInterval(transactions: [Transaction]) -> Int {
    return toInterval(str: RecurringTransaction.PrintRelationship(transactions: transactions))
}

#Preview {
    Suggestions().modelContainer(for: RecurringTransaction.self, inMemory: true)
}
