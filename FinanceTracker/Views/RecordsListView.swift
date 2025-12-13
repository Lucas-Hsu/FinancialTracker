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
    private enum TransactionEditorState
    {
        case addNew,
             modify,
             disabled
    }
    @State private var transactionEditorState: TransactionEditorState = .disabled
    
    // MARK: - Private Attributes
    @State private var viewModel: RecordsListViewModel
    @State private var transactionBST: TransactionBST
    @State private var transaction: Transaction?
    
    // MARK: - Constructor
    init(modelContext: ModelContext, transactionBST: TransactionBST)
    {
        print("\t///RecordsListView init")
        _transactionBST = State(initialValue: transactionBST)
        _viewModel = State(initialValue: RecordsListViewModel(modelContext: modelContext, transactionBST: transactionBST))
        print("\tRecordsListView init///")
    }
    
    // MARK: - UI
    var body: some View
    {
        VStack
        {
            if viewModel.isLoading
            {
                ProgressView("Loading Transaction records...")
                .padding()
            }
            else
            {
                PrimaryButtonGlass(title:"Add New")
                { openTransactionEdit() }
                .padding()
                
                if (viewModel.sortedTransactions.isEmpty)
                {
                    VStack
                    {
                        Spacer()
                        Text("No Transaction records found. Please tap 'Add New'.")
                        .onAppear
                        {
                            viewModel.refresh()
                        }
                        Spacer()
                    }
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
                        .onDelete
                        { indexSet in
                            deleteTransactions(at: indexSet)
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: Binding(get: { transactionEditorState == .modify },
                                              set: { if !$0 { transactionEditorState = .disabled } }))
        {
            if let transaction = self.transaction
            { TransactionEditorView(transaction: transaction, modelContext: viewModel.modelContext) }
        }
        .fullScreenCover(isPresented: Binding(get: { transactionEditorState == .addNew },
                                              set: { if !$0 { transactionEditorState = .disabled } }))
        { TransactionEditorView(modelContext: viewModel.modelContext) }
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
    
    // For slide to delete
    private func deleteTransactions(at indices: IndexSet)
    {
        var transactionsToDelete: [Transaction] = []
        for index in indices
        { transactionsToDelete.append(viewModel.sortedTransactions[index]) }
        viewModel.delete(transactions: transactionsToDelete)
    }
}
