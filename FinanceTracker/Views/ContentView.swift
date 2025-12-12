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
                    RecordsListView(modelContext: modelContext)
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
                    RecordsListView(modelContext: modelContext)
                    .padding()
                }
            }
            .tabItem { Label("Records", systemImage: "list.dash") }
            .tag(ViewTabs.transactionRecords)
            
            // MARK: Charts and Summaries
            NavigationStack
            {
                HStack
                {
                    RecordsListView(modelContext: modelContext)
                }
            }
            .tabItem { Label("Statistics", systemImage: "chart.bar.fill") }
            .tag(ViewTabs.graphicalRepresentation)
        }
    }
}

#Preview
{ ContentView().modelContainer(for: [Transaction.self], inMemory: true) }

