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
    private(set) var transactionBST: TransactionBST
    private(set) var isLoading: Bool = true
    
    // MARK: - Fully Private
    @ObservationIgnored let modelContext: ModelContext
    @ObservationIgnored private var transactionObserver: Any?
    
    // MARK: - Constructors
    init(modelContext: ModelContext, transactionBST: TransactionBST)
    {
        self.modelContext = modelContext
        self.transactionBST = transactionBST
        setupTransactionObserver()
        // Check if BST is already ready (e.g., from previous init)
        if transactionBST.isReady {
            loadSortedTransactions()
            isLoading = false  // MARK: Data ready, no loading needed
        }
                // If not ready, observer will handle initial load notification
        
    }
    
    deinit
    {
        if let token = transactionObserver
        {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    // MARK: - Public Methods
    func refresh() {
        loadSortedTransactions()
    }
    
    // MARK: - Helpers Methods
    private func setupTransactionObserver() {
            transactionObserver = NotificationCenter.default.addObserver(
                forName: .transactionBSTUpdated,
                object: transactionBST,  // CHANGED: Observe specific BST instance
                queue: .main
            ) { [weak self] notification in
                guard let self = self else { return }
                
                let isInitialLoad = notification.userInfo?["initialLoad"] as? Bool ?? false
                
                if isInitialLoad {
                    // MARK: Handle initial async load completion
                    self.loadSortedTransactions()
                    self.isLoading = false
                    print("ViewModel: Initial load complete")
                } else {
                    // MARK: Handle subsequent updates
                    self.loadSortedTransactions()
                    print("ViewModel: Updated with changes")
                }
            }
        }
    
    private func loadSortedTransactions() {
            // Ensure BST is ready before accessing data
            guard transactionBST.isReady else {
                print("ViewModel: BST not ready yet, skipping load")
                return
            }
            
            let transactions = transactionBST.inOrderTraversal()
            sortedTransactions = transactions.sorted { $0.date > $1.date }
            print("ViewModel: Loaded \(sortedTransactions.count) sorted transactions")
        }
}
