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
    
    // MARK: - Fully Private
    @ObservationIgnored let modelContext: ModelContext
    @ObservationIgnored private var transactionObserver: NSObjectProtocol?
    
    // MARK: - Constructors
    init(modelContext: ModelContext)
    {
        self.modelContext = modelContext
        loadSortedTransactions()
        setupTransactionObserver()
    }
    
    // MARK: - Destroyer for preventing memory leaks
    deinit
    {
        if let observer = transactionObserver
        {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Public Methods
    
    // MARK: - Helpers Methods
    /// Set up an observer to receive TransactionDidSave notifications
    private func setupTransactionObserver() {
        transactionObserver = NotificationCenter.default.addObserver(forName: .transactionDidSave,
                                                                 object: nil,
                                                                 queue: .main)
        { [weak self] _ in
            self?.loadSortedTransactions()
        }
    }
    
    private func loadSortedTransactions()
    {
        let sortDescriptor = SortDescriptor(\Transaction.date, order: .reverse)
        let predicate = #Predicate<Transaction> { _ in true }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [sortDescriptor])
        do
        {
            sortedTransactions = try modelContext.fetch(descriptor)
        }
        catch
        {
            fatalError("Failed to fetch transactions: \(error)")
        }
    }
}
