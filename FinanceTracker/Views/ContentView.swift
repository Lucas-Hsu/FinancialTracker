//
//  ContentView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 1/13/25.
//

import SwiftUI
import SwiftData

/// This is the UI/window manager
struct ContentView: View
{
    // MARK: - Tab View Enums
    private enum ViewTabs: CaseIterable
    {
      case savedPatterns,
           transactionRecords,
           graphicalRepresentation
    }
    
    // MARK: - Attributes
    @Environment(\.modelContext) private var modelContext
    @State private var transactionBST: TransactionBST?
    @State private var refreshFlag = false // Add this
    
    // MARK: - UI
    var body: some View
    {
        TabView
        {
            // MARK: Saved Patterns (Recurring Transactions)
            NavigationStack
            {
                HStack
                {
                    Text("Suggestions")
                }
            }
            .tabItem { Label("Suggestions", systemImage: "person.text.rectangle") }
            .tag(ViewTabs.savedPatterns)
            
            // MARK: Transaction Records: Calendar and List
            NavigationStack
            {
                HStack
                {
                    Text("Calendar")
                    .padding()
                    if let bst = transactionBST
                    {
                        RecordsListView(modelContext: modelContext, transactionBST: bst)
                            .padding()
                    }
                    else
                    {
                        ProgressView("Loading transactions...")
                        .onAppear
                        {
                            transactionBST = TransactionBST(modelContext: modelContext)
                        }
                    }
                }
            }
            .tabItem { Label("Records", systemImage: "list.dash") }
            .tag(ViewTabs.transactionRecords)
            
            // MARK: Charts and Summaries
            NavigationStack
            {
                HStack
                {
                    Text("Statistics")
                }
            }
            .tabItem { Label("Statistics", systemImage: "chart.bar.fill") }
            .tag(ViewTabs.graphicalRepresentation)
        }
        .onReceive(NotificationCenter.default.publisher(for: .transactionBSTUpdated)) { _ in
                    // When BST updates, toggle the refresh flag
                    refreshFlag.toggle()
                }
    }
}

#Preview
{ ContentView().modelContainer(for: [Transaction.self], inMemory: true) }

