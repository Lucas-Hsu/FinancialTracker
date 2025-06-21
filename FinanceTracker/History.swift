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
    public var date: Date = Date()
    
    func toggleSheet() {
        showAddNewSheet.toggle()
        print("ShowAddNewSheet")
    }
}

struct History: View {
    // Assuming you have a @Query to fetch your transactions from the SwiftData store
    @Query(sort: \Transaction.date, order: .reverse) var transactions: [Transaction]
    @Environment(\.modelContext) private var modelContext // Access SwiftData context
    
    @State private var customsCenter = CustomsCenter()
    
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
    
    @State var scaleEffect: CGFloat = 1
    @State var AddNewButtonScaleEffect: CGFloat = 1
    
    @EnvironmentObject var sheetController: SheetController
    
    var body: some View {
        
        VStack {
            
            HStack {
                ForEach(Tag.allCases, id: \.self) { tag in
                    Image(systemName: tagSymbol[tag] ?? "questionmark")
                        .frame(width: 80, height: 50)
                        .accentButtonToggled(boolean:self.selectedTags.contains(tag.rawValue))
                        
                        .cornerRadius(8)
                        .foregroundColor(self.selectedTags.contains(tag.rawValue) ? .white : .secondary)
                        .scaleEffect(self.selectedTags.contains(tag.rawValue) ? 1.1 : 1.0) // Scale effect on selection
                        .animation(.spring(response: 0.4, dampingFraction: 0.4, blendDuration: 0.1), value: selectedTags) // Smooth animation on selection change
                                    
                        .onTapGesture {
                            // Toggle selection on tap
                            if self.selectedTags.contains(tag.rawValue) {
                                self.selectedTags.remove(tag.rawValue)
                            } else {
                                self.selectedTags.insert(tag.rawValue)
                            }
                            
                            
                        }
                }.padding(.horizontal,4)
            }
            .padding()
            Button(action: {
                isUnpaid = !isUnpaid
                withAnimation(Animation.spring(response: 0.3, dampingFraction: 0.4, blendDuration: 0.1), {
                    scaleEffect = scaleEffect==1.1 ? 1 : 1.1
                })
            }) {
                Text("Show Only Payment Pending")
                    .padding(10)
            }.accentButtonToggled(boolean: isUnpaid)
                .scaleEffect(scaleEffect)
                .foregroundStyle(!isUnpaid ? Color.accentColor : Color.white)
            
            
            
            
            HStack {

                Button(role: .destructive) {
                    clearAllTransactions()
                } label: {
                    Text("Clear All Transactions")
                        .font(.headline)
                        .foregroundColor(.red)
                }
                .padding()

                Button(action: {
                    sheetController.name = ""
                    sheetController.tag = .other
                    sheetController.price = 00.00
                    sheetController.toggleSheet()
                    AddNewButtonScaleEffect = 1.2
                    withAnimation(Animation.spring.speed(0.6), {
                        AddNewButtonScaleEffect = AddNewButtonScaleEffect==1.2 ? 1 : 1.2
                    })
                }) {
                    Text("Add New")
                        .padding(.horizontal, 80)
                        .padding(.vertical, 12)
                }
                .accentButton()
                .foregroundStyle(.white)
                .cornerRadius(10)
                .scaleEffect(AddNewButtonScaleEffect)
                .padding()
                
                VStack{
                    Button("Export") {
                        customsCenter.presentExport(for: transactions)
                    }
                    Button("Import") {
                        customsCenter.presentImport { imported in
                            for tx in imported {
                                modelContext.insert(tx)
                            }
                        }
                    }
                }
                
                
            }
            
            VStack{
                
                List {
                    // Iterate over the grouped transactions
                    ForEach(groupedTransactions.keys.sorted(by: >), id: \.self) { key in
                        // Filter the transactions for this section
                        let filteredTransactions = groupedTransactions[key]!.filter { transaction in
                            // Call matchesFilter on each transaction and only include it if it matches the filter
                            transaction.matchesFilter(onlyUnpaid: isUnpaid, tags: selectedTags)
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
                    }.clearBackground()
                    .plainFill()
                }
                .plainFill(material: .ultraThinMaterial, opacity: 0.4)
            }.clearBackground()
        }
        .fullScreenCover(item: $selectedTransaction) { transaction in
            TransactionDetailsView(transaction: Binding(get: {
                transaction
            }, set: { updatedTransaction in
                // Handle any changes in the transaction
                self.selectedTransaction = updatedTransaction
            }))
        }
        // File Exporter
        .fileExporter(
            isPresented: $customsCenter.isExporting,
            document: customsCenter.exportFile(),
            contentType: .json,
            defaultFilename: "Transactions"
        ) { result in
            if case .failure(let error) = result {
                print("Export error: \(error.localizedDescription)")
            }
        }
        // File Importer
        .fileImporter(
            isPresented: $customsCenter.isImporting,
            allowedContentTypes: [.json]
        ) { result in
            customsCenter.handleImport(result: result)
        }
        
    }
    
    func clearAllTransactions() {
            for transaction in transactions {
                modelContext.delete(transaction)
            }
            do {
                try modelContext.save()
                print("Cleared all transactions")
            } catch {
                print("Failed to clear transactions: \(error.localizedDescription)")
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
        return formattedDate
    }

#Preview {
    History()
        .modelContainer(for: Transaction.self, inMemory: true)
}

