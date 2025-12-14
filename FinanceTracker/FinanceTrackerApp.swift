//
//  FinanceTrackerApp.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 1/13/25.
//

import SwiftUI
import SwiftData

/// main: The app starts here
@main
struct FinanceTrackerApp: App
{
    var sharedModelContainer: ModelContainer =
    {
        let schema = Schema([Transaction.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do
        {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        }
        catch
        {
            fatalError("[ERROR] Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene
    {
        WindowGroup
        {
            ContentView()
        }
            .modelContainer(sharedModelContainer)
    }
}
