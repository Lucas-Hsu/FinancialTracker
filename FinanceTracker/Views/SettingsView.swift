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
    @State private var viewModel: SettingsViewModel = SettingsViewModel()
    // File handling state
    @State private var isExporting = false
    @State private var isImporting = false
    // Alert state
    @State private var showDeleteConfirmation = false
    @State private var showExportResult = false
    @State private var exportCount = 0
    @State private var showImportResult = false
    @State private var importAddedCount = 0
    
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
                    .padding(.bottom, 12)
                }
                else
                { ProgressView("Loading Transactions...").padding() }
            }
        }
        .onAppear
        { viewModel.refresh(transactions: allTransactions) }
        .padding()
        // Delete all
        .alert("Delete All Transactions?", isPresented: $showDeleteConfirmation)
        {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive)
            { viewModel.deleteAllTransactions(from: modelContext) }
        }
        message:
        { Text("This action cannot be undone.") }
        // Export alert
        .alert("Export Complete", isPresented: $showExportResult)
        { Button("OK", role: .cancel) { } }
        message:
        { Text("Exported \(exportCount) transactions.") }
        // Import alert
        .alert("Import Complete", isPresented: $showImportResult)
        { Button("OK", role: .cancel) { } }
        message:
        { Text("Added \(importAddedCount) new transactions.") }
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
                        Text("Transactions are stored in .JSON files.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                HStack(spacing: 15)
                {
                    DestructiveButtonGlass(title: "Delete All")
                    { showDeleteConfirmation = true }
                    .shadow(color: defaultButtonShadowColor, radius: 4, x: 0, y: 3)
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
        .fileExporter(isPresented: $isExporting,
                      document: viewModel.document,
                      contentType: .json,
                      defaultFilename: "FinanceBackup_\(DateFormatters.yyyyMMdd(date: Date()))")
        { result in
            if case .success = result
            { showExportResult = true }
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json], allowsMultipleSelection: false)
        { result in
            handleImport(result: result)
        }
    }
    
    // MARK: - Private Methods
    // Export
    private func prepareExport()
    {
        self.exportCount = viewModel.prepareExport()
        self.isExporting = true
    }
    // Import
    private func handleImport(result: Result<[URL], Error>)
    {
        viewModel.refresh(transactions: allTransactions)
        let count = viewModel.handleImport(result: result, modelContext: modelContext)
        self.importAddedCount = count
        self.showImportResult = true
    }
}
