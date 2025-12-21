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
    @Query(sort: \RecurringTransaction.startDate, order: .reverse) private var savedRecurringTransactions: [RecurringTransaction]
    
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
        HStack
        {
            if viewModel.isLoading
            {
                // MARK: Loading Message
                ProgressView("Loading Transaction and Recurring Transaction records...")
                .padding()
            }
            else
            {
                VStack(spacing: 0)
                {
                    Group
                    {
                        if #available(iOS 26.0, *)
                        {
                            Text("Saved Recurring Transactions")
                            .font(.title)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .glassEffect(.regular, in: .rect(cornerRadius: 12))
                        }
                        else
                        { Text("Saved Recurring Transactions") }
                    }
                    .zIndex(1)
                    .shadow(color: defaultPanelShadowColor, radius: 6, x: 0, y: 4)
                    if (!savedRecurringTransactions.isEmpty)
                    {
                        // MARK: Saved Recurring Transactions
                        List()
                        {
                            ForEach(savedRecurringTransactions)
                            { savedRecurringTransaction in
                                HStack
                                {
                                    RecurringTransactionView(recurringTransaction: savedRecurringTransaction)
                                    .padding(.trailing, 6)
                                    DestructiveButtonGlass(title: "Delete")
                                    {
                                        viewModel.delete(recurringTransaction: savedRecurringTransaction)
                                        refresh()
                                    }
                                    .shadow(color: defaultButtonShadowColor, radius: 3, x: 0, y: 2)
                                }
                                .listRowBackground(defaultPanelBackgroundColor)
                            }
                        }
                        .shadow(color: defaultPanelShadowColor, radius: 4, x: 0, y: 3)
                        .scrollContentBackground(.hidden)
                    }
                    else
                    {
                        // MARK: Empty Message
                        VStack
                        {
                            Spacer()
                            Text("No Recurring Transaction records saved.")
                            .foregroundStyle(Color(UIColor.systemGray))
                            .onAppear
                            { viewModel.refresh() }
                            Spacer()
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 700, maxHeight: 700)
                .padding()
                VStack
                {
                    VStack
                    {
                        Group
                        {
                            if #available(iOS 26.0, *)
                            {
                                Text("Found Recurring Transactions")
                                .font(.title)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .glassEffect(.regular, in: .rect(cornerRadius: 12))
                            }
                            else
                            { Text("Found Recurring Transactions") }
                        }
                        .zIndex(1)
                        .shadow(color: defaultPanelShadowColor, radius: 6, x: 0, y: 4)
                        if (!notSavedRecurringTransactions.isEmpty)
                        {
                            // MARK: Calculated Recurring Transactions
                            List
                            {
                                ForEach(notSavedRecurringTransactions)
                                { recurringTransaction in
                                    HStack
                                    {
                                        RecurringTransactionView(recurringTransaction: recurringTransaction)
                                        .padding(.trailing, 6)
                                        PrimaryButtonGlass(title: "Save")
                                        {
                                            viewModel.save(recurringTransaction: recurringTransaction)
                                            refresh()
                                        }
                                        .shadow(color: defaultButtonShadowColor, radius: 3, x: 0, y: 2)
                                    }
                                }
                            }
                            .shadow(color: defaultPanelShadowColor, radius: 4, x: 0, y: 3)
                            .scrollContentBackground(.hidden)
                        }
                        else
                        {
                            // MARK: Empty Message
                            VStack
                            {
                                Spacer()
                                Text("No Recurring Transaction records found.")
                                .foregroundStyle(Color(UIColor.systemGray))
                                .onAppear
                                { viewModel.refresh() }
                                Spacer()
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                    
                    VStack
                    {
                        Group
                        {
                            if #available(iOS 26.0, *)
                            {
                                Text("Manual Recurring Transactions")
                                .font(.title)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .glassEffect(.regular, in: .rect(cornerRadius: 12))
                            }
                            else
                            { Text("Manual Recurring Transactions") }
                        }
                        .zIndex(2)
                        .shadow(color: defaultPanelShadowColor, radius: 6, x: 0, y: 4)
                        .hidden()
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 700, maxHeight: 700)
                .padding()
                .onAppear
                { refresh() }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func refresh()
    {
        notSavedRecurringTransactions = viewModel.filterOut(savedRecurringTransactions)
    }
}
