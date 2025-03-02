//
//  ContentView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 1/13/25.
//

import SwiftUI
import SwiftData

enum Tabs {
    case graphs, plus, me
}

import SwiftUI

struct ContentView: View {
    @StateObject private var sheetController = SheetController()
    @State private var selectedTab: Int = 0
    var body: some View {
        TabView (selection: $selectedTab) {
            
            
            
            
            
            Suggestions()
                .tabItem {
                    Label("Suggestions", systemImage: "person.text.rectangle")
                }
                .tag(1)
            
            HStack{
                CalendarView()
                History()
            }
            .environmentObject(sheetController)
            .fullScreenCover(isPresented: $sheetController.showAddNewSheet) {
                AddNew(name: sheetController.name,
                       selectedTag: sheetController.tag,
                       price: sheetController.price)
            }
            .tabItem {
                Label("Records", systemImage: "list.dash")
            }
            .tag(0)
            

            Statistics()
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar.fill")
                }
                .tag(2)

        }
        .accentColor(.blue) // Set the accent color for selected tabs
        .environment(\.horizontalSizeClass, .compact)
    }
}


#Preview {
    ContentView()
        .modelContainer(for: [Transaction.self, RecurringTransaction.self], inMemory: true)
}
