//
//  RecurringTransaction.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 2/25/25.
//

import SwiftUI
import SwiftData
import Foundation

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
    var transactions: [Transaction]
    
    init(beginDate: Date = Date(),
         intervalType: TypesOfRecurringTransaction = TypesOfRecurringTransaction.Yearly,
         interval : Int = 1,
         name: String = "Recurring Transaction",
         tag: Tag = Tag.other,
         price: Double = 1999,
         notes: [String]? = nil,
         transactions: [Transaction] = [Transaction(),Transaction(),Transaction()])
    {
        self.id = UUID()
        self.beginDate = beginDate
        self.intervalType = intervalType
        self.interval = interval
        self.name = name
        self.tag = tag
        self.price = price
        self.notes = notes
        self.transactions = transactions
    }
    
    init(patternType : TransactionPattern = TransactionPattern(beginDate: Date(),
                                                               type: .Yearly,
                                                               interval: 1),
         name: String = "Recurring Transaction",
         tag: Tag = Tag.other,
         price: Double = 1999,
         notes: [String]? = nil,
         transactions: [Transaction] = [Transaction(),Transaction(),Transaction()])
    {
        self.id = UUID()
        self.beginDate = patternType.getBeginDate()
        self.intervalType = patternType.getType()
        self.interval = patternType.getInterval()
        self.name = name
        self.tag = tag
        self.price = price
        self.notes = notes
        self.transactions = transactions
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
        return RelationshipBetween(date1: self.beginDate, date2: date) == getTransactionPattern()
    }
    
    public func reccursOn(date: Date) -> Bool
    {
        return RelationshipBetween(date1: self.beginDate, date2: date) == getTransactionPattern() && date != self.beginDate
    }
    
    public func transactionOn(date: Date) -> Transaction?
    {
        for transaction in self.transactions
        {
            if Calendar.current.startOfDay(for: transaction.date) == Calendar.current.startOfDay(for: date)
            { return transaction }
        }
        return nil
    }
    
    
    public func eventDescription() -> String
    {
        return "EVENT"
    }
    
    // Conformance to Equatable
    static func == (lhs: RecurringTransaction, rhs: RecurringTransaction) -> Bool {
        return lhs.beginDate == rhs.beginDate && lhs.name == rhs.name && lhs.price == rhs.price && lhs.tag == rhs.tag && lhs.interval == rhs.interval && lhs.intervalType == rhs.intervalType
    }
}


struct RecurringTransactionTile: View {
   @Environment(\.modelContext) private var modelContext
   @Query var recurringTransactions: [RecurringTransaction]
   
   @State var transactions: [Transaction] = []
   @State var date: Date = Date()
   @State var name: String = "Recurring Transaction"
   @State var type: String = "Custom"
   @State var interval: Int = 0
   @State var tag: String = "Other"
   @State var price: Double = 0.00

   let patterns: [(type: String, interval: Int)] = [
   ("Daily", 1),
   ("Weekly", 7),
   ("Monthly", 30),
   ("Yearly", 365)
   ]
   var body: some View {
   HStack {
       Text(transactions.first?.name ?? "Recurring Transaction")
       .padding()
       Spacer()
       Text(transactions.first?.date.formatted(.dateTime.year().month(.abbreviated).day(.twoDigits)) ?? "0000/MMM./00")
       .padding()
       Spacer()
       
       Text("\(getPattern().getType())")
       .padding()
       
       Spacer()
       Text("\(getPattern().getInterval())")
       .padding()
       Spacer()
       
       Button(action: {
           if (isInContext(recurringTransaction: constructRecurringTransaction())) {
               deleteRecurringTransaction()
           } else {
               addRecurringTransaction()
           }
       }) {
           Text(isInContext(recurringTransaction: constructRecurringTransaction()) ? "Delete" : "Add").padding(8)
               .padding(.horizontal, 8)
               .frame(width: 100, height: 40)
               .background{
                   if (isInContext(recurringTransaction: constructRecurringTransaction())) {
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
       .foregroundStyle(isInContext(recurringTransaction: constructRecurringTransaction()) ? Color.red : Color.accentColor)
       .padding()
       
   }
   .frame(minWidth: 0, maxWidth: 600, maxHeight: 80)
   .cornerRadius(20)
   }

   private func addRecurringTransaction() {
       print("Adding Recurring Transaction")
   let newTransaction = RecurringTransaction(beginDate: transactions.first?.date ?? Date(),
                                             intervalType: getPattern().getType(),
                                             interval: getPattern().getInterval(),
                                             name: transactions.first?.name ?? "Recurring Transaction",
                                             tag: transactions.first?.tag ?? .other,
                                             price: transactions.first?.price ?? 0.00
   )
   modelContext.insert(newTransaction)
   }
   
   private func deleteRecurringTransaction() {
       let newRecurringTransaction = constructRecurringTransaction()
       print("Deleting Recurring Transaction")
       if let existingTransaction = self.recurringTransactions.first(where: { $0 == newRecurringTransaction }) {
           modelContext.delete(existingTransaction)
           print("Deleted existing transaction")
       }
   }
   
   private func constructRecurringTransaction() -> RecurringTransaction
   {
       return RecurringTransaction(beginDate: transactions.first?.date ?? Date(),
                                   intervalType: getPattern().getType(),
                                   interval: getPattern().getInterval(),
                                   name: transactions.first?.name ?? "Recurring Transaction",
                                   tag: transactions.first?.tag ?? .other,
                                   price: transactions.first?.price ?? 0.00
                                   )
   }
   
   private func isInContext(recurringTransaction: RecurringTransaction) -> Bool
   {
       if (recurringTransactions.contains(recurringTransaction))
       { return true }
       return false
   }
   
   private func getPattern() -> TransactionPattern
   {
       var transactions : [Transaction] = transactions.sorted { $0.date < $1.date }
       // Ignore repeated transactions
       transactions = transactions.reduce(into: [Transaction]())
       { result, transaction in
           if !result.contains(where: { $0.sameDayAs(transaction) })
           { result.append(transaction) }
       }
       return RelationshipBetween(date1: transactions[0].date, date2: transactions[1].date)
   }
}


#Preview {
    Suggestions().modelContainer(for: RecurringTransaction.self, inMemory: true)
}
