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
    var body: some View {
        TabView {
            
            Text("Suggestions")
                .tabItem {
                    Label("Suggestions", systemImage: "person.text.rectangle")
                }
                .tag(0)
            
            HStack{
                CalendarView()
                History()
            }
            .tabItem {
                Label("Records", systemImage: "list.dash")
            }
            .tag(1)
            

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
        .modelContainer(for: Transaction.self, inMemory: true)
}
