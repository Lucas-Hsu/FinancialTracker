//
//  StatisticsView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/21/25.
//

import SwiftUI
import SwiftData

struct StatisticsView: View
{
    // MARK: - State Management
    private enum StatisticType: String, CaseIterable
    {
        case predict = "Monthly Spending"
        case ratio   = "    Spending Ratio    "
    }
    @State private var selection: StatisticType = StatisticType.predict

    // MARK: - UI
    var body: some View
    {
        VStack(spacing: 20)
        {
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
            Group
            {
                if selection == .predict
                { SummaryView() }
                else
                { Spacer() }
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
            Button(StatisticType.predict.rawValue) { selection = .predict }
            Button(StatisticType.ratio.rawValue) { selection = .ratio }
        }
        label:
        {
            HStack
            {
                Text(selection.rawValue)
                .fontWeight(.bold)
                .font(.title2)
                .foregroundStyle(Color.primary)
                Image(systemName: "chevron.down")
                .foregroundStyle(Color.primary)
            }
        }
        .frame(width: 240)
    }
}
