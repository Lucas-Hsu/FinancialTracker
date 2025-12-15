//
//  RecurringTransactionViewModel.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/14/25.
//

import Foundation
import SwiftUI
import SwiftData

/// `RecordsListViewModel` provides methods for the UI to read and modify `Transaction` objects.
@Observable
final class RecurringTransactionListViewModel
{
    // MARK: - Read-only Attributes
    private(set) var transactionBST: TransactionBST
    private(set) var isLoading: Bool = true
    private(set) var recurringTransactions: [RecurringTransaction] = []
    
    // MARK: - Fully Private
    @ObservationIgnored private var transactionObserver: Any?
    @ObservationIgnored private var savedRecurringTransactions: [RecurringTransaction] = []
    @ObservationIgnored private var modelContext: ModelContext
    
    // MARK: - Constructors
    init(transactionBST: TransactionBST, modelContext: ModelContext)
    {
        print("\t///RecurringTransactionViewModel Init")
        self.transactionBST = transactionBST
        self.modelContext = modelContext
        setupTransactionObserver()
        if transactionBST.isReady
        {
            refresh()
            isLoading = false
            print("\tRecurringTransactionViewModel loadedSortedTransactions")
        }
        else
        {
            print("\tRecurringTransactionViewModel TransactionBST is not ready.")
        }
        print("\tRecurringTransactionViewModel Init///")
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
        findRecurringTransactions()
    }
    // Filters out already saved RecurringTransactions
    func filterOut(_ saved: [RecurringTransaction]) -> [RecurringTransaction]
    {
        return recurringTransactions.filter { !saved.contains($0) }
    }
    // Save a RecurringTransaction
    func save(recurringTransaction: RecurringTransaction)
    {
        for rT in fetchRecurringTransactions()
        {
            if recurringTransaction == rT // Skip if already in modelContext
            { return }
        }
        modelContext.insert(recurringTransaction)
        if modelContext.saveSuccess()
        {
            print("Saved RecurringTransaction \n \(recurringTransaction)")
        }
        refresh()
    }
    // Delete a RecurringTransaction
    func delete(recurringTransaction: RecurringTransaction)
    {
        modelContext.delete(recurringTransaction)
        if modelContext.saveSuccess()
        {
            print("Deleted RecurringTransaction \n \(recurringTransaction)")
        }
    }
    // Get RecurringTransactions from ModelContext
    func fetchRecurringTransactions() -> [RecurringTransaction]
    {
        do
        {
            let descriptor = FetchDescriptor<RecurringTransaction>()
            return try modelContext.fetch(descriptor)
        }
        catch
        {
            print("Failed to fetch RecurringTransactions: \(error)")
            return []
        }
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
    // Find RecurrignTransactions from TransactionBST
    private func findRecurringTransactions()
    {
        let transactions: [Transaction] = readTransactions()
        let categorized: [TransactionGroupHeader:[Transaction]] = categorizeTransactions(transactions: transactions)
        print("RecurringTransactionViewModel: \(categorized)")
        var recurringTransactions: [RecurringTransaction] = []
        for k in categorized.keys
        {
            guard let groupedTransactions = categorized[k] else
            { continue }
            guard let recurringTransaction  = RecurringPatternRecognition.findRecurringTransaction(groupedTransactions) else
            { continue }
            recurringTransactions.append(recurringTransaction)
        }
        self.recurringTransactions = recurringTransactions
        print("RecurringTransactionViewModel: Found \(self.recurringTransactions.count) recurring transactions from TransactionBST")
    }
    // Categorize Transactions into groups distinguised by TransactionGroupHeader
    private func categorizeTransactions(transactions: [Transaction]) -> [TransactionGroupHeader:[Transaction]]
    {
        let recognitionLowerBound : Int = 3
        var groupedTransactions: [TransactionGroupHeader: [Transaction]] = [:]
        groupedTransactions.reserveCapacity(transactions.count)
        for transaction in transactions
        {
            groupedTransactions[transaction.getTransactionGroupHeader(), default: []].append(transaction)
        }
        let recurringGroupedTransactions = groupedTransactions.filter { $0.value.count >= recognitionLowerBound }
        return recurringGroupedTransactions
    }
    // Read Transactions from TransactionBST
    private func readTransactions() -> [Transaction]
    {
        print("RecurringTransactionViewModel reading Transactions from TransactionBST...")
        guard transactionBST.isReady else
        {
            print("RecurringTransactionViewModel: TransactionBST not ready yet. Loading skipped.")
            return []
        }
        let sortedTransactions = transactionBST.inOrderTraversal()
        print("RecurringTransactionViewModel: Loaded \(sortedTransactions.count) sorted transactions from TransactionBST")
        return sortedTransactions
    }
}
