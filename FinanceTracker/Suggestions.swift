//
//  Suggestions.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 2/24/25.
//

import SwiftUI
import SwiftData
struct Suggestions: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.name, order: .forward) var transactions: [Transaction]
    @Query(sort: \RecurringTransaction.name, order: .forward) var recurringTransactions: [RecurringTransaction]
    @State var categoree: [String:[Transaction]] = [:]
    
    // Update `categoree` when `transactions` changes
    var body: some View
    {
        
        VStack
        {

            VStack
            {
                
            }
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    public func refresh()
    {
        for recurringTransaction in recurringTransactions
        { modelContext.delete(recurringTransaction) }
        saveModelContext(modelContext)
    }
    
    private func categorize() -> [TransactionSignature:[Transaction]]
    {
        let recognitionLowerBound : Int = 3 // Minimum amount of Transactions with a certain Signature to be recognized as recurring
        var groupedTransactions: [TransactionSignature: [Transaction]] = [:]
        groupedTransactions.reserveCapacity(self.transactions.count) // Prevent constant resizing of dictionary
        for transaction in self.transactions
        { groupedTransactions[transaction.signature, default: []].append(transaction) }
        let recurringGroupedTransactions = groupedTransactions.filter { $0.value.count >= recognitionLowerBound } // Lower limit to how much
        return recurringGroupedTransactions
    }
    
    /// returns only one patternGroup
    private func determinePattern(from transactions: [Transaction]) -> [TransactionPattern: [Transaction]]
    {
        let sortedTransactions = transactions.sorted { $0.date < $1.date }
        guard sortedTransactions.count > 1 else
        { return [TransactionPattern(type: .None):[]] }
        let pattern = RelationshipBetween(date1: sortedTransactions[0].date,
                                          date2: sortedTransactions[1].date)
        for i in 1..<(sortedTransactions.count - 1)
        {
            let otherPattern = RelationshipBetween(date1: sortedTransactions[i].date,
                                                  date2: sortedTransactions[i + 1].date)
            if otherPattern != pattern
            { return [TransactionPattern(type: .None):[]] }
        }
        return [pattern:transactions]
    }
    
    private func createRecurringTransactions(from patternGroups: [TransactionPattern: [Transaction]]) -> [RecurringTransaction]
    {
        var recurringTransactions : [RecurringTransaction] = []
        for patternGroup in patternGroups
        {
            let pattern : TransactionPattern = patternGroup.key
            let transactionSample : Transaction = patternGroup.value.first!
            if pattern.getTypeInternal() == .None
            { continue }
            let recurringTransaction : RecurringTransaction = RecurringTransaction(beginDate: pattern.getBeginDate(),
                                                                                   intervalType: pattern.getType(),
                                                                                   interval: pattern.getInterval(),
                                                                                   name: transactionSample.name,
                                                                                   tag: transactionSample.tag,
                                                                                   price: transactionSample.price,
                                                                                   notes: transactionSample.notes)
            recurringTransactions.append(recurringTransaction)
        }
        return recurringTransactions
    }

}

func RelationshipBetween(date1: Date, date2: Date) -> TransactionPattern
{
    let dates : [Date] = [date1, date2].sorted { $0 < $1 }
    let components1 = Calendar.current.dateComponents([.year, .month, .day], from: dates[0])
    let components2 = Calendar.current.dateComponents([.year, .month, .day], from: dates[1])
    
    if components1.year != components2.year {
        var i : Int = 1
        var dateRunner : Date = Calendar.current.date(byAdding: DateComponents(year: 1), to: dates[0])!
        while dateRunner <= dates[1].addingTimeInterval(365*24*60*60) // + 1 year to make sure not accidentally neglect dates
        {
            if dateRunner == dates[1]
            { return TransactionPattern(beginDate: dates[0], type: .Yearly, interval: i) }
            i = i + 1
            dateRunner = Calendar.current.date(byAdding: DateComponents(year: i), to: dates[0])!
        }
    }

    if components1.month != components2.month {
        var i : Int = 1
        var dateRunner : Date = Calendar.current.date(byAdding: DateComponents(month: i), to: dates[0])!
        while dateRunner <= dates[1].addingTimeInterval(31*24*60*60) // + 1 month to make sure not accidentally neglect dates
        {
            if dateRunner == dates[1]
            { return TransactionPattern(beginDate: dates[0], type: .Monthly, interval: i) }
            i = i + 1
            dateRunner = Calendar.current.date(byAdding: DateComponents(month: i), to: dates[0])!
        }
    }
    
    if components1.day != components2.day {
        var i : Int = 1
        var dateRunner : Date = Calendar.current.date(byAdding: DateComponents(day: i), to: dates[0])!
        while dateRunner <= dates[1].addingTimeInterval(24*60*60) // + 1 day to make sure not accidentally neglect dates
        {
            if dateRunner == dates[1]
            {
                if i % 7 == 0
                { return TransactionPattern(beginDate: dates[0], type: .Weekly, interval: i/7) }
                else
                { return TransactionPattern(beginDate: dates[0], type: .Custom, interval: i) }
            }
            i = i + 1
            dateRunner = Calendar.current.date(byAdding: DateComponents(month: i), to: dates[0])!
        }
    }
    
    return TransactionPattern(type: .None)
}

enum TypesOfRecurringTransaction: String, CaseIterable, Codable
{
    case Yearly, Monthly, Weekly, Custom
    
    public func toInternal() -> TypesOfRecurringTransactionsInternal
    {
        switch self
        {
        case .Yearly:
            return .Yearly
        case .Monthly:
            return .Monthly
        case .Weekly:
            return .Weekly
        case .Custom:
            return .Custom
        }
    }
}
enum TypesOfRecurringTransactionsInternal: String, CaseIterable, Codable // To differentiate between groups of transactions that have and don't have patterns
{
    case Yearly, Monthly, Weekly, Custom, None
}

/// Checks if the current set of transactions have the same recurring pattern
private func findPattern(transactions: [Transaction]) -> TransactionPattern
{
    var transactions : [Transaction] = transactions.sorted { $0.date < $1.date }
    // Ignore repeated transactions
    transactions = transactions.reduce(into: [Transaction]())
    { result, transaction in
        if !result.contains(where: { $0.sameDayAs(transaction) })
        { result.append(transaction) }
    }
    var patterns : [TransactionPattern] = []
    for i in 0...(transactions.count-2)
    {
        let pattern: TransactionPattern = RelationshipBetween(date1: transactions[i].date, date2: transactions[i+1].date)
        patterns.append(pattern)
    }
    for pattern in patterns
    {
        if !pattern.hasSameTypeAndInterval(with: patterns.first!)
        { return TransactionPattern(beginDate: Date(), type: .None, interval: 0) }
    }
    return patterns.first!
}

#Preview {
    Suggestions().modelContainer(for: RecurringTransaction.self, inMemory: true)
}
