//
//  ContentView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 1/13/25.
//

import SwiftUI
import SwiftData

struct ContentView: View
{
    @State private var selectedTab: ViewTabs = .transactionRecords
    
    var body: some View
    {
        TabView (selection: $selectedTab)
        {
            // MARK: - Saved Patterns (Recurring Transactions)
            NavigationStack
            {
                HStack
                {
                    RecordsListView()
                }
            }
                .tabItem { Label("Suggestions", systemImage: "person.text.rectangle") }
                .tag(ViewTabs.savedPatterns)
                .edgesIgnoringSafeArea(.all)
            
            // MARK: - Transaction Records: Calendar and List
            NavigationStack
            {
                HStack
                {
                    Text("Calendar")
                        .padding()
                    RecordsListView()
                        .padding()
                }
            }
                .tabItem { Label("Records", systemImage: "list.dash") }
                .tag(ViewTabs.transactionRecords)
                .edgesIgnoringSafeArea(.all)
            
            // MARK: - Charts and Summaries
            NavigationStack
            {
                HStack
                {
                    RecordsListView()
                }
            }
                .tabItem { Label("Statistics", systemImage: "chart.bar.fill") }
                .tag(ViewTabs.graphicalRepresentation)
        }
    }
}

#Preview
{
    ContentView()
}
