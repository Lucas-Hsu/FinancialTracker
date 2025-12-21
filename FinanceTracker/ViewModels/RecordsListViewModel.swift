//
//  RecordsListViewModel.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/11/25.
//

import Foundation
import SwiftUI
import SwiftData

/// `RecordsListViewModel` provides methods for the UI to read and modify `Transaction` objects.
@Observable
final class RecordsListViewModel
{
    // MARK: - Read-only Attributes
    private(set) var sortedTransactions: [Transaction] = []
    private(set) var groupedTransactions: [String: [Transaction]] = [:]
    private(set) var transactionBST: TransactionBST
    private(set) var isLoading: Bool = true
    private(set) var sortByNewestFirst: Bool = true
    private(set) var selectedIsPaid: Bool? = nil
    private(set) var selectedTags: Set<Tag> = Set(Tag.allCases)
    
    // MARK: - Fully Private
    @ObservationIgnored let modelContext: ModelContext
    @ObservationIgnored private var transactionObserver: Any?
    
    // MARK: - Constructors
    init(modelContext: ModelContext, transactionBST: TransactionBST)
    {
        print("\t///RecordListViewModel Init")
        self.modelContext = modelContext
        self.transactionBST = transactionBST
        setupTransactionObserver()
        if transactionBST.isReady
        {
            refresh()
            isLoading = false
            print("\tRecordListViewModel loadedSortedTransactions")
        }
        else
        {
            print("\tRecordListViewModel TransactionBST is not ready.")
        }
        print("\tRecordListViewModel Init///")
    }
    
    // MARK: - Destructors
    deinit
    {
        if let token = transactionObserver
        {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    // MARK: - Public Methods
    func refresh()
    {
        loadSortedTransactions()
        regroupTransactions()
    }
    
    func delete(transactions: [Transaction])
    {
        for transaction in transactions
        { modelContext.delete(transaction) }
        if modelContext.saveSuccess()
        { NotificationCenter.default.post(name: .transactionsUpdated, object: nil) }
    }
    
    func toggleIsPaid(_ state: Bool) -> Bool?
    {
        if selectedIsPaid == nil
        {
            selectedIsPaid = state
            return state
        }
        else
        {
            selectedIsPaid = nil
            return nil
        }
    }
    
    func reverseOrder()
    {
        sortByNewestFirst = !sortByNewestFirst
    }
    
    func toggleTagSelection(tag: Tag)
    {
        if selectedTags.contains(tag)
        { selectedTags.remove(tag) }
        else
        { selectedTags.insert(tag) }
    }
    
    // MARK: - Helpers Methods
    // Wait for notifications from TransactionBST of transactions changes
    private func setupTransactionObserver()
    {
        transactionObserver = NotificationCenter.default.addObserver(forName: .transactionBSTUpdated,
                                                                     object: transactionBST,
                                                                     queue: .main)
        { [weak self] notification in
            guard let self = self else
            { return }
            let isInitialLoad = notification.userInfo?["initialLoad"] as? Bool ?? false
            if isInitialLoad
            {
                print("RecordsListViewModel Initializing...")
                self.isLoading = false
            }
            self.refresh()
        }
    }
    // Load sorted Transactions from TransactionBST
    private func loadSortedTransactions()
    {
        print("RecordListViewModel LoadingSortedTransactions...")
        guard transactionBST.isReady else
        {
            print("RecordsListViewModel: TransactionBST not ready yet. Loading skipped.")
            return
        }
        sortedTransactions = transactionBST.inOrderTraversal()
        print("RecordsListViewModel: Loaded \(sortedTransactions.count) sorted transactions from TransactionBST")
    }
    // Group each key by date
    private func regroupTransactions()
    {
        groupedTransactions = Dictionary(grouping: sortedTransactions)
        { transaction in
            return DateFormatters.yyyyMMdd(date: transaction.date)
        }
    }
}
