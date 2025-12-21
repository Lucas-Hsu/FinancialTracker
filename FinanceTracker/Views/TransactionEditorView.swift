//
//  TransactionEditorView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/11/25.
//

import SwiftUI
import SwiftData

/// View for adding, editing, and deleting individual Transaction objects. Connects to `TransactionEditorViewModel`.
struct TransactionEditorView: View
{
    // MARK: - Private Attributes
    // Transaction
    @State private var date: Date
    @State private var name: String
    @State private var price: Double
    @State private var tag: Tag
    @State private var isPaid: Bool
    @State private var notes: [String]?
    @State private var receiptImage: Data?
    // Dependencies
    @State private var viewModel: TransactionEditorViewModel
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Constructors
    init(modelContext: ModelContext, isNew: Bool, transaction: Transaction = Transaction())
    {
        print("TransactionEditorView Editing existing Transaction.")
        _date = State(initialValue: transaction.date)
        _name = State(initialValue: transaction.name)
        _price = State(initialValue: transaction.price)
        _tag = State(initialValue: transaction.tag)
        _isPaid = State(initialValue: transaction.isPaid)
        _notes = State(initialValue: transaction.notes)
        _receiptImage = State(initialValue: transaction.receiptImage)
        _viewModel = State(initialValue: TransactionEditorViewModel(modelContext: modelContext,
                                                                    isNew: isNew,
                                                                    transaction: transaction))
    }
    
    // MARK: - UI
    var body: some View
    {
        HStack
        {
            // MARK: Receipt Image Editor
            ReceiptImageView(receiptData: $receiptImage)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // MARK: Transaction Details Editor
            VStack
            {
                // MARK: Form
                VStack(spacing: 20)
                {
                    if viewModel.errorMessage != ""
                    { Text(viewModel.errorMessage) }
                    // Name
                    TextField("Name", text: $name)
                    // Price
                    HStack
                    {
                        Text("¥")
                        TextField("Price", value: $price, formatter: PriceFormatter.formatter)
                        Spacer()
                    }
                    // IsPaid
                    Toggle("Payment Deposited", isOn: $isPaid)
                    // Date
                    DatePicker("Date", selection: $date)
                    // Tag
                    Picker("Category", selection: $tag)
                    {
                        ForEach(Tag.allCases, id: \.self)
                        { tag in
                            let symbol = tagSymbols[tag] ?? "questionmark"
                            Image(systemName: symbol).tag(tag)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    // Notes
                    TextEditor(text: Binding( get: { notes?.joined(separator: "\n") ?? "" },
                                              set: { notes = $0.isEmpty ? nil : $0.split(separator: "\n").map(String.init) } ))
                    .frame(height: 100)
                }
                .padding()
                Spacer()
                // MARK: Action Buttons
                HStack {
                    // Save the Transaction to modelContext
                    PrimaryButtonGlass(title: "Save")
                    {
                        viewModel.save(date: date,
                                       name: name,
                                       price: price,
                                       tag: tag,
                                       isPaid: isPaid,
                                       notes: notes,
                                       receiptImage: receiptImage)
                        if viewModel.hasSaved
                        { dismiss() }
                    }
                    .padding()
                    // Only show Delete if it's an existing Transaction
                    if (!viewModel.isNew)
                    {
                        DestructiveButtonGlass(title: "Delete")
                        {
                            viewModel.delete()
                            if viewModel.hasDeleted
                            { dismiss() }
                        }
                        .padding()
                    }
                    // Cancel the operation, nothing is changed
                    SecondaryButtonGlass(title: "Cancel")
                    {
                        viewModel.cancel()
                        if (!viewModel.hasSaved && !viewModel.hasDeleted)
                        { dismiss() }
                    }
                    .padding()
                }
            }
            .frame(width: 0.5 * UIScreen.main.bounds.width)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BackgroundImage())
        // MARK: OCR Listeners (trigger when valid data received)
        .onChange(of: viewModel.detectedName)
        { _, newName in
            if let n = newName { self.name = n }
        }
        .onChange(of: viewModel.detectedPrice)
        { _, newPrice in
            if let p = newPrice { self.price = p }
        }
        .onChange(of: viewModel.detectedDate)
        { _, newDate in
            if let d = newDate { self.date = d }
        }
        .onChange(of: viewModel.detectedNote)
        { _, newNote in
            if let n = newNote
            {
                var currentNotes = self.notes ?? []
                if !currentNotes.contains(n)
                { // Avoid duplicates
                    currentNotes.append(n)
                    self.notes = currentNotes
                }
            }
        }
    }
}
