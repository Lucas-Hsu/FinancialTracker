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
    private enum ViewTabs: Hashable
    {
      case savedPatterns,
           transactionRecords,
           graphicalRepresentation
    }
    @State private var viewTabs: ViewTabs = .transactionRecords
    
    // MARK: - Attributes
    @Environment(\.modelContext) private var modelContext
    @State private var transactionBST: TransactionBST?
    @State private var refreshFlag = false // Add this
    
    // MARK: - UI
    var body: some View
    {
        TabView (selection: $viewTabs)
        {
            // MARK: Saved Patterns (Recurring Transactions)
                NavigationStack
            {
                HStack
                {
                    if let bst = transactionBST
                    {
                        RecurringTransactionListView(modelContext: modelContext, transactionBST: bst)
                        .padding()
                    }
                    else
                    {
                        ProgressView("Building TransactionBST...")
                    }
                }
            }
            .tabItem { Label("Recurring", systemImage: "calendar") }
            .tag(ViewTabs.savedPatterns)
            // MARK: Transaction Records: Calendar and List
            NavigationStack
            {
                HStack
                {
                    CalendarView(modelContext: modelContext)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: 700)
                    
                    if let bst = transactionBST
                    {
                        RecordsListView(modelContext: modelContext, transactionBST: bst)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: 700)
                    }
                    else
                    {
                        ProgressView("Building TransactionBST...")
                    }
                }
                .background(
                    ZStack
                    {
                        Image("iPad26Background")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                        Rectangle()
                        .fill(defaultPanelBackgroundColor)
                        .scaledToFit()
                        .opacity(0.7)
                    }
                )
            }
            .tabItem { Label("Records", systemImage: "line.3.horizontal") }
            .tag(ViewTabs.transactionRecords)
            // MARK: Charts and Summaries
            NavigationStack
            {
                HStack
                {
                    SummaryView()
                }
                .background(
                    ZStack
                    {
                        Image("iPad26Background")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                        Rectangle()
                        .fill(defaultPanelBackgroundColor)
                        .scaledToFit()
                        .opacity(0.7)
                    }
                )
            }
            .tabItem { Label("Stats", systemImage: "chart.line.uptrend.xyaxis") }
            .tag(ViewTabs.graphicalRepresentation)
        }
        .environment(\.horizontalSizeClass, .compact)
        .onAppear
        {
            self.transactionBST = TransactionBST(modelContext: modelContext)
        }
    }
}

#Preview
{ ContentView().modelContainer(for: [Transaction.self], inMemory: true) }
