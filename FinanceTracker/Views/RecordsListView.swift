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
    
    // MARK: - Private Attributes
    @State private var viewModel: RecordsListViewModel
    @State private var transaction: Transaction?
    
    // MARK: - Constructor
    init(modelContext: ModelContext)
    {
        _viewModel = State(initialValue: RecordsListViewModel(modelContext: modelContext))
    }
    
    // MARK: - UI
    var body: some View
    {
        VStack
        {
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
                }
            }
        }
        // MARK: Opens Transaction Edit Page
        .fullScreenCover(isPresented: Binding(get: { transactionEditorState == .modify },
                                              set: { if !$0 { transactionEditorState = .disabled } }))
        {
            if let transaction: Transaction = self.transaction
            { TransactionEditorView(transaction: transaction, modelContext: viewModel.modelContext) }
        }
        // MARK: Opens Transaction AddNew Page
        .fullScreenCover(isPresented: Binding(get: { transactionEditorState == .addNew },
                                              set: { if !$0 { transactionEditorState = .disabled } }))
        {
            TransactionEditorView(modelContext: viewModel.modelContext)
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
}
