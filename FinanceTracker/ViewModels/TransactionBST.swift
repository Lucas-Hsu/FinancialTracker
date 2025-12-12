//
//  TransactionBST.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/12/25.
//

import Foundation
import SwiftData

/// Builds and traverses a Binary Search Tree with `TransactionNode`s.
@Observable
final class TransactionBST
{
    // MARK: - Options enums
    private enum NodeCompareDecision: CaseIterable
    {
        case leftSubtree,
             rightSubtree
    }
    private enum BSTSortMethod: CaseIterable
    {
        case date
    }
    
    // MARK: - Read-only Attributes: the View can access and be notified of change in.
    private(set) var root: TransactionNode?
    @ObservationIgnored private var notificationToken: Any?
    
    // MARK: - Fully Private: No need to be observed by View.
    @ObservationIgnored let modelContext: ModelContext
    @ObservationIgnored var transactions: [Transaction]
    
    // MARK: - Constructors
    init(modelContext: ModelContext)
    {
        self.modelContext = modelContext
        self.root = nil
        self.transactions = []
        readTransactions()
    }
    
    // MARK: - Destructors
    deinit
    {
        if let token = notificationToken
        {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    // MARK: - Public Methods
    public func inOrderTravesal() -> [Transaction]
    {
        guard let rootNode = self.root else
        { return [] }
        return rootNode.inOrder()
    }
    
    // MARK: - Helpers Methods
    // Set up Context Observer to see when modelContext changes
    private func setupContextObserver()
    {
        notificationToken = NotificationCenter.default.addObserver(forName: .NSManagedObjectContextObjectsDidChange,
                                                                   object: modelContext,
                                                                   queue: .main)
        { [weak self] notification in
            print("Notification 'modelContext: .NSManagedObjectContextObjectsDidChange' Received.")
            self?.refresh()
        }
    }
    // Refresh Sorted Transaction Array
    private func refresh()
    {
        print("Refreshing TransactionBST...")
        self.readTransactions()
        self.buildTree()
        print("Refreshing TransactionBST Complete!")
    }
    // Read Transactions from the ModelContext
    private func readTransactions()
    {
        do
        {
            let descriptor = FetchDescriptor<Transaction>( sortBy: [SortDescriptor(\.id)] )
            self.transactions = try modelContext.fetch(descriptor)
        }
        catch
        { fatalError("[ERROR] Failed to load transactions: \(error)") }
    }
    
    // Build a BST from the unsorted Transaction array
    private func buildTree(choice: BSTSortMethod = .date)
    {
        if (transactions.count == 0)
        { self.root = nil }
        else
        {
            self.root = TransactionNode(value: transactions[0])
            guard let rootNode: TransactionNode = self.root else
            { return }
            for i in 1..<transactions.count
            {
                recursiveAdd(node: TransactionNode(value: transactions[i]),to: rootNode, compareType: choice)
            }
        }
    }
    
    // Recursively add a new node to a node's subtrees
    private func recursiveAdd(node newNode: TransactionNode, to targetNode: TransactionNode, compareType: BSTSortMethod)
    {
        var decision: NodeCompareDecision
        switch (compareType)
        {
        case .date:
            decision = compareNodesDate(newNode: newNode, targetNode: targetNode)
        }
        if decision == .leftSubtree
        {
            if let childNode: TransactionNode = targetNode.left
            { recursiveAdd(node: newNode, to: childNode, compareType: compareType) }
            else
            { targetNode.setLeft(node: newNode) }
        }
        else // Right Subtree
        {
            if let childNode: TransactionNode = targetNode.right
            { recursiveAdd(node: newNode, to: childNode, compareType: compareType) }
            else
            { targetNode.setRight(node: newNode) }
        }
    }
    
    // Nodes with more recent dates added to the left subtree
    private func compareNodesDate(newNode: TransactionNode, targetNode: TransactionNode) -> NodeCompareDecision
    {
        if (targetNode.value.date > newNode.value.date)
        { return NodeCompareDecision.leftSubtree }
        return NodeCompareDecision.rightSubtree
    }
}
