//
//  TransactionPattern.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 7/6/25.
//

import Foundation

struct TransactionPattern: Hashable
{
    private var beginDate: Date
    private var type: TypesOfRecurringTransactionsInternal
    private var interval: Int

    init(beginDate: Date = Date(),
         type: TypesOfRecurringTransactionsInternal,
         interval: Int = 0)
    {
        self.beginDate = beginDate
        self.type = type
        self.interval = interval
    }

    public func isValidInterval(_ interval: Int) -> Bool
    {
        switch self.type
        {
        case .Yearly:
            return interval >= 1 // Might want to set a upper limit to prevent ridiculously large intervals
        case .Monthly:
            return interval >= 1 && interval <= 12
        case .Weekly:
            return interval >= 1
        case .Custom:
            return interval >= 1
        case .None:
            return false
        }
    }

    public func getBeginDate() -> Date
    { return self.beginDate }
    
    public func getType() -> TypesOfRecurringTransaction
    {
        if self.type == .None
        {
            print("[ERROR]: None is not a valid recurring transaction type")
            return .Custom
        }
        return TypesOfRecurringTransaction(rawValue: self.type.rawValue)!
    }

    public func getTypeInternal() -> TypesOfRecurringTransactionsInternal
    { return self.type }

    public func getInterval() -> Int
    { return self.interval }

    public func toString() -> String
    { return "\(self.type.rawValue):\(self.interval)" }
    
    public func hasPattern() -> Bool
    { return self.type != .None && (self.type == .Custom && isValidInterval(self.interval) || self.type != .Custom) }

    public func hasSameTypeAndInterval(with other: TransactionPattern) -> Bool
    { return self.type == other.type && self.interval == other.interval }
}
