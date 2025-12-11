//
//  ImportExportViewModel.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/11/25.
//

import Foundation
import SwiftData

/// Allows import and export of `Transaction` data for backup or migration.
class ImportExportViewModel
{
    static func serialize(from context: ModelContext) throws -> Data
    {
        let fetchDescriptor = FetchDescriptor<Transaction>()
        let transactions = try context.fetch(fetchDescriptor)
        
        let codables = transactions.map { TransactionCodable(from: $0) }
        return try JSONEncoder().encode(codables)
    }
    static func deserialize(from: Data, into context: ModelContext) throws -> Int
    {
        let codables = try JSONDecoder().decode([TransactionCodable].self, from: from)
        
        for codable in codables
        {
            let transaction = codable.toModel()
            context.insert(transaction)
        }
        
        _ = context.saveSuccess()
        return codables.count
    }
}

/*
import SwiftUI

import UniformTypeIdentifiers

@Observable
class ImportExportViewModel {
    // UI State
    var isExporting = false
    var isImporting = false
    var errorMessage: String?
    
    // File Operations
    func exportToFile(from context: ModelContext) -> TransactionExportDocument {
        let data = try! Transaction.exportAll(from: context)
        return TransactionExportDocument(data: data)
    }
    
    func importFromFile(url: URL, into context: ModelContext) throws -> Int {
        let data = try Data(contentsOf: url)
        return try Transaction.importFrom(data: data, into: context)
    }
}

// MARK: - SwiftUI File Document
struct TransactionExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    
    // ... init and fileWrapper implementations
}
*/
