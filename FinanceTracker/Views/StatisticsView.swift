//
//  StatisticsView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/21/25.
//

import SwiftUI
import SwiftData

/// This is the statistics page that shows pie chart or summary.
struct StatisticsView: View
{
    // MARK: - State Management
    private enum StatisticType: String, CaseIterable, Identifiable
    {
        var id: String { self.rawValue }
        case predict = "Spending Summary"
        case ratio   = "Spending Ratio"
        case history = "Spending History"
    }
    @State private var selection: StatisticType = StatisticType.predict
    
    // MARK: - Private Attributes
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    // MARK: - UI
    var body: some View
    {
        VStack(spacing: 20)
        {
            // MARK: Statistics Type Selection Toolbar
            Group
            {
                if #available(iOS 26.0, *)
                {
                    toolbar
                    .glassEffect(.regular, in: .rect(cornerRadius: 12))
                }
                else
                { toolbar }
            }
            .shadow(color: defaultPanelShadowColor, radius: 6, x: 0, y: 4)
            // MARK: Statistics Window
            Group
            {
                switch selection
                {
                case .predict:
                    SummaryView()
                case .ratio:
                    ComparisonView(transactions: transactions)
                case .history:
                    HistoryView(transactions: transactions)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 700, maxHeight: 700)
        .padding()
    }
    
    // MARK: - Components
    // Toolbar
    private var toolbar: some View
    {
        HStack
        {
            dropdown
            Spacer()
            if selection == .predict
            {
                Text(Date().formatted(.dateTime.month(.wide).year()))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .frame(height: 60)
    }
    // Dropdown Selection
    private var dropdown: some View
    {
        Menu
        {
            ForEach(StatisticType.allCases)
            { type in
                Button(type.rawValue)
                { selection = type }
            }
        }
        label:
        {
            HStack
            {
                Label(selection.rawValue, systemImage: "chevron.down")
                .fontWeight(.bold)
                .font(.title2)
                .foregroundStyle(Color.primary)
                .frame(width: 236)
            }
        }
        .frame(width: 240)
    }
}
