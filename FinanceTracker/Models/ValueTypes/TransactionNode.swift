//
//  TransactionNode.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/12/25.
//

/// A node containing a `Transaction` record.
class TransactionNode {
    private(set) var value: Transaction
    private(set) var left: TransactionNode?
    private(set) var right: TransactionNode?
    
    init(value: Transaction)
    { self.value = value }
    
    init(value: Transaction, left: TransactionNode?, right: TransactionNode?)
    {
        self.value = value
        self.left = left
        self.right = right
    }
    
    public func setValue(transaction: Transaction)
    { self.value = transaction }
    public func setLeft(node: TransactionNode)
    { self.left = node }
    public func setRight(node: TransactionNode)
    { self.right = node }
    
    public func inOrder() -> [Transaction]
    {
        var transactions: [Transaction] = []
        
        // Left
        if let left = left
        { transactions.append(contentsOf: left.inOrder()) }
        // Node
        transactions.append(value)
        // Right
        if let right = right
        { transactions.append(contentsOf: right.inOrder()) }
        
        return transactions
    }
}
