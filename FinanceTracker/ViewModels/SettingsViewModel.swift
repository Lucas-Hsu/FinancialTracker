//
//  SettingsViewModel.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/23/25.
//

import Foundation
import SwiftData
import SwiftUI

/// Provides functionality for settings
@Observable
final class SettingsViewModel
{
    // MARK: - Observable Attributes
    var document: BackupDocument?
    
    // MARK: - Private Attributes
    @ObservationIgnored private var transactions: [Transaction] = []
    
    // MARK: - Public Methods
    // Refresh to get all transactions
    func refresh(transactions: [Transaction])
    {
        self.transactions = transactions
    }
    // Delete all transactions
    func deleteAllTransactions(from modelContext: ModelContext)
    {
        let transactions: [Transaction] = fetchTransactions(modelContext: modelContext)
        for transaction in transactions
        {
            if transactions.contains(transaction)
            {  modelContext.delete(transaction) }
        }
        if modelContext.saveSuccess()
        {
            NotificationCenter.default.post(name: .transactionsUpdated, object: nil)
        }
    }
    // Export
    func prepareExport() -> Int
    {
        let txCodables = transactions.map
        { TransactionCodable(from: $0) }
        self.document = BackupDocument(backup: BackupData(transactions: txCodables))
        return txCodables.count
    }
    // Import
    func handleImport(result: Result<[URL], Error>, modelContext: ModelContext) -> Int
    {
        var addedCount: Int = 0
        do
        {
            guard let selectedFile = try result.get().first else
            { return 0 }
            if selectedFile.startAccessingSecurityScopedResource()
            {
                let data = try Data(contentsOf: selectedFile)
                let decoded = try JSONDecoder().decode(BackupData.self, from: data)
                let existingTransactions = fetchTransactions(modelContext: modelContext)
                let existingIDs = Set(existingTransactions.map { $0.id })
                for txCodable in decoded.transactions
                {
                    if !existingIDs.contains(txCodable.id)
                    {
                        modelContext.insert(txCodable.toModel())
                        addedCount += 1
                    }
                }
                if addedCount > 0 && modelContext.saveSuccess()
                { NotificationCenter.default.post(name: .transactionsUpdated, object: nil) }
                selectedFile.stopAccessingSecurityScopedResource()
            }
        }
        catch
        {
            print("Import error: \(error)")
            return 0
        }
        return addedCount
    }
    
    // MARK: - Private Helpers
    // Fetch transactions from modelContext
    private func fetchTransactions(modelContext: ModelContext) -> [Transaction]
    {
        do
        {
            let descriptor = FetchDescriptor<Transaction>()
            return try modelContext.fetch(descriptor)
        }
        catch
        {
            print("Failed to fetch Transactions: \(error)")
            return []
        }
    }
}
