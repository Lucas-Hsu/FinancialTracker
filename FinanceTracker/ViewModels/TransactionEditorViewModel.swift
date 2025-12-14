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
    // MARK: - Read-only Attributes
    private(set) var transaction: Transaction
    private(set) var isNew: Bool
    private(set) var hasSaved: Bool = false
    private(set) var hasDeleted: Bool = false
    private(set) var errorMessage: String = ""
    
    // MARK: - Fully Private
    @ObservationIgnored let modelContext: ModelContext
    
    // MARK: - Constructors
    init(modelContext: ModelContext)
    {
        self.modelContext = modelContext
        self.transaction = Transaction()
        self.isNew = true
        print("TransactionEditorViewModel isNew \(self.isNew)")
    }
    init(transaction: Transaction, modelContext: ModelContext)
    {
        self.modelContext = modelContext
        self.transaction = transaction
        self.isNew = false
        print("TransactionEditorViewModel isNew \(self.isNew)")
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
        if modelContext.saveSuccess()
        {
            hasSaved = true
            hasDeleted = false
            NotificationCenter.default.post(name: .transactionsUpdated,
                                            object: nil,
                                            userInfo: ["operation": isNew ? "insert" : "update"])
            print("TransactionEditorViewModel Saved Transaction and posted .transactionsUpdated notif.")
        }
    }
    
    func delete()
    {
        print("TransactionEditorViewModel attempted delete(), isNew \(self.isNew)")
        guard !isNew else
        {
            print("[WARN] No need to delete when adding new Transaction.")
            return
        }
        modelContext.delete(transaction)
        if modelContext.saveSuccess()
        {
            hasDeleted = true
            hasSaved = false
            NotificationCenter.default.post(name: .transactionsUpdated,
                                            object: nil,
                                            userInfo: ["operation": "delete"])
            print("TransactionEditorViewModel Deleted Transaction and posted .transactionsUpdated notif.")
        }
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
        if (!transaction.isNameValid(name: name))
        {
            errorMessage = "[WARN] Name cannot be empty. Set to default."
            print(errorMessage)
            // return false
        }
        if (!transaction.isPriceValid(price: price))
        {
            errorMessage = "[ERROR] Price \(price) cannot be negative. Save aborted."
            print(errorMessage)
            return false
        }
        if (!transaction.isDateValid(date: date))
        {
            errorMessage = "[ERROR] \(date.toMediumString()) Date cannot be in the future. Save aborted."
            print(errorMessage)
            return false
        }
        if (!transaction.isTagValid(tag: tag) || !transaction.isIsPaidValid(isPaid: isPaid) || !transaction.isNotesValid(notes: notes) || !transaction.isReceiptImageValid(receiptImage: receiptImage))
        {
            errorMessage = "[ERROR] Uncaught error type. Save aborted."
            print(errorMessage)
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
