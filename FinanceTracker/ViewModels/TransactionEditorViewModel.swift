//
//  TransactionEditorViewModel.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/11/25.
//

import Foundation
import SwiftData

/// Methods for the UI to use for adding new and editing `Transaction` objects, reading from and saving to ModelContext.
@Observable
final class TransactionEditorViewModel
{
    // MARK: - Read-only Attributes
    private(set) var transaction: Transaction
    private(set) var isNew: Bool
    private(set) var hasSaved: Bool = false
    private(set) var hasDeleted: Bool = false
    private(set) var errorMessage: String = ""
    
    // MARK: - Detected OCR Values (Observable by View)
    var detectedName: String? = nil
    var detectedPrice: Double? = nil
    var detectedDate: Date? = nil
    var detectedNote: String? = nil
    
    // MARK: - Fully Private
    @ObservationIgnored let modelContext: ModelContext
    @ObservationIgnored private var ocrObserver: Any?
    
    // MARK: - Constructors
    init(modelContext: ModelContext, isNew: Bool, transaction: Transaction = Transaction())
    {
        self.modelContext = modelContext
        self.isNew = isNew
        if isNew
        { self.transaction = Transaction() }
        else
        { self.transaction = transaction }
        setupOCRObserver()
        print("TransactionEditorViewModel isNew \(self.isNew)")
    }
    
    // MARK: - Destructors
    deinit
    {
        if let token = ocrObserver
        { NotificationCenter.default.removeObserver(token) }
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
    
    // MARK: - OCR Logic
    // Set up notif for ocrBubbleTapped
    private func setupOCRObserver()
    {
        ocrObserver = NotificationCenter.default.addObserver(forName: .ocrBubbleTapped,
                                                             object: nil,
                                                             queue: .main)
        { [weak self] notification in
            guard let self = self,
                  let text = notification.object as? String else
            { return }
            self.parseOCRString(text)
        }
    }
    // Parses a raw OCR string, in order: Date -> Price -> Name/Note.
    private func parseOCRString(_ rawText: String)
    {
        var workingText: String = rawText
        var foundDate: Date? = nil
        var foundPrice: Double? = nil
        var foundName: String? = nil
        // Extract Date
        if let (date, remainingText) = extractDate(from: workingText)
        {
            if date <= Date().addingTimeInterval(3600) // Do not allow dates from the future future
            {
                foundDate = date
                workingText = remainingText
            }
        }
        // Extract Price
        if let (price, remainingText) = extractPrice(from: workingText)
        {
            foundPrice = price
            workingText = remainingText
        }
        // Extract Name/Notes
        let cleanedRemainder = cleanupNoise(workingText)
        if !cleanedRemainder.isEmpty
        {
            if let _ = cleanedRemainder.rangeOfCharacter(from: .letters)
            {
                if cleanedRemainder.count < 48
                { foundName = cleanedRemainder }
                else
                { self.detectedNote = cleanedRemainder }
            }
        }
        // Update With Extract Success Content
        if let d = foundDate { self.detectedDate = d }
        if let p = foundPrice { self.detectedPrice = p }
        if let n = foundName { self.detectedName = n }
    }
    // Finds the first valid date in String, returns extracted Date date and remaining text after extracting date.
    private func extractDate(from text: String) -> (Date, String)?
    {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else
        { return nil }
        let range = NSRange(location: 0, length: text.utf16.count)
        let matches = detector.matches(in: text, options: [], range: range)
        // Assume the first match is the date we want
        if let match = matches.first, let date = match.date, let rangeRange = Range(match.range, in: text)
        {
            var newText = text
            newText.removeSubrange(rangeRange)
            return (date, newText)
        }
        return nil
    }
    // Finds the first valid price pattern in String, returns extracted Double price and remaining text after extracting.
    private func extractPrice(from text: String) -> (Double, String)?
    {
        // Integers are not prices
        let pattern = #"[¥$€£]?\s?(\d{1,3}(?:[.,]\d{3})*[.,]\d{2})"# // [Optional currency symbol] [Optional space] [1 to 3 digits] [Optional thousand separators] [3 digits]  [Mandatory cents separator] [2 digits]
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else
        { return nil }
        let range = NSRange(location: 0, length: text.utf16.count)
        let matches = regex.matches(in: text, options: [], range: range)
        // Max value we assume is total
        var bestMatch: (Double, NSRange)? = nil
        for match in matches
        {
            let matchRange = match.range
            if let swiftRange = Range(matchRange, in: text)
            {
                var priceString = String(text[swiftRange])
                let symbols = ["¥", "$", "€", "£", " ", ","]
                for s in symbols { priceString = priceString.replacingOccurrences(of: s, with: "") }
                if let value = Double(priceString)
                {
                    guard let currentBest = bestMatch else
                    { // First match
                        bestMatch = (value, matchRange)
                        continue
                    }
                    if value > currentBest.0
                    { bestMatch = (value, matchRange) }
                }
            }
        }
        if let (price, matchRange) = bestMatch,
           let rangeRange = Range(matchRange, in: text)
        {
            var newText = text
            newText.removeSubrange(rangeRange)
            return (price, newText)
        }
        return nil
    }
    // Remove OCR artifacts like bullets and random punctuation
    private func cleanupNoise(_ text: String) -> String
    {
        var result = text.strip()
        let markers = ["•", "-", "*", ">"]
        result = trimFromSide(result, isPrefix: true, clean: markers)
        result = trimFromSide(result, isPrefix: false, clean: markers)
        return result
    }
    // Remove OCR artifacts like bullets and random punctuation one side
    private func trimFromSide(_ string: String, isPrefix: Bool, clean markers: [String]) -> String
    {
        var str = string
        for marker in markers
        {
            let hasMarker = isPrefix ? str.hasPrefix(marker) : str.hasSuffix(marker)
            if hasMarker
            {
                str = isPrefix ? String(str.dropFirst(marker.count)).strip() : String(str.dropLast(marker.count)).strip()
                return trimFromSide(str, isPrefix: isPrefix, clean: markers)
            }
        }
        return str
    }
    // Ensure transaction values are correct
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
    // Save a transaction
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
