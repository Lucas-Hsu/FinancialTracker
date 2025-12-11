//
//  TransactionEditorViewModel.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/11/25.
//

import Foundation
import SwiftData

/// `TransactionEditorViewModel` provides methods for the UI to use for adding new and editing `Transaction` objects, reading from and saving to ModelContext.
@Observable
final class TransactionEditorViewModel
{
    // MARK: - Read-only Attributes: the View can access and be notified of change in.
    private(set) var transaction: Transaction
    private(set) var isNew: Bool
    private(set) var hasSaved: Bool = false
    private(set) var hasDeleted: Bool = false
    private(set) var errorMessage: String?
    
    // MARK: - Fully Private: No need to be observed by View.
    @ObservationIgnored private let modelContext: ModelContext
    
    // MARK: - Constructors
    init(modelContext: ModelContext)
    {
        self.modelContext = modelContext
        self.transaction = Transaction()
        self.isNew = true
    }
    init(transaction: Transaction, modelContext: ModelContext)
    {
        self.modelContext = modelContext
        self.transaction = transaction
        self.isNew = false
    }
    
    // MARK: - Public Methods
    func save(date: Date,
              name: String,
              price: Double,
              tag: Tag,
              isPaid: Bool,
              notes: [String]? = nil,
              receiptImage: Data? = nil)
    {
        guard validate(date: date,
                       name: name,
                       price: price,
                       tag: tag,
                       isPaid: isPaid,
                       notes: notes,
                       receiptImage: receiptImage)
        else
        {
            print("[WARN] Aborted Transaction save.")
            return
        }
        
        _ = writeToTransaction(date: date,
                            name: name,
                            price: price,
                            tag: tag,
                            isPaid: isPaid,
                            notes: notes,
                            receiptImage: receiptImage)
        
        if (isNew)
        {
            modelContext.insert(transaction)
            isNew = false
        }
        
        if (modelContext.saveSuccess())
        {
            hasSaved = true
            hasDeleted = false
        }
    }
    
    func delete()
    {
        if (!isNew)
        {
            modelContext.delete(transaction)
            if modelContext.saveSuccess()
            {
                hasDeleted = true
                hasSaved = false
            }
            return
        }
        print("[WARN] No need to delete when adding new Transaction.")
    }

    func cancel()
    {
        hasSaved = false
        hasDeleted = false
    }
    
    // MARK: - Helpers Methods
    private func validate(date: Date,
                          name: String,
                          price: Double,
                          tag: Tag,
                          isPaid: Bool,
                          notes: [String]? = nil,
                          receiptImage: Data? = nil) -> Bool
    {
        if (transaction.isNameValid(name: name))
        {
            print("[ERROR] Name cannot be empty. Set to default.")
            return false
        }
        else if (transaction.isPriceValid(price: price))
        {
            print("[ERROR] Price \(price) cannot be negative. Set as absolute value.")
            return false
        }
        else if (transaction.isDateValid(date: date))
        {
            print("[ERROR] \(date.toMediumString()) Date cannot be in the future. Set to default.")
            return false
        }
        else if (!transaction.isTagValid(tag: tag) || !transaction.isIsPaidValid(isPaid: isPaid) || !transaction.isNotesValid(notes: notes) || !transaction.isReceiptImageValid(receiptImage: receiptImage))
        {
            print("[ERROR] Uncaught error type.")
            return false
        }
        return true
    }
    
    private func writeToTransaction(date: Date,
                                 name: String,
                                 price: Double,
                                 tag: Tag,
                                 isPaid: Bool,
                                 notes: [String]? = nil,
                                 receiptImage: Data? = nil) -> Bool
    {
        guard validate(date: date,
                       name: name,
                       price: price,
                       tag: tag,
                       isPaid: isPaid,
                       notes: notes,
                       receiptImage: receiptImage) else
        { return false }
        transaction.setDate(date: date)
        transaction.setName(name: name)
        transaction.setPrice(price: price)
        transaction.setTag(tag: tag)
        transaction.setIsPaid(isPaid: isPaid)
        transaction.setNotes(notes: notes)
        transaction.setReceiptImage(receiptImage: receiptImage)
        return true
    }
}
