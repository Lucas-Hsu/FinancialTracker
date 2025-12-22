//
//  SettingsView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/22/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// View to manage `Transaction`s and `Transaction` patterns
struct SettingsView: View
{
    // MARK: - Private Attributes
    @Environment(\.modelContext) private var modelContext
    @Query private var allTransactions: [Transaction]
    @State private var document: BackupDocument?
    @State private var isExporting = false
    @State private var isImporting = false
    var transactionBST: TransactionBST?

    // MARK: - UI
    var body: some View
    {
        VStack(spacing: 8)
        {
            settingsSection
            Group
            {
                if let bst = transactionBST
                {
                    RecurringTransactionListView(modelContext: modelContext, transactionBST: bst)
                    .padding(.bottom)
                }
                else
                { ProgressView("Loading Transactions...").padding() }
            }
        }
        .padding()
    }
    
    // MARK: - Components
    private var settingsSection: some View
    {
        VStack(alignment: .leading, spacing: 4)
        {
            // Header
            Text("Settings")
            .font(.system(size: 28, weight: .semibold))
            .padding(.horizontal)
            // Data Management
            HStack
            {
                HStack
                {
                    Image(systemName: "externaldrive.fill.badge.checkmark")
                    .font(.title)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 50, height: 50)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Circle())
                    VStack(alignment: .leading)
                    {
                        Text("Data Management")
                        .font(.headline)
                        Text("Transactions are stored in .transactions files (JSON)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                HStack(spacing: 15)
                {
                    PrimaryButtonGlass(title: "Export")
                    { prepareExport() }
                    .shadow(color: defaultButtonShadowColor, radius: 4, x: 0, y: 3)
                    SecondaryButtonGlass(title: "Import")
                    { isImporting = true }
                    .shadow(color: defaultButtonShadowColor.opacity(0.4), radius: 4, x: 0, y: 3)
                }
            }
            .padding(10)
            .background(defaultPanelBackgroundColor)
            .cornerRadius(16)
            .shadow(color: defaultPanelShadowColor, radius: 4, x: 0, y: 3)
        }
        .padding(.bottom)
        .fileExporter(isPresented: $isExporting, document: document, contentType: .json, defaultFilename: "FinanceBackup_\(DateFormatters.yyyyMMdd(date: Date()))")
        { _ in }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json], allowsMultipleSelection: false)
        { result in
            handleImport(result: result)
        }
    }
    
    // MARK: - Private Methods
    // Export
    private func prepareExport()
    {
        let txCodables = allTransactions.map
        { TransactionCodable(from: $0) }
        self.document = BackupDocument(backup: BackupData(transactions: txCodables))
        self.isExporting = true
    }
    // Import
    private func handleImport(result: Result<[URL], Error>)
    {
        do
        {
            guard let selectedFile = try result.get().first else
            { return }
            if selectedFile.startAccessingSecurityScopedResource()
            {
                let data = try Data(contentsOf: selectedFile)
                let decoded = try JSONDecoder().decode(BackupData.self, from: data)
                for tx in decoded.transactions
                { modelContext.insert(tx.toModel()) }
                try? modelContext.save()
                NotificationCenter.default.post(name: .transactionsUpdated, object: nil)
                selectedFile.stopAccessingSecurityScopedResource()
            }
        }
        catch
        { print("Import error: \(error)") }
    }
}

