//
//  FinanceTrackerApp.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 1/13/25.
//
import SwiftUI
import SwiftData

@main
struct FinanceTrackerApp: App
{
    var sharedModelContainer: ModelContainer =
    {
        let schema = Schema([Transaction.self,
                             RecurringTransaction.self,
                             SelectedRecurringTransactionIDs.self
                            ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene
    {
        WindowGroup { ContentView() }
            .modelContainer(sharedModelContainer)
    }
}
