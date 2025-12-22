//
//  ContentView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 1/13/25.
//

import SwiftUI
import SwiftData

/// Main window
struct ContentView: View
{
    // MARK: - Tab View Manager
    private enum ViewTabs: Hashable
    {
      case graphicalRepresentation,
           transactionRecords,
           settings
    }
    @State private var viewTabs: ViewTabs = .transactionRecords
    
    // MARK: - Private Attributes
    @Environment(\.modelContext) private var modelContext
    @State private var transactionBST: TransactionBST?
    @State private var refreshFlag = false // Add this
    
    // MARK: - UI
    var body: some View
    {
        TabView (selection: $viewTabs)
        {
            // MARK: Charts and Summaries
            NavigationStack
            {
                HStack
                {
                    StatisticsView()
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: 700)
                }
                .background(BackgroundImage())
            }
            .tabItem { Label("Stats", systemImage: "chart.line.uptrend.xyaxis") }
            .tag(ViewTabs.graphicalRepresentation)
            // MARK: Transaction Records: Calendar and List
            NavigationStack
            {
                HStack(spacing: 16)
                {
                    Group
                    {
                        if #available(iOS 26.0, *)
                        {
                            CalendarView(modelContext: modelContext)
                            .glassEffect(.regular, in: .rect(cornerRadius: 16))
                        }
                        else
                        { CalendarView(modelContext: modelContext) }
                    }
                    .padding(.leading)
                    .frame(maxWidth: .infinity, minHeight: 700, maxHeight: 700)
                    if let bst = transactionBST
                    {
                        Group
                        {
                            if #available(iOS 26.0, *)
                            {
                                RecordsListView(modelContext: modelContext, transactionBST: bst)
                                .glassEffect(.regular, in: .rect(cornerRadius: 16))
                            }
                            else
                            { RecordsListView(modelContext: modelContext, transactionBST: bst) }
                        }
                        .padding(.trailing)
                        .frame(maxWidth: .infinity, minHeight: 700, maxHeight: 700)
                    }
                    else
                    {
                        ProgressView("Building TransactionBST...")
                    }
                }
                .background(BackgroundImage())
            }
            .tabItem { Label("Records", systemImage: "line.3.horizontal") }
            .tag(ViewTabs.transactionRecords)
            // MARK: Settings & Backup
            // Updated Settings Tab within ContentView.swift
            NavigationStack
            {
                ZStack
                {
                    if #available(iOS 26.0, *)
                    {
                        SettingsView(transactionBST: transactionBST)
                        .glassEffect(.regular, in: .rect(cornerRadius: 16))
                    }
                    else
                    { SettingsView(transactionBST: transactionBST) }
                }
                .frame(maxWidth: .infinity, minHeight: 700, maxHeight: 700)
                .padding(.horizontal)
                .background(BackgroundImage("Gradients"))
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            .tag(ViewTabs.settings)
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
