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
final class TransactionBST {
    // MARK: - Options enums
    private enum NodeCompareDecision
    { case leftSubtree, rightSubtree }
    private enum BSTSortMethod: CaseIterable
    { case dateDescending }
    
    // MARK: - Read-only Attributes
    private(set) var root: TransactionNode?
    private(set) var isReady: Bool = false
    
    // MARK: - Fully Private
    @ObservationIgnored let modelContext: ModelContext
    @ObservationIgnored private var transactions: [Transaction]
    @ObservationIgnored private var notificationToken: Any?
    
    // MARK: - Constructors
    init(modelContext: ModelContext)
    {
        print("\t///TransactionBST Init")
        self.modelContext = modelContext
        self.root = nil
        self.transactions = []
        // asynchronously load to avoid slowing UI down
        Task
        { @MainActor in
            await self.loadInitialData()
        }
        setupContextObserver()
        print("\tTransactionBST Init///")
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
    public func inOrderTraversal() -> [Transaction]
    {
        guard let rootNode = self.root else { return [] }
        return rootNode.inOrder()
    }
    
    public func refresh()
    {
        readTransactions()
        buildTree()
        NotificationCenter.default.post(
            name: .transactionBSTUpdated,
            object: self,
            userInfo: ["initialLoad": false]
        )
    }
    
    // MARK: - Context Observation
    private func setupContextObserver()
    {
        // Observe .transactionsUpdated notification (which usually should be sent by self)
        NotificationCenter.default.addObserver(forName: .transactionsUpdated,
                                               object: nil,
                                               queue: .main)
        { [weak self] notification in
            print("TransactionBST Received BST update notification")
            self?.refresh()
        }
    }
    
    // MARK: - Helper Methods
    @MainActor
    private func loadInitialData() async
    {
        readTransactions()
        buildTree()
        isReady = true
        NotificationCenter.default.post(name: .transactionBSTUpdated,
                                        object: self,
                                        userInfo: ["initialLoad": true])
        print("BST: Initial load complete with \(transactions.count) transactions")
    }
    
    private func readTransactions()
    {
        do
        {
            let descriptor = FetchDescriptor<Transaction>()
            self.transactions = try modelContext.fetch(descriptor)
            print("TransactionBST Loaded \(transactions.count) transactions")
        }
        catch
        {
            self.root = nil
            self.transactions = []
            print("[ERROR] TransactionBST Failed to load transactions: \(error)")
        }
    }
    // Build a BST from the unsorted Transaction array
    private func buildTree(choice: BSTSortMethod = .dateDescending)
    {
        if transactions.isEmpty
        {
            self.root = nil
            return
        }
        self.root = TransactionNode(value: transactions[0])
        guard let rootNode: TransactionNode = self.root else
        { return }
        for i in 1..<transactions.count
        { recursiveAdd(node: TransactionNode(value: transactions[i]),to: rootNode, compareType: choice) }
        print("BST: Tree rebuilt with \(transactions.count) nodes")
    }
    // Recursively add a new node to a node's subtrees
    private func recursiveAdd(node newNode: TransactionNode, to targetNode: TransactionNode, compareType: BSTSortMethod)
    {
        var decision: NodeCompareDecision
        switch (compareType)
        {
        case .dateDescending:
            decision = compareNodesDateDescending(newNode: newNode, targetNode: targetNode)
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
    private func compareNodesDateDescending(newNode: TransactionNode, targetNode: TransactionNode) -> NodeCompareDecision
    {
        if (newNode.value.date > targetNode.value.date)
        { return NodeCompareDecision.leftSubtree }
        return NodeCompareDecision.rightSubtree
    }
}
