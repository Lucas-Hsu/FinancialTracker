//
//  TransactionEditorView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/11/25.
//

import SwiftUI
import SwiftData

struct TransactionEditorView: View
{
    // MARK: - Attributes
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
        init(modelContext: ModelContext) {
            // Initialize View state with defaults
            _date = State(initialValue: Date())
            _name = State(initialValue: "")
            _price = State(initialValue: 0)
            _tag = State(initialValue: .other)
            _isPaid = State(initialValue: true)
            _notes = State(initialValue: nil)
            _receiptImage = State(initialValue: nil)
            
            // Initialize ViewModel
            _viewModel = State(initialValue: TransactionEditorViewModel(modelContext: modelContext))
        }
        
        init(transaction: Transaction, modelContext: ModelContext) {
            print("Editing Existing Transaction.")
            // Initialize View state with existing transaction values
            _date = State(initialValue: transaction.date)
            _name = State(initialValue: transaction.name)
            _price = State(initialValue: transaction.price)
            _tag = State(initialValue: transaction.tag)
            _isPaid = State(initialValue: transaction.isPaid)
            _notes = State(initialValue: transaction.notes)
            _receiptImage = State(initialValue: transaction.receiptImage)
            
            // Initialize ViewModel with transaction
            _viewModel = State(initialValue: TransactionEditorViewModel(
                transaction: transaction,
                modelContext: modelContext
            ))
        }
    
    // MARK: - UI
    var body: some View
    {
        VStack
        {
            // MARK: Form
                VStack(spacing: 20)
            {
                TextField("Name", text: $name)
                TextField("Price", value: $price, formatter: PriceFormatter.formatter )
                DatePicker("Date", selection: $date)
                Picker("Category", selection: $tag)
                {
                    ForEach(Tag.allCases, id: \.self)
                    { tag in
                        Text(tag.rawValue).tag(tag)
                    }
                }
                    .pickerStyle(SegmentedPickerStyle())
                
                Toggle("Paid", isOn: $isPaid)
                
                // Notes field
                TextEditor(text: Binding(
                    get: { notes?.joined(separator: "\n") ?? "" },
                    set: { notes = $0.isEmpty ? nil : $0.split(separator: "\n").map(String.init) }
                ))
                    .frame(height: 100)
            }
                .padding()
            
            Spacer()
            
            // MARK: Action Buttons
            HStack {
                PrimarySaveButtonGlass
                {
                    viewModel.save(
                        date: date,
                        name: name,
                        price: price,
                        tag: tag,
                        isPaid: isPaid,
                        notes: notes,
                        receiptImage: receiptImage
                    )
                    if viewModel.hasSaved
                    {
                        dismiss()
                    }
                }
                .padding()
                
                SecondaryCancelButtonGlass
                {
                    viewModel.cancel()
                    if (!viewModel.hasSaved && !viewModel.hasDeleted)
                    {
                        dismiss()
                    }
                }
                .padding()
                
                if (!viewModel.isNew)
                {
                    DestructiveDeleteButtonGlass
                    {
                        viewModel.delete()
                        if viewModel.hasDeleted
                        {
                            dismiss()
                        }
                    }
                    .padding()
                }
            }
        }
    }
}
