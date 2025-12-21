//
//  ComparisonView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/21/25.
//

import SwiftUI
import Charts
import SwiftData

/// View for Pie Chart
struct ComparisonView: View
{
    // MARK: - Private Attributes
    private var transactions: [Transaction]
    @State private var viewModel = ComparisonViewModel()
    @State private var inputStart: Date = Date()
    @State private var inputEnd: Date = Date()
    
    // MARK: - Constructor
    init(transactions: [Transaction])
    {
        self.transactions = transactions
    }
    
    // MARK: - UI
    var body: some View
    {
        HStack(spacing: 20)
        {
            // MARK: Controls
            VStack(spacing: 0)
            {
                if #available(iOS 26.0, *)
                {
                    controlPanel
                    .glassEffect(.regular, in: .rect(cornerRadius: 16))
                    .shadow(color: defaultPanelShadowColor, radius: 4, x: 0, y: 6)
                }
                else
                {
                    controlPanel
                    .background(defaultPanelBackgroundColor)
                    .cornerRadius(16)
                    .shadow(color: defaultPanelShadowColor, radius: 4, x: 0, y: 6)
                }
            }
            .frame(width: 220)
            // MARK: Chart
            VStack
            {
                if viewModel.chartData.isEmpty
                {
                    if #available(iOS 26.0, *)
                    {
                        contentUnavailable
                        .glassEffect(.regular, in: .rect(cornerRadius: 16))
                    }
                    else
                    { contentUnavailable }
                }
                else
                {
                    if #available(iOS 26.0, *)
                    {
                        chartLayout
                        .padding()
                        .glassEffect(.regular, in: .rect(cornerRadius: 16))
                        .shadow(color: defaultPanelShadowColor, radius: 4, x: 0, y: 6)
                    }
                    else
                    {
                        chartLayout
                        .padding()
                        .background(defaultPanelBackgroundColor)
                        .cornerRadius(16)
                        .shadow(color: defaultPanelShadowColor, radius: 4, x: 0, y: 6)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
        .onAppear
        {
            inputStart = viewModel.startMonth
            inputEnd = viewModel.endMonth
            viewModel.refreshTransactions(transactions: transactions)
        }
        .onChange(of: transactions)
        { _, newValue in
            viewModel.refreshTransactions(transactions: newValue)
        }
    }
    
    // MARK: - Components
    // MARK: Control Panel
    private var controlPanel: some View
    {
        VStack(spacing: 15)
        {
            Text("Configuration")
                .font(.headline)
                .padding(.top, 20)
            Divider()
            // Date Wheels
            VStack(alignment: .leading, spacing: 5)
            {
                Text("From")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                HStack
                {
                    Spacer()
                    MonthYearWheelPicker(date: $inputStart)
                    .frame(height: 100)
                    Spacer()
                }
                Divider()
                .padding(.vertical, 5)
                Text("To")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                HStack
                {
                    Spacer()
                    MonthYearWheelPicker(date: $inputEnd)
                    .frame(height: 100)
                    Spacer()
                }
            }
            .frame(maxHeight: 280)
            Divider()
            // Tag Selectors
            VStack(alignment: .leading, spacing: 10)
            {
                Text("Categories")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10)
                {
                    ForEach(Tag.allCases, id: \.self)
                    { tag in
                        IconToggleButtonGlass(icon: tagSymbols[tag] ?? "questionmark",
                                              shadow: viewModel.selectedTags.contains(tag),
                                              toggle: viewModel.selectedTags.contains(tag))
                        { viewModel.toggleTag(tag) }
                        .frame(width: 60, height: 40)
                    }
                }
                .padding(.horizontal)
            }
            Divider()
            // Generate Button
            PrimaryButtonGlass(title: "Generate")
            { generate() }
            .shadow(color: defaultButtonShadowColor, radius: 4, x: 0, y: 4)
            .padding(.bottom, 20)
        }
    }
    // MARK: Pie Chart
    private var chartLayout: some View
    {
        ZStack(alignment: .topTrailing)
        {
            // Chart
            HStack
            {
                Chart(viewModel.chartData)
                { item in
                    SectorMark(angle: .value("Amount", item.value),
                               innerRadius: .ratio(0.5),
                               angularInset: 1.5)
                    .cornerRadius(5)
                    .foregroundStyle(tagColors(item.tag))
                    .annotation(position: .overlay)
                    {
                        if item.percentage > 0.05
                        {
                            Text("\(Int(item.percentage * 100))%")
                            .frame(height: 10)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 1)
                        }
                    }
                }
                .frame(width: 500)
                .padding(20)
                .padding(.leading, 20)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            // Legend
            legendView
            .padding(12)
            .background(defaultPanelBackgroundColor)
            .cornerRadius(12)
            .shadow(color: defaultPanelShadowColor, radius: 4, x: 0, y: 4)
        }
    }
    // MARK: Legend
    private var legendView: some View
    {
        VStack(alignment: .leading, spacing: 10)
        {
            Text("Total Expenditure Comparison by Tags")
            .font(.caption)
            .foregroundStyle(.primary)
            Text("\(DateFormatters.MMMyyyy(date: inputStart)) ~ \(DateFormatters.MMMyyyy(date: inputEnd))")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.bottom, 2)
            ForEach(viewModel.chartData)
            { item in
                HStack(spacing: 0)
                {
                    HStack
                    {
                        Circle()
                        .fill(tagColors(item.tag))
                        .frame(width: 10, height: 10)
                        Image(systemName: tagSymbols[item.tag] ?? "questionmark")
                        .foregroundStyle(tagColors(item.tag))
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 40, alignment: .leading)
                        .lineLimit(1)
                    }
                    Spacer()
                    Text("\(PriceFormatter.format1D(price: item.percentage * 100))%")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    Spacer()
                    Text("¥" + PriceFormatter.format(price: item.value))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: 220)
    }
    // MARK: Not Enough Data
    private var contentUnavailable: some View
    {
        VStack(spacing: 15)
        {
            Image(systemName: "chart.pie")
            .font(.system(size: 60))
            .foregroundStyle(.secondary)
            Text("Not Enough Data")
            .font(.title3)
            .foregroundStyle(.secondary)
            Text("Adjust filters or date range to generate statistics.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(defaultPanelBackgroundColor)
        .cornerRadius(16)
        .shadow(color: defaultPanelShadowColor, radius: 4, x: 0, y: 6)
    }
    
    // MARK: - Logic
    // Generate Pie Chart
    private func generate()
    {
        viewModel.setStartMonth(inputStart)
        viewModel.setEndMonth(inputEnd)
        viewModel.generate()
    }
}
