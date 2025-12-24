//
//  RecurringTransactionView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/14/25.
//

import SwiftUI
import SwiftData

/// View for list of `RecurringTransaction`s
struct RecurringTransactionListView: View
{
    // MARK: - Private Attributes
    @Query(sort: \RecurringTransaction.startDate, order: .reverse) private var savedRecurringTransactions: [RecurringTransaction]
    @State private var viewModel: RecurringTransactionListViewModel
    @State private var notSavedRecurringTransactions: [RecurringTransaction] = []

    // MARK: - Constructors
    init(modelContext: ModelContext, transactionBST: TransactionBST)
    {
        _viewModel = State(initialValue: RecurringTransactionListViewModel(transactionBST: transactionBST, modelContext: modelContext))
    }

    // MARK: - UI
    var body: some View
    {
        ZStack(alignment: .center)
        {
            HStack(spacing: 16)
            {
                // MARK: Saved Recurring Transactions
                VStack(alignment: .leading, spacing: 4)
                {
                    Label("Saved Patterns", systemImage: "clock.arrow.2.circlepath")
                    .font(.headline)
                    .padding(.horizontal)
                    if savedRecurringTransactions.isEmpty
                    {
                        GrayBox(text: "No saved patterns.")
                        .innerShadow(shape: RoundedRectangle(cornerRadius: 12),
                                     color: darkerPanelShadowColor,
                                     radius: 4,
                                     x: 0,
                                     y: 2)
                    }
                    else
                    {
                        ZStack
                        {
                            GrayBox()
                            ScrollView
                            {
                                ForEach(savedRecurringTransactions)
                                { item in
                                    patternRow(item: item, isSaved: true)
                                    .padding()
                                }
                            }
                        }
                        .innerShadow(shape: RoundedRectangle(cornerRadius: 12),
                                     color: darkerPanelShadowColor,
                                     radius: 4,
                                     x: 0,
                                     y: 2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                // MARK: Suggested Recurring Transactions
                VStack(alignment: .leading, spacing: 4)
                {
                    Label("Detected Patterns", systemImage: "clock.badge.questionmark")
                    .font(.headline)
                    .padding(.horizontal)
                    if notSavedRecurringTransactions.isEmpty
                    {
                        GrayBox(text: """
                            No patterns found.
                            
                            [Requirements] 
                            At least 3 transactions with:
                            - Same name 
                            - Same tag
                            - Regular intervals in between.
                            """)
                        .innerShadow(shape: RoundedRectangle(cornerRadius: 12),
                                     color: darkerPanelShadowColor,
                                     radius: 4,
                                     x: 0,
                                     y: 2)
                    }
                    else
                    {
                        ZStack
                        {
                            GrayBox()
                            ScrollView
                            {
                                ForEach(notSavedRecurringTransactions)
                                { item in
                                    patternRow(item: item, isSaved: false)
                                    .padding()
                                }
                            }
                        }
                        .innerShadow(shape: RoundedRectangle(cornerRadius: 12),
                                     color: darkerPanelShadowColor,
                                     radius: 4,
                                     x: 0,
                                     y: 2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            loadingIndicator
        }
    }
    // MARK: - Components
    // Loading Indicator
    private var loadingIndicator: some View
    {
        Group
        {
            if viewModel.isUpdated
            {
                ProgressView("Recalculating Transaction patterns...")
                .onAppear
                {
                    refresh()
                    viewModel.setIsUpdatedFalse()
                }
            }
        }
    }
    // A single row of recurring transaction
    private func patternRow(item: RecurringTransaction, isSaved: Bool) -> some View
    {
        HStack
        {
            RecurringTransactionView(recurringTransaction: item)
            Spacer()
            Group
            {
                if isSaved
                {
                    DestructiveButtonGlass(title: "Remove")
                    {
                        viewModel.delete(recurringTransaction: item)
                        refresh()
                    }
                }
                else
                {
                    PrimaryButtonGlass(title: "Save")
                    {
                        viewModel.save(recurringTransaction: item)
                        refresh()
                    }
                }
            }
            .padding(.leading, 6)
            .shadow(color: defaultButtonShadowColor, radius: 4, x: 0, y: 3)
        }
        .padding()
        .background(defaultPanelBackgroundColor)
        .cornerRadius(20)
        .shadow(color: defaultPanelShadowColor, radius: 4, x: 0, y: 3)
    }
    
    // MARK: - Private Methods
    // Update notsaved recurring transactions
    private func refresh()
    {
        notSavedRecurringTransactions = viewModel.filterOut(savedRecurringTransactions)
    }
}
