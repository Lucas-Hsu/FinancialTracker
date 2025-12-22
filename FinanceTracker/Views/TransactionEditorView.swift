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
        HStack(spacing: 20)
        {
            // MARK: Receipt Image Editor
            Group
            {
                if #available(iOS 26.0, *)
                {
                    ReceiptImageView(receiptData: $receiptImage)
                    .glassEffect(.regular, in: .rect(cornerRadius: 12))
                }
                else
                {
                    ReceiptImageView(receiptData: $receiptImage)
                    .background(Color(UIColor.secondarySystemBackground))
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // MARK: Transaction Form
            Group
            {
                if #available(iOS 26.0, *)
                {
                    transactionForm
                    .glassEffect(.regular, in: .rect(cornerRadius: 20))
                }
                else
                { transactionForm }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(BackgroundImage("GradientsFlipped"))
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
    
    // MARK: - Components
    private var transactionForm: some View
    {
        VStack(spacing: 4)
        {
            // MARK: Form
            VStack(spacing: 30)
            {
                VStack(spacing: 8)
                {
                    // Price
                    HStack(alignment: .firstTextBaseline, spacing: 4)
                    {
                        Text("¥")
                        .font(.system(size: 40, weight: .regular))
                        .foregroundStyle(.secondary)
                        TextField("0", value: $price, formatter: PriceFormatter.formatter)
                        .font(.system(size: 56, weight: .bold))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .fixedSize()
                    }
                    // Name
                    TextField("Transaction Name", text: $name)
                    .frame(maxWidth: 540)
                    .font(.system(size: 26, weight: .light))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(UIColor.systemGray).mix(with: .primary, by: 0.5))
                    .lineLimit(1)
                    .truncationMode(.middle)
                }
                // isPaid
                MorphingToggleButtonGlass(toggle: $isPaid, onText: "Paid", offText: "Pending")
                .shadow(color: defaultPanelShadowColor, radius: 4, x: 0, y: 3)
                Divider()
                .background(Color(UIColor.systemGray))
                VStack(spacing: 20)
                {
                    // Date
                    DatePicker("Date", selection: $date)
                    .font(.system(size: 22, weight: .medium))
                    // Tag
                    HStack(spacing: 10)
                    {
                        Text("Category")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.primary)
                        Spacer()
                        Picker("Category", selection: $tag)
                        {
                            ForEach(Tag.allCases, id: \.self)
                            { tag in
                                Image(systemName: tagSymbols[tag] ?? "questionmark").tag(tag)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: .infinity)
                    }
                }
                Divider()
                .background(Color(UIColor.systemGray))
                // Notes
                VStack(alignment: .leading, spacing: 10)
                {
                    Text("Notes")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.secondary)                
                    TextEditor(text: Binding( get: { notes?.joined(separator: "\n") ?? "" },
                                              set: { notes = $0.isEmpty ? nil : $0.split(separator: "\n").map(String.init) }))
                    .frame(height: 180)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .background(Color.primary.opacity(0.08))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            .padding(.top, 30)
            .padding(.horizontal, 30)
            // MARK: Action buttons
            HStack(spacing: 40)
            {
                // Save transaction
                PrimaryButtonGlass(title: "Save")
                {
                    viewModel.save(date: date, name: name, price: price, tag: tag, isPaid: isPaid, notes: notes, receiptImage: receiptImage)
                    if viewModel.hasSaved
                    { dismiss() }
                }
                .shadow(color: defaultButtonShadowColor, radius: 4, x: 0, y: 3)
                // Delete transaction
                if (!viewModel.isNew)
                {
                    DestructiveButtonGlass(title: "Delete")
                    {
                        viewModel.delete()
                        if viewModel.hasDeleted
                        { dismiss() }
                    }
                    .shadow(color: defaultButtonShadowColor, radius: 4, x: 0, y: 3)
                }
                // Cancel operation
                SecondaryButtonGlass(title: "Cancel")
                {
                    viewModel.cancel()
                    if (!viewModel.hasSaved && !viewModel.hasDeleted)
                    { dismiss() }
                }
                .shadow(color: defaultButtonShadowColor, radius: 4, x: 0, y: 3)
            }
            .padding(20)
        }
        .frame(maxHeight: .infinity)
    }
}
