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
    private enum NodeCompareDecision: CaseIterable {
        case leftSubtree, rightSubtree
    }
    
    private enum BSTSortMethod: CaseIterable
    {
        case date
    }
    
    // MARK: - Read-only Attributes
    private(set) var root: TransactionNode?
    private(set) var isReady: Bool = false
    
    // MARK: - Fully Private
    @ObservationIgnored let modelContext: ModelContext
    @ObservationIgnored private var transactions: [Transaction]
    @ObservationIgnored private var notificationToken: Any?
    
    // MARK: - Constructors
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.root = nil
        self.transactions = []
        // asynchronously load to avoid slowing UI
        Task { @MainActor in
            await self.loadInitialData()
        }
        setupContextObserver()
    }
    
    deinit {
        if let token = notificationToken {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    // MARK: - Public Methods
    public func inOrderTraversal() -> [Transaction] {
        guard let rootNode = self.root else { return [] }
        return rootNode.inOrder()
    }
    
    public func refresh() {
        readTransactions()
        buildTree()
        // Notify everyone that BST has been updated
        NotificationCenter.default.post(
                    name: .transactionBSTUpdated,
                    object: self,
                    userInfo: ["initialLoad": false]  // NEW: different from initial load
                )
    }
    
    /*
    public func findTransaction(id: PersistentIdentifier?) -> Transaction? {
        guard let id = id else { return nil }
        return findTransactionRecursive(root: root, id: id)
    }
    */
    
    private func findTransactionRecursive(root: TransactionNode?, id: PersistentIdentifier) -> Transaction? {
        guard let root = root else { return nil }
        
        if root.value.id == id {
            return root.value
        }
        
        if let foundInLeft = findTransactionRecursive(root: root.left, id: id) {
            return foundInLeft
        }
        
        if let foundInRight = findTransactionRecursive(root: root.right, id: id) {
            return foundInRight
        }
        
        return nil
    }
    
    // MARK: - Context Observation
    private func setupContextObserver() {
        // Observe SwiftData context saves
        notificationToken = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: modelContext,
            queue: .main
        ) { [weak self] _ in
            print("SwiftData context changed - refreshing BST")
            self?.refresh()
        }
        
        // Also observe our custom notification for immediate updates
        NotificationCenter.default.addObserver(
            forName: .transactionBSTUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if notification.object as? TransactionBST !== self {
                print("Received BST update notification from another source")
                self?.refresh()
            }
        }
    }
    
    // MARK: - Helper Methods
    @MainActor
        private func loadInitialData() async {
            readTransactions()
            buildTree()
            isReady = true  // MARK: Set ready flag after async load completes
            NotificationCenter.default.post(
                name: .transactionBSTUpdated,
                object: self,
                userInfo: ["initialLoad": true]  // NEW: Flag for initial load
            )
            print("BST: Initial load complete with \(transactions.count) transactions")
        }
    
    private func readTransactions() {
        do {
            let descriptor = FetchDescriptor<Transaction>()
            self.transactions = try modelContext.fetch(descriptor)
            print("BST: Loaded \(transactions.count) transactions")
        } catch {
            print("[ERROR] Failed to load transactions: \(error)")
            self.transactions = []
            self.root = nil
        }
    }
    
    // Build a BST from the unsorted Transaction array
    private func buildTree(choice: BSTSortMethod = .date)
    {
        if transactions.isEmpty
        {
            self.root = nil
            return
        }
        
        self.root = TransactionNode(value: transactions[0])
        guard let rootNode: TransactionNode = self.root else { return }
        
        for i in 1..<transactions.count
        {
            recursiveAdd(node: TransactionNode(value: transactions[i]),to: rootNode, compareType: choice)
        }
        print("BST: Tree rebuilt with \(transactions.count) nodes")
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
