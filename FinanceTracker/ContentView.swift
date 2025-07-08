//
//  ContentView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 1/13/25.
//

import SwiftUI
import SwiftData

enum Tab: Int, CaseIterable {
  case records,
       suggestions,
       statistics
}

func saveModelContext(_ modelContext: ModelContext)
{
    do
    {
        try modelContext.save()
    } catch
    {
        print("Failed to save context: \(error)")
    }
}

struct ContentView: View
{
    @StateObject private var addNewSheetController = SheetController()
    @State private var selectedTab: Tab = Tab.records
    
    var body: some View
    {
        TabView (selection: $selectedTab)
        {
            Suggestions()
                .tabItem { Label("Suggestions",
                                 systemImage: "person.text.rectangle") }
                .tag(Tab.suggestions)
                .colorfulAccentBackground(colorLinear: [.accentColor, .white, .white],
                                          colorRadial: [.accentColor, .white, .accentColor, .white])
                .edgesIgnoringSafeArea(.all)
                
            HStack
            {
                CalendarView()
                    .padding()
                History()
                    .padding()
            }
                .environmentObject(addNewSheetController)
                .fullScreenCover(isPresented: $addNewSheetController.showAddNewSheet)
                {
                    AddNew(date: addNewSheetController.date,
                           name: addNewSheetController.name,
                           tag: addNewSheetController.tag,
                           price: addNewSheetController.price)
                }
                .tabItem { Label("Records",
                                 systemImage: "list.dash") }
                .tag(Tab.records)
                .colorfulAccentBackground(colorLinear: [.white, .white],
                                          colorRadial: [.accentColor, .white, .accentColor, .white])
                .edgesIgnoringSafeArea(.all)
            
            Statistics()
                .tabItem { Label("Statistics",
                                 systemImage: "chart.bar.fill") }
                .tag(Tab.statistics)
        }
            .environment(\.horizontalSizeClass, .compact)
    }
}

#Preview
{ ContentView()
        .modelContainer(for: [Transaction.self,
                              RecurringTransaction.self],
                        inMemory: true) }
