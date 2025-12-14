//
//  RecurringTransactionView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/14/25.
//

import SwiftUI
import SwiftData

/// View for list of RecurringTransactions
struct RecurringTransactionView: View
{
    // MARK: - Private Attributes
    @State private var viewModel: RecurringTransactionViewModel
    @State private var transactionBST: TransactionBST
    @State private var transaction: Transaction?
    
    // MARK: - Constructor
    init(modelContext: ModelContext, transactionBST: TransactionBST)
    {
        print("\t///RecurringTransactionView init")
        _transactionBST = State(initialValue: transactionBST)
        _viewModel = State(initialValue: RecurringTransactionViewModel(transactionBST: transactionBST))
        print("\tRecurringTransactionView init///")
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
                if (viewModel.filteredRecurringTransactions.isEmpty)
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
                        ForEach(viewModel.filteredRecurringTransactions)
                        { recurringTransaction in
                            Text(recurringTransaction.description)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
}
