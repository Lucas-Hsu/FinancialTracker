//
//  History.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 2/1/25.
//

import SwiftUI
import SwiftData

class SheetController: ObservableObject {
    @Published var showAddNewSheet = false
    
    public var name: String = ""
    public var tag: Tag = .other
    public var price: Double = 0.00
    
    func toggleSheet() {
        showAddNewSheet.toggle()
        print("ShowAddNewSheet")
    }
}

struct History: View {
    // Assuming you have a @Query to fetch your transactions from the SwiftData store
    @Query(sort: \Transaction.date, order: .reverse) var transactions: [Transaction]

    @State private var selectedTags: Set<String> = Set(Tag.allCases.map { $0.rawValue })
    @State private var isUnpaid: Bool = false;
    @State private var selectedTransaction: Transaction?

    var groupedTransactions: [String: [Transaction]] {
        // Group transactions by the same date (year-month-day)
        let grouped = Dictionary(grouping: transactions) { transaction in
            return formattedDate_(transaction.date)
        }

        // Sort the dictionary by date (most recent first)
        let sortedGrouped = grouped.sorted {
            formattedDateToDate($0.key) < formattedDateToDate($1.key)
        }

        // Return the sorted dictionary
        return Dictionary(uniqueKeysWithValues: sortedGrouped)
    }
    
    func formattedDate_(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd" // ISO 8601 format, easily sortable
        return dateFormatter.string(from: date)
    }
    
    func formattedDateToDate(_ dateString: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: dateString) ?? Date()
    }
    
    @EnvironmentObject var sheetController: SheetController
    
    var body: some View {
        
        VStack {
            
            HStack {
                ForEach(Tag.allCases, id: \.self) { tag in
                    Image(systemName: symbolRepresentation[tag] ?? "questionmark")
                        .padding()
                        .frame(width: 80, height: 50)
                        .background(self.selectedTags.contains(tag.rawValue) ? Color.accentColor : Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .foregroundColor(self.selectedTags.contains(tag.rawValue) ? .white : .secondary)
                        .onTapGesture {
                            // Toggle selection on tap
                            if self.selectedTags.contains(tag.rawValue) {
                                self.selectedTags.remove(tag.rawValue)
                            } else {
                                self.selectedTags.insert(tag.rawValue)
                            }
                        }
                }
            }
            .padding()
            Toggle("Show Only Payment Pending", isOn: $isUnpaid)
                .toggleStyle(ButtonToggleStyle())
                .scaleEffect(isUnpaid ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isUnpaid)
            
            
            
            Button("Add New") {
                sheetController.name = ""
                sheetController.tag = .other
                sheetController.price = 00.00
                sheetController.toggleSheet()
            }
            .frame(width: 240, height: 50)
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .cornerRadius(10)
            .padding()
            
            VStack{
                
                List {
                    // Iterate over the grouped transactions
                    ForEach(groupedTransactions.keys.sorted(by: >), id: \.self) { key in
                        // Filter the transactions for this section
                        let filteredTransactions = groupedTransactions[key]!.filter { transaction in
                            // Call matchesFilter on each transaction and only include it if it matches the filter
                            transaction.matchesFilter(tags: selectedTags, isUnpaid: isUnpaid)
                        }
                        
                        // Only display the section if there are any matching transactions
                        if !filteredTransactions.isEmpty {
                            Section(header: Text(key).font(.headline)) {
                                // For each group of transactions, display a list of filtered transactions
                                ForEach(filteredTransactions, id: \.id) { transaction in
                                    TransactionView(transaction: transaction).onTapGesture {
                                        self.selectedTransaction = transaction
                                    }
                                }
                            }
                        }
                    }
                }
                
                
            }
        }
        .fullScreenCover(item: $selectedTransaction) { transaction in
            TransactionDetailsView(transaction: Binding(get: {
                transaction
            }, set: { updatedTransaction in
                // Handle any changes in the transaction
                self.selectedTransaction = updatedTransaction
            }))
        }
        
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()



struct TransactionView: View {
    var transaction: Transaction

    var body: some View {
            HStack {
                VStack(alignment: .leading) {
                    Text(transaction.name)
                        .font(.body)
                    Text(transaction.tag)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                
                Text(formattedPrice(transaction.price))
                    .font(.body)
                    .bold()
                    .foregroundColor(transaction.paid ? .black : .red)
            }
            .padding()
    }
}

private var currencyFormatter: NumberFormatter {
    let formatter = NumberFormatter()
    formatter.locale=Locale(identifier: "cn_CN")
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }

private func formattedPrice(_ price: Double) -> String {
    return currencyFormatter.string(from: NSNumber(value: price)) ?? "0.00"
    }

private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        let formattedDate = formatter.string(from: date)
    /*
        let day = Calendar.current.component(.day, from: date)
        let suffix: String
        

        // Determine the appropriate suffix (st, nd, rd, th)
        switch day {
        case 1, 21, 31:
            suffix = "st"
        case 2, 22:
            suffix = "nd"
        case 3, 23:
            suffix = "rd"
        default:
            suffix = "th"
        }
        
        Format the date string
        
        Replace the day part with the formatted day and suffix
        let dayString = "\(day)\(suffix)"
        let dateString = formattedDate.replacingOccurrences(of: "\(day)", with: dayString)
        
        return dateString
        */
        return formattedDate
    }

#Preview {
    History()
        .modelContainer(for: Transaction.self, inMemory: true)
}

