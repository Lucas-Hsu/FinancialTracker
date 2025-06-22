//
//  RecurringTransactionsTestView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 2/27/25.
//

import SwiftUI
import SwiftData
import Foundation

func daysInYear(year: Int) -> [Date] {
    let calendar = Calendar.current
    
    // Create the start and end dates for the year
    guard let startDate = calendar.date(from: DateComponents(year: year-1, month: 1, day: 1)),
          let endDate = calendar.date(from: DateComponents(year: year+1, month: 12, day: 31)) else {
        return []
    }
    
    var dates: [Date] = []
    var currentDate = startDate
    
    // Loop from the start date until the end date (inclusive)
    while currentDate <= endDate {
        dates.append(currentDate)
        // Advance by one day using the calendar to handle all calendar-specific adjustments
        guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
            break
        }
        currentDate = nextDate
    }
    
    return dates
}

func more365(date: Date) -> [Date] {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month, .day], from: date)
    
    // Create the start and end dates for the year
    guard let startDate = calendar.date(from: DateComponents(year: components.year, month: components.month, day: components.day)),
          let endDate = calendar.date(from: DateComponents(year: (components.year ?? 2025)+1, month: components.month, day: components.day)) else {
        return []
    }
    
    var dates: [Date] = []
    var currentDate = startDate
    
    // Loop from the start date until the end date (inclusive)
    while currentDate <= endDate {
        dates.append(currentDate)
        // Advance by one day using the calendar to handle all calendar-specific adjustments
        guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
            break
        }
        currentDate = nextDate
    }
    
    return dates
}

struct RecurringTransactionsTestView: View {
    
    @Query(sort: \RecurringTransaction.price, order: .reverse) var recurringTransactions: [RecurringTransaction]
    @Environment(\.modelContext) var modelContext
    
    @State var date: Date = Date()
    @State var intervalType: TypesOfRecurringTransaction = .Custom
    @State var interval: Int = 1
    @State var name: String = "Rent"
    @State var tag: String = Tag.other.rawValue
    @State var price: Double = 10.00
    
    var body: some View {
        HStack {
            
            VStack {
                VStack{
                    List {
                        // Iterate over the grouped transactions
                        ForEach(recurringTransactions) { recurringTransaction in
                            Text(recurringTransaction.price.description)
                        }
                    }
                }
                let currentYear = Calendar.current.component(.year, from: Date())
                let allDays: [Date] = daysInYear(year: currentYear)
                List(allDays, id: \.self) { date in
                    if let recurringTransactionLast = recurringTransactions.last {
                        if recurringTransactionLast.occursOnDate(date: date) {
                            Text("\(date)")
                        }
                    }
                }
            }
            
            VStack {
                Form {
                    Section(header: Text("Transaction Record")) {
                        TextField("Title", text: $name)
                            .padding()
                        
                        DatePicker(
                            "Enter Date",
                            selection: $date,
                            displayedComponents: .date
                        )
                        .padding()
                        
                        Picker("Type", selection: $intervalType) {
                            ForEach(TypesOfRecurringTransaction.allCases, id: \.self) { tag in
                                Text(tag.rawValue).tag(tag)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                        
                        HStack {
                            Text("Interval")
                            Spacer()
                            TextField("Enter Price", value: $interval, formatter: NumberFormatter())
                                .keyboardType(.decimalPad)
                        }
                        .padding()
                        
                        HStack {
                            Text("Price  (CN¥)")
                            Spacer()
                            TextField("Enter Price", value: $price, formatter: Transaction().priceFormatter)
                                .keyboardType(.decimalPad)
                        }
                        .padding()
                    }
                }
                Button(action: {
                    saveRecurringTransaction(
                        date: date,
                        intervalType: intervalType.rawValue,
                        interval: interval,
                        name: name,
                        tag: tag,
                        price: price
                    )
                    
                    
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
    RecurringTransactionsTestView()
        .modelContainer(for: RecurringTransaction.self, inMemory: true)
}
