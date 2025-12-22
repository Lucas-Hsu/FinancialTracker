//
//  BackupDocument.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/22/25.
//

import SwiftUI
import UniformTypeIdentifiers

/// File Document implementation for import/export
struct BackupDocument: FileDocument
{
    // MARK: - Static Attributes
    static var readableContentTypes: [UTType] { [.json, UTType(exportedAs: "com.lucashsu.financetracker.transactions")] }

    // MARK: - Attributes
    var backup: BackupData

    // MARK: - Constructors
    // Export
    init(backup: BackupData)
    {
        self.backup = backup
    }
    // Import
    init(configuration: ReadConfiguration) throws
    {
        guard let data = configuration.file.regularFileContents else
        { throw CocoaError(.fileReadCorruptFile) }
        self.backup = try JSONDecoder().decode(BackupData.self, from: data)
    }

    // MARK: - Public Methods
    // Encodes data to json
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper
    {
        let data = try JSONEncoder().encode(backup)
        return .init(regularFileWithContents: data)
    }
}
