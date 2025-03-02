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
            Text(name)
            .padding()
            Spacer()
            Text(date.formatted(.dateTime.year().month(.abbreviated).day(.twoDigits)))
            .padding()
            Spacer()
            Text(type)
            .padding()
            Spacer()
            Text(interval.description)
            .padding()
            Spacer()
            Button("Add") {
                addRecurringTransaction(date: date, name: name, type: type, interval: interval, tag: tag, price: price)
            }
            .buttonStyle(.bordered)
            .padding()
        }
        .frame(minWidth: 0, maxWidth: 600, maxHeight: 80)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
    }
    
    private func addRecurringTransaction(date: Date,name: String, type: String, interval: Int, tag: String, price: Double) {
        let newTransaction = RecurringTransaction(
            date: date,
            intervalType: type,
            interval: interval,
            name: name,
            tag: tag,
            price: price
        )
        
        modelContext.insert(newTransaction)
    }
}

