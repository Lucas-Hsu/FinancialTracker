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
        VStack(spacing: 0)
        {
            if viewModel.isLoading
            {
                // MARK: Loading Message
                ProgressView("Loading Transaction records...")
                .padding()
            }
            else
            {
                // MARK: Toolbar
                if #available(iOS 26.0, *)
                {
                    toolbar
                    .glassEffect(.regular, in: .rect(cornerRadius: 16))
                }
                else
                { toolbar }
                
                // MARK: Empty Message
                if (viewModel.groupedTransactions.isEmpty)
                {
                    VStack
                    {
                        Spacer()
                        Text("No Transaction records found. Please tap 'Add New'.")
                            .onAppear
                        { viewModel.refresh() }
                        Spacer()
                    }
                }
                // MARK: Sorted list of Transactions
                List
                {
                    ForEach(viewModel.sortByNewestFirst ? viewModel.groupedTransactions.keys.sorted(by: >) : viewModel.groupedTransactions.keys.sorted(by: <), id: \.self)
                    { key in
                        let filteredTransactions: [Transaction] = viewModel.groupedTransactions[key]?.filter(
                            {transaction in
                                transaction.matchesFilter(isPaid: viewModel.selectedIsPaid,
                                                          selectedTags: viewModel.selectedTags)
                            }) ?? []
                        if !filteredTransactions.isEmpty
                        {
                            Section(header:
                                        Text(DateFormatters.dMMMMyyyy(date: key))
                                        .font(.headline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(Color(UIColor.systemGray)))
                            {
                                ForEach(viewModel.sortByNewestFirst ? filteredTransactions : filteredTransactions.reversed(), id: \.id)
                                { transaction in
                                    TransactionView(transaction: transaction)
                                    .listRowBackground(defaultPanelBackgroundColor)
                                    .onTapGesture
                                    { openTransactionEdit(transaction: transaction) }
                                }
                                .onDelete
                                { indexSet in
                                    let transactionsToDelete = indexSet.map { filteredTransactions[$0] }
                                    viewModel.delete(transactions: transactionsToDelete)
                                }
                            }
                        }
                    }
                }
                .shadow(color: defaultPanelShadowColor, radius: 3, x: 0, y: 3)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 700, maxHeight: 700)
        .fullScreenCover(isPresented: Binding(get: { transactionEditorState == .modify },
                                              set: { if !$0 { transactionEditorState = .disabled } }))
        {
            if let transaction = self.transaction
            { TransactionEditorView(modelContext: viewModel.modelContext, isNew: false, transaction: transaction) }
        }
        .fullScreenCover(isPresented: Binding(get: { transactionEditorState == .addNew },
                                              set: { if !$0 { transactionEditorState = .disabled } }))
        { TransactionEditorView(modelContext: viewModel.modelContext, isNew: true) }
    }
    
    // MARK: - Components
    private var toolbar: some View
    {
        VStack(spacing: 0)
        {
            HStack
            {
                // !isPaid only filter
                Button(action: { _ = viewModel.toggleIsPaid(false) })
                {
                    HStack(spacing: 6)
                    {
                        Image(systemName: viewModel.selectedIsPaid == false ? "checkmark.square.fill" : "square")
                        Text("Payment Pending")
                    }
                    .foregroundColor(viewModel.selectedIsPaid == false ? .blue : .gray)
                }
                // Add new Transaction button
                PrimaryButtonGlass(title:"Add New")
                { openTransactionEdit() }
                .padding()
                .shadow(color: Color(hue: 0.58, saturation: 0.5, brightness: 0.5, opacity: 0.4), radius: 2, x: 0, y: 2)
                // Sort by newest/oldest
                Button(action: { viewModel.reverseOrder() })
                {
                    HStack(spacing: 6)
                    {
                        Image(systemName: viewModel.sortByNewestFirst ? "checkmark.square.fill" : "square")
                        Text("Newest First")
                    }
                    .foregroundColor(viewModel.sortByNewestFirst ? .blue : .gray)
                }
            }
            
            HStack
            {
                ForEach(Tag.allCases, id: \.self)
                { tag in
                    IconToggleButtonGlass(icon: tagSymbols[tag] ?? "questionmark", shadow: viewModel.selectedTags.contains(tag), toggle: viewModel.selectedTags.contains(tag))
                    {viewModel.toggleTagSelection(tag: tag)}
                    .frame(width: 60, height: 40)
                    .padding(.vertical)
                }
                .padding(.horizontal, 2)
            }
            .offset(y: -6)
        }
        .frame(maxWidth: .infinity, minHeight: 160, maxHeight: 160)
        .zIndex(1)
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
