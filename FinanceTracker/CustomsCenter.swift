//
//  CustomsCenter.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 6/19/25.
//

import Foundation
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - FileDocument
struct TransactionFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var codableTransactions: [CodableTransaction]

    init(transactions: [Transaction]) {
        self.codableTransactions = transactions.map { CodableTransaction(from: $0) }
    }

    init(configuration: ReadConfiguration) throws {
        guard let fileData = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.codableTransactions = try JSONDecoder().decode([CodableTransaction].self, from: fileData)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(codableTransactions)
        return .init(regularFileWithContents: data)
    }
}

// MARK: - Observable Import/Export Manager
@Observable
class CustomsCenter {
    var isExporting: Bool = false
    var isImporting: Bool = false

    private var exportTransactions: [Transaction] = []
    private var importCallback: (([Transaction]) -> Void)?

    func presentExport(for transactions: [Transaction]) {
        self.exportTransactions = transactions
        self.isExporting = true
    }

    func presentImport(handler: @escaping ([Transaction]) -> Void) {
        self.importCallback = handler
        self.isImporting = true
    }

    func exportFile() -> TransactionFileDocument {
        TransactionFileDocument(transactions: exportTransactions)
    }

    func handleImport(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                do {
                    let data = try Data(contentsOf: url)
                    let decoded = try JSONDecoder().decode([CodableTransaction].self, from: data)
                    let models = decoded.map { $0.toModel() }
                    self.importCallback?(models)
                } catch {
                    print("❌ Import failed:", error.localizedDescription)
                }
            } else {
                print("❌ Could not start security scoped access")
            }
        case .failure(let error):
            print("❌ File selection failed:", error.localizedDescription)
        }
    }

}
