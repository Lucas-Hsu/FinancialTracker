//
//  RecordsListView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/11/25.
//

import SwiftUI
import SwiftData

struct RecordsListView: View
{
    private enum TransactionEditorState: CaseIterable
    {
        case addNew,
             modify,
             disabled
    }
    
    @State private var transactionEditorState: TransactionEditorState = .disabled
    @State private var viewModel: RecordsListViewModel
    @State private var transaction: Transaction?
    
    init(modelContext: ModelContext) {
        _viewModel = State(initialValue: RecordsListViewModel(modelContext: modelContext))
    }
    
    var body: some View
    {
        VStack
        {
            Button(action:
            {
                openTransactionEdit()
            })
            {
                Text("Add New")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            VStack
            {
                List {
                    ForEach(viewModel.sortedTransactions)
                    { transaction in
                        TransactionView(transaction: transaction)
                            .onTapGesture {
                                openTransactionEdit(transaction: transaction)
                            }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: Binding(get: { transactionEditorState == .modify },
                                    set: { if !$0 { transactionEditorState = .disabled } }))
        {
            if let transaction: Transaction = self.transaction
            { TransactionEditorView(transaction: transaction, modelContext: viewModel.modelContext) }
        }
        .fullScreenCover(isPresented: Binding(get: { transactionEditorState == .addNew },
                                    set: { if !$0 { transactionEditorState = .disabled } }))
        {
            TransactionEditorView(modelContext: viewModel.modelContext)
        }
        
    }
    
    private func openTransactionEdit(transaction: Transaction? = nil)
    {
        self.transaction = transaction
        if (transaction == nil)
        { transactionEditorState = TransactionEditorState.addNew }
        else
        { transactionEditorState = TransactionEditorState.modify }
    }
}
