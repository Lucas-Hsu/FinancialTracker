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
    @Query var recurringTransactions: [RecurringTransaction]
    
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
        
        Button(action: {
            if (isInContext(recurringTransaction: constructRecurringTransaction())) {
                deleteRecurringTransaction()
            } else {
                addRecurringTransaction()
            }
        }) {
            Text(isInContext(recurringTransaction: constructRecurringTransaction()) ? "Delete" : "Add").padding(8)
                .padding(.horizontal, 8)
                .frame(width: 100, height: 40)
                .background{
                    if (isInContext(recurringTransaction: constructRecurringTransaction())) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.red.opacity(0.4))
                            .blur(radius: 4)
                            .opacity(1)
                    } else {
                            RoundedRectangle(cornerRadius: 6)
                            .fill(.ultraThickMaterial)
                                .blur(radius: 4)
                                .opacity(1)
                    }
                }
        }
        .buttonStyle(ScaleButtonStyle())
        .foregroundStyle(isInContext(recurringTransaction: constructRecurringTransaction()) ? Color.red : Color.accentColor)
        .padding()
        

        
        /*
        if (isInContext(recurringTransaction: constructRecurringTransaction())) {
            Button (action: {
                deleteRecurringTransaction()
            }) {
                Text("Delete").padding(8)
                    .padding(.horizontal, 8)
            }
            .foregroundStyle(Color.accentColor)
            .plainFill(material: .ultraThickMaterial, opacity: 1, cornerRadius: 4)
            .padding()
            .buttonStyle(ScaleButtonStyle())
        } else {
            Button (action: {
                addRecurringTransaction()
            }) {
                Text("Add").padding(8)
                    .padding(.horizontal, 8)
            }
            .foregroundStyle(Color.accentColor)
            .plainFill(material: .ultraThickMaterial, opacity: 1, cornerRadius: 4)
            .padding()
            .buttonStyle(ScaleButtonStyle())
        }
         */
        
    }
    .frame(minWidth: 0, maxWidth: 600, maxHeight: 80)
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
    
    private func deleteRecurringTransaction() {
        let newRecurringTransaction = constructRecurringTransaction()
        print("Deleting Recurring Transaction")
        if let existingTransaction = self.recurringTransactions.first(where: { $0 == newRecurringTransaction }) {
            modelContext.delete(existingTransaction)
            print("Deleted existing transaction")
        }
    }
    
    private func constructRecurringTransaction() -> RecurringTransaction {
        return RecurringTransaction(
            date: transactions.first?.date ?? Date(),
            intervalType: getType(transactions: transactions),
            interval: getInterval(transactions: transactions),
            name: transactions.first?.name ?? "Recurring Transaction",
            tag: transactions.first?.tag ?? "Other",
            price: transactions.first?.price ?? 0.00
        )
    }
    
    private func isInContext(recurringTransaction: RecurringTransaction) -> Bool {
        if (recurringTransactions.contains(recurringTransaction)) {
            return true
        }
        return false
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
