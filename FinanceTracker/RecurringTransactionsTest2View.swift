//
//  RecurringTransactionsTest2View.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 3/2/25.
//

import SwiftUI
import SwiftData
import Foundation

struct RecurringTransactionsTest2View: View {
    
    @Environment(\.modelContext) var modelContext
    
    @State var date1: Date = Date()
    @State var date2: Date = Date()
    @State var date3: Date = Date()
    
    @State var pattern: String = ""

    var body: some View {
        HStack {
            
            VStack{
                Text(pattern)
                
                let allDays: [Date] = more365(date: date1)
                List(allDays, id: \.self) { date in
                    if RecurringTransaction.matchesPattern(date: date, pattern: pattern, initialDate: date1) {
                            Text("\(date)")
                        }
                }
                
            }
            
            VStack {
                Form {
                    Section(header: Text("Transaction Record")) {
                        DatePicker(
                            "Enter Date1",
                            selection: $date1,
                            displayedComponents: .date
                        )
                        .padding()
                        
                        DatePicker(
                            "Enter Date2",
                            selection: $date2,
                            displayedComponents: .date
                        )
                        .padding()
                        
                        DatePicker(
                            "Enter Date3",
                            selection: $date3,
                            displayedComponents: .date
                        )
                        .padding()
                    }
                }
                Button(action: {
                    
                    pattern = RecurringTransaction.PrintRelationship(dates: [date1, date2, date3])
                    
                }) {
                    HStack {
                        Text("Submit")
                            .font(.headline)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
                }
            }
            
            
        }
    }
    
    func saveRecurringTransaction(
        date: Date,
        intervalType: String,
        interval: Int,
        name: String,
        tag: String,
        price: Double,
        notes: [String]? = nil
    ) {
        modelContext.insert(
            RecurringTransaction(
                date: date,
                intervalType: intervalType,
                interval: interval,
                name: name.isEmpty ? "Unnamed RecurringTransaction" : name,
                tag: tag,
                price: price,
                notes: notes
            )
        )
        try! modelContext.save()
    }
}




#Preview {
    RecurringTransactionsTest2View()
        .modelContainer(for: RecurringTransaction.self, inMemory: true)
}
