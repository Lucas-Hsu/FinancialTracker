//
//  RecordsListView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/11/25.
//

import SwiftUI
import SwiftData

/// View for list of Transactions sorted by most recent date, and launches Adding New, Editing, and Deleting.
struct RecordsListView: View
{
    // MARK: - State Management
    private enum TransactionEditorState: CaseIterable
    {
        case addNew,
             modify,
             disabled
    }
    @State private var transactionEditorState: TransactionEditorState = .disabled
    @State private var refreshID = UUID() // Force view refresh
    
    // MARK: - Private Attributes
    @State private var viewModel: RecordsListViewModel
    @State private var transactionBST: TransactionBST
    @State private var transaction: Transaction?
    
    // MARK: - Constructor
    init(modelContext: ModelContext, transactionBST: TransactionBST)
    {
        _transactionBST = State(initialValue: transactionBST)
        _viewModel = State(initialValue: RecordsListViewModel(modelContext: modelContext, transactionBST: transactionBST))
    }
    
    // MARK: - UI
    var body: some View
    {
        VStack
        {
            if viewModel.isLoading {
                            // MARK: Show loading state while BST initializes
                            ProgressView("Loading transactions...")
                                .padding()
            } else {
                // MARK: Add New Transaction button
                Button(action: { openTransactionEdit() } )
                {
                    Text("Add New")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                // MARK: Sorted list of Transactions
                VStack
                {
                    List
                    {
                        ForEach(viewModel.sortedTransactions)
                        { transaction in
                            TransactionView(transaction: transaction)
                                .onTapGesture
                            { openTransactionEdit(transaction: transaction) }
                        }
                        .onDelete { indexSet in
                            deleteTransactions(at: indexSet)
                        }
                    }
                    .id(refreshID) // Force List refresh when ID changes
                }
            }
        }
        .onChange(of: viewModel.sortedTransactions) { _, _ in
            refreshID = UUID() // Refresh view when data changes
        }
        // MARK: Opens Transaction Edit Page
        .fullScreenCover(isPresented: Binding(get: { transactionEditorState == .modify },
                                              set: { if !$0 { transactionEditorState = .disabled } }))
        {
            if let transaction = self.transaction {
                TransactionEditorView(transaction: transaction, modelContext: viewModel.modelContext)
                    .onDisappear {
                        // Refresh when editor closes
                        viewModel.refresh()
                    }
            }
        }
        // MARK: Opens Transaction AddNew Page
        .fullScreenCover(isPresented: Binding(get: { transactionEditorState == .addNew },
                                              set: { if !$0 { transactionEditorState = .disabled } }))
        {
            TransactionEditorView(modelContext: viewModel.modelContext)
                .onDisappear {
                    // Refresh when editor closes
                    viewModel.refresh()
                }
        }
    }
    
    // MARK: - Helper Functions
    private func openTransactionEdit(transaction: Transaction? = nil)
    {
        self.transaction = transaction
        if (transaction == nil)
        { transactionEditorState = TransactionEditorState.addNew }
        else
        { transactionEditorState = TransactionEditorState.modify }
    }
    
    private func deleteTransactions(at offsets: IndexSet) {
        for index in offsets {
            let transaction = viewModel.sortedTransactions[index]
            viewModel.modelContext.delete(transaction)
        }
        
        do {
            try viewModel.modelContext.save()
            // Post notification to refresh BST
            NotificationCenter.default.post(name: .transactionBSTUpdated, object: nil)
        } catch {
            print("[ERROR] Failed to delete transactions: \(error)")
        }
    }
}
