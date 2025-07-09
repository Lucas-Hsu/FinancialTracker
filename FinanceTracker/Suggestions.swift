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
    @Query var selectedRecurringTransactionIDs: [SelectedRecurringTransactionIDs]
    @Binding var selectedRecurringTransactions: [RecurringTransaction]
    @State var refreshScale : CGFloat = 1.0
    @State var isRefreshing: Bool = false
    
    // Update `categoree` when `transactions` changes
    var body: some View
    {
        
        VStack
        {
            Button("Refresh")
            {
                if (!isRefreshing)
                {
                    refresh()
                    isRefreshing = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0)
                    { isRefreshing = false }
                }
                refreshScale = 1.2
                withAnimation(.easeInOut(duration: 2))
                { refreshScale = 1.0 }
            }
                .scaleEffect(refreshScale)
                
            
            VStack
            {
                ForEach(recurringTransactions, id: \.self)
                { recurringTransaction in
                    RecurringTransactionTile(recurringTransaction: recurringTransaction, selectedRecurringTransactions: $selectedRecurringTransactions)
                }
            }
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    public func refresh()
    {
        clearRecurringTransactions()
        let categories = categorizeTransactions()
        let patterns = determinePatterns(from: categories)
        let newRecurringTransactions = createRecurringTransactions(from: patterns)
        addRecurringTransactions(recurringTransactions: newRecurringTransactions)
    }
    
    private func categorizeTransactions() -> [TransactionSignature:[Transaction]]
    {
        let recognitionLowerBound : Int = 3 // Minimum amount of Transactions with a certain Signature to be recognized as recurring
        var groupedTransactions: [TransactionSignature: [Transaction]] = [:]
        groupedTransactions.reserveCapacity(self.transactions.count) // Prevent constant resizing of dictionary
        for transaction in self.transactions
        { groupedTransactions[transaction.signature, default: []].append(transaction) }
        let recurringGroupedTransactions = groupedTransactions.filter { $0.value.count >= recognitionLowerBound } // Lower limit to how much
        return recurringGroupedTransactions
    }
    
    private func determinePatterns(from groupedTransactions: [TransactionSignature:[Transaction]]) -> [TransactionPattern: Transaction]
    {
        var patterns: [TransactionPattern: Transaction] = [:]
        for group in groupedTransactions.keys
        {
            let pattern = determinePattern(from: groupedTransactions[group]!)
            if (pattern.getTypeInternal() == .None) { continue }
            patterns[pattern] = groupedTransactions[group]?.first!
        }
        return patterns
    }
    
    /// returns exactly one patternGroup
    private func determinePattern(from transactions: [Transaction]) -> TransactionPattern
    {
        // Ignore repeated transactions
        let sortedTransactions = transactions.sorted { $0.date < $1.date }
            .reduce(into: [Transaction]())
            { result, transaction in
                if !result.contains(where: { $0.sameDayAs(transaction) })
                { result.append(transaction) }
            }
        guard sortedTransactions.count > 1 else
        { return TransactionPattern(type: .None) }
        let pattern = RelationshipBetween(date1: sortedTransactions[0].date,
                                          date2: sortedTransactions[1].date)
        if pattern.getTypeInternal() == .None
        { return TransactionPattern(type: .None) }
        for i in 2..<sortedTransactions.count
        {
            let otherPattern = RelationshipBetween(date1: sortedTransactions[0].date,
                                                  date2: sortedTransactions[i].date)
            if otherPattern.getType() != pattern.getType()
            { return TransactionPattern(type: .None) }
            if !patternOccursOn(date: sortedTransactions[i].date, pattern: pattern)
            { return TransactionPattern(type: .None) }
        }
        return pattern
    }
    
    private func patternOccursOn(date: Date, pattern: TransactionPattern) -> Bool
    {
        let beginDate = pattern.getBeginDate()
        if Calendar.current.startOfDay(for: pattern.getBeginDate()) > Calendar.current.startOfDay(for: date)
        { return false }
        switch (pattern.getType())
        {
        case .Yearly:
            var i : Int = 0
            var dateRunner : Date = beginDate
            while dateRunner <= date.addingTimeInterval(365*24*3600)
            {
                if dateRunner.sameDayAs(date)
                {
                    return i % pattern.getInterval() == 0
                }
                i += 1
                dateRunner = Calendar.current.date(byAdding: .year, value: i, to: beginDate)!
            }
        case .Monthly:
            var i : Int = 0
            var dateRunner : Date = beginDate
            while dateRunner <= date.addingTimeInterval(30*24*3600)
            {
                if dateRunner.sameDayAs(date)
                {
                    return i % pattern.getInterval() == 0
                }
                i += 1
                dateRunner = Calendar.current.date(byAdding: .month, value: i, to: beginDate)!
            }
        case .Weekly:
            let interval : Int = beginDate.amountOfDays(from: date)
            return interval % 7 == 0
                    && interval/7 % pattern.getInterval() == 0
        case .Custom:
            let interval : Int = beginDate.amountOfDays(from: date)
            return interval % pattern.getInterval() == 0
        }
        return false
    }
    
    private func createRecurringTransactions(from patternGroups: [TransactionPattern: Transaction]) -> [RecurringTransaction]
    {
        var recurringTransactions : [RecurringTransaction] = []
        for patternGroup in patternGroups
        {
            let pattern : TransactionPattern = patternGroup.key
            let transactionSample : Transaction = patternGroup.value
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
    
    private func clearRecurringTransactions()
    {
        if self.recurringTransactions.count == 0 { return }
        
        for recurringTransaction in recurringTransactions
        { modelContext.delete(recurringTransaction) }
        saveModelContext(modelContext)
        
        for selectedRecurringTransactionId in selectedRecurringTransactionIDs {
            modelContext.delete(selectedRecurringTransactionId)
            saveModelContext(modelContext)
        }
        
        selectedRecurringTransactions = []
    }
    
    private func addRecurringTransactions(recurringTransactions: [RecurringTransaction])
    {
        if self.recurringTransactions.count > 0 { return }
        
        for recurringTransaction in recurringTransactions
        {
            if self.recurringTransactions.map({$0.id}).contains(recurringTransaction.id) == false
            { modelContext.insert(recurringTransaction) }
            saveModelContext(modelContext)
        } 
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
            if dateRunner.sameDayAs(dates[1])
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
            if dateRunner.sameDayAs(dates[1])
            { return TransactionPattern(beginDate: dates[0], type: .Monthly, interval: i) }
            i = i + 1
            dateRunner = Calendar.current.date(byAdding: DateComponents(month: i), to: dates[0])!
        }
    }
    
    if components1.day != components2.day {
        let interval : Int = dates[0].amountOfDays(from: dates[1])
        if interval % 7 == 0
        { return TransactionPattern(beginDate: dates[0], type: .Weekly, interval: interval/7) }
        else
        { return TransactionPattern(beginDate: dates[0], type: .Custom, interval: interval) }
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

#Preview {
    Suggestions(selectedRecurringTransactions: .constant([]))
        .modelContainer(for: RecurringTransaction.self, inMemory: true)
}
