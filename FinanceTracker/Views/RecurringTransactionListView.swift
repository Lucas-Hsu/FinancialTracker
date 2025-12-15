//
//  RecurringTransactionView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/14/25.
//

import SwiftUI
import SwiftData

/// View for list of RecurringTransactions
struct RecurringTransactionListView: View
{
    // MARK: - Private State Attributes
    @State private var viewModel: RecurringTransactionListViewModel
    @State private var transactionBST: TransactionBST
    @State private var transaction: Transaction?
    @State private var notSavedRecurringTransactions: [RecurringTransaction] = []
    @Query(sort: \RecurringTransaction.startDate, order: .reverse)
        private var savedRecurringTransactions: [RecurringTransaction]
    
    // MARK: - Constructor
    init(modelContext: ModelContext, transactionBST: TransactionBST)
    {
        print("\t///RecurringTransactionView init")
        _transactionBST = State(initialValue: transactionBST)
        _viewModel = State(initialValue: RecurringTransactionListViewModel(transactionBST: transactionBST, modelContext: modelContext))
        print("\tRecurringTransactionView init///")
    }
    
    // MARK: - UI
    var body: some View
    {
        VStack
        {
            if viewModel.isLoading
            {
                VStack
                {
                    ProgressView("Loading Transaction and Recurring Transaction records...")
                    .padding()
                }
            }
            else
            {
                // MARK: Saved Recurring Transactions
                Text("Saved Recurring Transactions")
                .onAppear
                { refresh() }
                if (!savedRecurringTransactions.isEmpty)
                {
                    VStack
                    {
                        List()
                        {
                            ForEach(savedRecurringTransactions)
                            { savedRecurringTransaction in
                                HStack
                                {
                                    RecurringTransactionView(recurringTransaction: savedRecurringTransaction)
                                    Spacer()
                                    DestructiveDeleteButtonGlass()
                                    {
                                        viewModel.delete(recurringTransaction: savedRecurringTransaction)
                                        refresh()
                                    }
                                }
                            }
                        }
                    }
                }
                else
                {
                    Spacer()
                    Text("No Recurring Transaction records saved.")
                    .onAppear
                    { viewModel.refresh() }
                    Spacer()
                }
                // MARK: Calculated Recurring Transactions
                Text("Found Recurring Transactions")
                if (!viewModel.recurringTransactions.isEmpty)
                {
                    VStack
                    {
                        List()
                        {
                            ForEach(notSavedRecurringTransactions)
                            { recurringTransaction in
                                
                                HStack
                                {
                                    RecurringTransactionView(recurringTransaction: recurringTransaction)
                                    Spacer()
                                    PrimaryButtonGlass(title: "Save")
                                    {
                                        viewModel.save(recurringTransaction: recurringTransaction)
                                        refresh()
                                    }
                                }
                            }
                        }
                    }
                }
                else
                {
                    Spacer()
                    Text("No Recurring Transaction records found.")
                    .onAppear
                    { viewModel.refresh() }
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func refresh()
    {
        notSavedRecurringTransactions = viewModel.filterOut(savedRecurringTransactions)
        print("\(notSavedRecurringTransactions)kjhgf")
    }
}
