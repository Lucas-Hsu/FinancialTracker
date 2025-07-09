//
//  RecurringTransaction.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 2/25/25.
//

import SwiftUI
import SwiftData
import Foundation

struct RecurringTransactionSignature: Codable, Equatable, Hashable
{
    var beginDate: Date
    var intervalType: TypesOfRecurringTransaction
    var interval: Int
    var name: String
    var price: Double
    var tag: Tag
    var notes: [String]?
    
    
    init(name: String,
         price: Double,
         tag: Tag,
         notes: [String]? = nil,
         beginDate: Date = Date(),
         intervalType: TypesOfRecurringTransaction = .Custom,
         interval: Int = 1)
    {
        self.name = name
        self.price = price
        self.tag = tag
        self.notes = notes
        self.beginDate = beginDate
        self.intervalType = intervalType
        self.interval = interval
    }
    
    init (recurringTransaction: RecurringTransaction) {
        self.name = recurringTransaction.name
        self.price = recurringTransaction.price
        self.tag = recurringTransaction.tag
        self.notes = recurringTransaction.notes
        self.beginDate = recurringTransaction.beginDate
        self.intervalType = recurringTransaction.intervalType
        self.interval = recurringTransaction.interval
    }
}

@Model class RecurringTransaction: Equatable
{
    @Attribute(.unique) var id: UUID
    var beginDate: Date
    var intervalType: TypesOfRecurringTransaction
    var interval: Int
    var name: String
    var tag: Tag
    var price: Double
    var notes: [String]?

    var signature : RecurringTransactionSignature
    { RecurringTransactionSignature(recurringTransaction: self) }
    
    init(beginDate: Date = Date(),
         intervalType: TypesOfRecurringTransaction = TypesOfRecurringTransaction.Yearly,
         interval : Int = 1,
         name: String = "Recurring Transaction",
         tag: Tag = Tag.other,
         price: Double = 1999,
         notes: [String]? = nil)
    {
        self.id = UUID()
        self.beginDate = beginDate
        self.intervalType = intervalType
        self.interval = interval
        self.name = name
        self.tag = tag
        self.price = price
        self.notes = notes
    }
    
    init(patternType : TransactionPattern = TransactionPattern(beginDate: Date(),
                                                               type: .Yearly,
                                                               interval: 1),
         name: String = "Recurring Transaction",
         tag: Tag = Tag.other,
         price: Double = 1999,
         notes: [String]? = nil)
    {
        self.id = UUID()
        self.beginDate = patternType.getBeginDate()
        self.intervalType = patternType.getType()
        self.interval = patternType.getInterval()
        self.name = name
        self.tag = tag
        self.price = price
        self.notes = notes
    }
    
    public func toString() -> String {
        return "\(name), \(intervalType), \(tag)"
    }
    
    private func getTransactionPattern() -> TransactionPattern
    {
        return TransactionPattern(beginDate: self.beginDate, type: intervalType.toInternal(), interval: interval)
    }
    
    public func occursOn(date: Date) -> Bool
    {
        if Calendar.current.startOfDay(for: self.beginDate) > Calendar.current.startOfDay(for: date)
        { return false }
        let pattern : TransactionPattern = getTransactionPattern()
        switch (pattern.getType())
        {
        case .Yearly:
            var i : Int = 0
            var dateRunner : Date = self.beginDate
            while dateRunner <= date.addingTimeInterval(365*24*3600)
            {
                if dateRunner.sameDayAs(date)
                {
                    return i % pattern.getInterval() == 0
                }
                i += 1
                dateRunner = Calendar.current.date(byAdding: .year, value: i, to: dateRunner)!
            }
        case .Monthly:
            var i : Int = 0
            var dateRunner : Date = self.beginDate
            while dateRunner <= date.addingTimeInterval(30*24*3600)
            {
                if dateRunner.sameDayAs(date)
                {
                    return i % pattern.getInterval() == 0
                }
                i += 1
                dateRunner = Calendar.current.date(byAdding: .month, value: i, to: dateRunner)!
            }
        case .Weekly:
            let interval : Int = self.beginDate.amountOfDays(from: date)
            return interval % 7 == 0
                    && interval/7 % pattern.getInterval() == 0
        case .Custom:
            let interval : Int = self.beginDate.amountOfDays(from: date)
            return interval % pattern.getInterval() == 0
        }
        return false
    }
    
    public func reccursOn(date: Date) -> Bool
    {
        return !date.sameDayAs(self.beginDate) && occursOn(date: date)
    }
    
    public func transactionOn(date: Date, from transactions: [Transaction]) -> Transaction?
    {
        for transaction in transactions
        {
            if transaction.sameDayAs(date: date)
            { return transaction }
        }
        return nil
    }
    
    public func isIn(array: [RecurringTransaction]) -> Bool
    {
        for recurringTransaction in array
        {
            if recurringTransaction.id == self.id
            { return true }
        }
        return false
    }
    
    public func eventDescription() -> String
    {
        let words : [TypesOfRecurringTransaction : [String]] = [.Yearly : ["yearly", "years"],
                                                                .Monthly : ["monthly", "months"],
                                                                .Weekly : ["weekly", "weeks"],
                                                                .Custom : ["daily", "days"]]
        let formatter = DateFormatter()
        formatter.timeZone = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        let description : String = "\(self.name), \(self.price); Started on \(self.beginDate.localDescription), recurs "
        if self.interval != 1
        {
            return description + "every \(self.interval) \(words[self.intervalType]?[1] ?? "[ERROR]")."
        } else {
            return description + "\(words[self.intervalType]?[0] ?? "[ERROR]")."
        }
    }
    
    // Conformance to Equatable
    static func == (lhs: RecurringTransaction, rhs: RecurringTransaction) -> Bool {
        return lhs.id == rhs.id
    }
}


struct RecurringTransactionTile: View {
   @Environment(\.modelContext) private var modelContext
   @State var recurringTransaction: RecurringTransaction
    @Binding var selectedRecurringTransactions: [RecurringTransaction]
    @Query var selectedRecurringTransactionIDs: [SelectedRecurringTransactionIDs]
    
   var body: some View {
   HStack {
       Text(recurringTransaction.name)
       .padding()
       Spacer()
       Text(recurringTransaction.beginDate.description)
       .padding()
       Spacer()
       
       Text(recurringTransaction.intervalType.rawValue)
       .padding()
       
       Spacer()
       Text(recurringTransaction.interval.description)
       .padding()
       Spacer()
       
       Button(action: {
           if (recurringTransaction.isIn(array: selectedRecurringTransactions))
           {
               let index : Int = selectedRecurringTransactions.firstIndex(where: { $0.id == recurringTransaction.id })!
               for selectedRecurringTransactionID in selectedRecurringTransactionIDs {
                   if (selectedRecurringTransactionID.selectedID == recurringTransaction.id) {
                       modelContext.delete(selectedRecurringTransactionID)
                       saveModelContext(modelContext)
                   }
               }
               selectedRecurringTransactions.remove(at: index)
               
           } else {
               selectedRecurringTransactions.append(recurringTransaction)
               modelContext.insert(SelectedRecurringTransactionIDs(selectedID: recurringTransaction.id))
               saveModelContext(modelContext)
           }
       })
       {
           Text(recurringTransaction.isIn(array: selectedRecurringTransactions) ? "Remove" : "Activate")
               .padding(8)
               .padding(.horizontal, 8)
               .frame(width: 100, height: 40)
               .background
                {
                   if (recurringTransaction.isIn(array: selectedRecurringTransactions))
                    {
                       RoundedRectangle(cornerRadius: 6)
                           .fill(.red.opacity(0.4))
                           .blur(radius: 4)
                           .opacity(1)
                    } else {
                       RoundedRectangle(cornerRadius: 6)
                            .fill(.ultraThickMaterial)
                            .blur(radius: 4)
                            .opacity(1)
                    }
                }
       }
       .buttonStyle(ScaleButtonStyle())
       .foregroundStyle(recurringTransaction.isIn(array: selectedRecurringTransactions) ? Color.red : Color.accentColor)
       .padding()
   }
   .frame(minWidth: 0, maxWidth: 600, maxHeight: 80)
   .cornerRadius(20)
   }
}


#Preview {
    RecurringTransactionTile(recurringTransaction: RecurringTransaction(), selectedRecurringTransactions: .constant([])).modelContainer(for: RecurringTransaction.self, inMemory: true)
}
