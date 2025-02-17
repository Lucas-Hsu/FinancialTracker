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
            HStack{
                CalendarView()
                History()
            }
            .tabItem {
                Label("Records", systemImage: "list.dash")
            }
            .tag(0)
            

            Statistics()
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar.fill")
                }
                .tag(1)

        }
        .accentColor(.blue) // Set the accent color for selected tabs
        .environment(\.horizontalSizeClass, .compact)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Transaction.self, inMemory: true)
}
