//
//  History.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 2/1/25.
//

import SwiftUI
import SwiftData

/// For persist/transfer data across `AddNew()` pages, for example from clicking on `Calendar` `Event`s.
class SheetController: ObservableObject
{
    @Published var showAddNewSheet = false
    public var name: String = ""
    public var tag: Tag = .other
    public var price: Double = 0.00
    public var date: Date = Date()
    
    func toggleSheet()
    {
        showAddNewSheet.toggle()
        print("ShowAddNewSheet")
    }
}

/// Displays all transactions in a list sorted from most recent to most distant date
struct History: View
{
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) var transactions: [Transaction]
    @EnvironmentObject var modifySheetController: SheetController
    
    @State private var customsCenter = CustomsCenter()
    @State private var selectedTags: Set<Tag> = Set(Tag.allCases)
    @State private var onlyUnpaid: Bool = false;
    @State private var selectedTransaction: Transaction?

    @State var onlyUnpaidScaleEffect: CGFloat = 1
    @State var addNewButtonScaleEffect: CGFloat = 1

    /// Group transactions together by same date. Transactions within each group are sorted by time
    var groupedTransactions: [String: [Transaction]]
    {
        // Group transactions by date
        let grouped = Dictionary(grouping: transactions)
        { transaction in
            return transaction.date.shortDate
        }

        // Sort each key by date
        let sortedGrouped = grouped.sorted {
            $0.key.toDate() < $1.key.toDate()
        }
        
        // Sort each values of each key by time
        let sortedTransactionsGrouped = sortedGrouped.map
        { (key, transactions) in
            return (key, transactions.sorted { $0.date < $1.date })
        }

        return Dictionary(uniqueKeysWithValues: sortedTransactionsGrouped)
    }
    
    func clearAllTransactions()
    {
        for transaction in transactions
        { modelContext.delete(transaction) }
        do
        {
            try modelContext.save()
            print("Cleared all transactions")
        } catch {
            print("Failed to clear transactions: \(error.localizedDescription)")
        }
    }
    
    var body: some View
    {
        VStack
        {
            HStack
            {
                ForEach(Tag.allCases, id: \.self)
                { tag in
                    Image(systemName: tagSymbol[tag] ?? "questionmark")
                        .frame(width: 80, height: 50)
                        .cornerRadius(8)
                        .foregroundColor(self.selectedTags.contains(tag) ? .white : .secondary)
                        .scaleEffect(self.selectedTags.contains(tag) ? 1.1 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.4, blendDuration: 0.1), value: selectedTags)
                        
                        .accentButtonToggled(boolean:self.selectedTags.contains(tag))
                        .onTapGesture
                        {
                            if self.selectedTags.contains(tag)
                            {
                                self.selectedTags.remove(tag)
                            } else {
                                self.selectedTags.insert(tag)
                            }
                        }
                }
                    .padding(.horizontal,4)
            }
                .padding()
            
            Button(action: {
                onlyUnpaid = !onlyUnpaid
                withAnimation( Animation.spring(response: 0.3,
                                                dampingFraction: 0.4,
                                                blendDuration: 0.1),
                               { onlyUnpaidScaleEffect = onlyUnpaidScaleEffect == 1.1 ? 1 : 1.1 } )
                            })
            {
                Text("Show Only Payment Pending")
                    .padding(10)
            }
                .scaleEffect(onlyUnpaidScaleEffect)
                .foregroundStyle(!onlyUnpaid ? Color.accentColor : Color.white)
                .accentButtonToggled(boolean: onlyUnpaid)

            HStack
            {
                Button(role: .destructive)
                { clearAllTransactions() }
                label:
                {
                    Text("Clear All Transactions")
                        .font(.headline)
                        .foregroundColor(.red)
                }
                    .padding()

                Button(action: {
                    modifySheetController.name = ""
                    modifySheetController.tag = .other
                    modifySheetController.price = 00.00
                    modifySheetController.toggleSheet()
                    addNewButtonScaleEffect = 1.2
                    withAnimation(Animation.spring.speed(0.6),
                        {
                            addNewButtonScaleEffect = addNewButtonScaleEffect == 1.2 ? 1 : 1.2
                        })
                                })
                {
                    Text("Add New")
                        .padding(.horizontal, 80)
                        .padding(.vertical, 12)
                }
                    .accentButton()
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                    .scaleEffect(addNewButtonScaleEffect)
                    .padding()
                
                VStack
                {
                    Button("Export")
                    { customsCenter.presentExport(for: transactions) }
                    
                    Button("Import")
                    {
                        customsCenter.presentImport
                        { imported in
                            for tx in imported
                            { modelContext.insert(tx) }
                        }
                    }
                }
            }
            
            VStack
            {
                List
                {
                    ForEach(groupedTransactions.keys.sorted(by: >), id: \.self)
                    { key in
                        let filteredTransactions = groupedTransactions[key]!.filter
                        { transaction in
                            transaction.matchesFilter(onlyUnpaid: onlyUnpaid, tags: selectedTags)
                        }
                        
                        if !filteredTransactions.isEmpty
                        {
                            Section(header: Text(key).font(.headline))
                            {
                                ForEach(filteredTransactions, id: \.id)
                                { transaction in
                                    TransactionView(transaction: transaction)
                                        .onTapGesture
                                        { self.selectedTransaction = transaction }
                                }
                            }
                        }
                    }
                        .clearBackground()
                        .plainFill()
                }
                    .plainFill(material: .ultraThinMaterial, opacity: 0.4)
            }
                .clearBackground()
        }
            .fullScreenCover(item: $selectedTransaction)
            { transaction in
                ModifyOld(transaction: Binding(get: { transaction },
                                               set: { updatedTransaction in
                                                        self.selectedTransaction = updatedTransaction
                                                    }
                                              ))
            }
            .fileExporter(isPresented: $customsCenter.isExporting,
                          document: customsCenter.exportFile(),
                          contentType: .json,
                          defaultFilename: "Transactions")
            { result in
                if case .failure(let error) = result
                { print("Export error: \(error.localizedDescription)") }
            }
            .fileImporter(isPresented: $customsCenter.isImporting,
                          allowedContentTypes: [.json])
            { result in
                customsCenter.handleImport(result: result)
            }
    }
}

#Preview
{
    History()
        .modelContainer(for: Transaction.self, inMemory: true)
}
