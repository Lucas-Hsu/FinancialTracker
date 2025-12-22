//
//  HistoryView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/22/25.
//

import SwiftUI
import Charts
import SwiftData

/// View for Bar Chart History
struct HistoryView: View
{
    // MARK: - Private Attributes
    private var transactions: [Transaction]
    @State private var viewModel = HistoryViewModel()
    @State private var inputStart: Date = Date()
    @State private var inputEnd: Date = Date()
    @State private var selectedTimestep: Timestep = .months
    @State private var hide: Bool = false
    
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
                    {
                        contentUnavailable
                        .background(defaultPanelBackgroundColor)
                        .cornerRadius(16)
                    }
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
            selectedTimestep = viewModel.timestep
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
            // Timestep Picker
            VStack(alignment: .leading, spacing: 10)
            {
                Text("Timestep")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                Picker("Timestep", selection: $selectedTimestep)
                {
                    ForEach(Timestep.allCases)
                    { step in
                        Text(step.rawValue).tag(step)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }
            .padding(.vertical, 10)
            Divider()
            // Generate Bar Chart
            PrimaryButtonGlass(title: "Generate")
            { generate() }
            .shadow(color: defaultButtonShadowColor, radius: 4, x: 0, y: 4)
            .padding(.vertical, 16)
            .padding(.bottom, 20)
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Components
    // MARK: Bar Chart
    private var chartLayout: some View
    {
        ZStack(alignment: .topTrailing)
        {
            // Chart
            Chart(viewModel.chartData)
            { item in
                BarMark(x: .value("Date", item.date, unit: viewModel.timestep == .years ? .year : .month),
                        y: .value("Amount", item.value))
                .foregroundStyle(Color.accentColor)
                .cornerRadius(12)
                .annotation(position: .top)
                {
                    Text("¥" + PriceFormatter.format(price: item.value))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
            }
            .chartXAxis
            {
                AxisMarks(values: .stride(by: viewModel.timestep == .years ? .year : .month))
                { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: viewModel.timestep == .years ? .dateTime.year() : .dateTime.month().year())
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(20)
            // Legend
            legendView
            .padding(12)
            .background(defaultPanelBackgroundColor)
            .cornerRadius(12)
            .shadow(color: defaultPanelShadowColor, radius: 4, x: 0, y: 4)
            .opacity(hide ? 0.01 : 1)
            .onTapGesture
            { hide.toggle() }
        }
    }
    // MARK: Legend
    private var legendView: some View
    {
        HStack
        {
            VStack(alignment: .leading, spacing: 10)
            {
                Text("Expenditure History By \(viewModel.timestep.rawValue)")
                .font(.caption)
                .foregroundStyle(.primary)
                Text("\(DateFormatters.MMMyyyy(date: inputStart)) ~ \(DateFormatters.MMMyyyy(date: inputEnd))")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 2)
                HStack(spacing: 8)
                {
                    Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: 12, height: 12)
                    .cornerRadius(2)
                    Text("Expenditure Sum")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .frame(maxWidth: 220)
    }
    // MARK: Not Enough Data
    private var contentUnavailable: some View
    {
        VStack(spacing: 15)
        {
            Image(systemName: "chart.bar")
            .font(.system(size: 60))
            .foregroundStyle(.secondary)
            Text("Not Enough Data")
            .font(.title3)
            .foregroundStyle(.secondary)
            Text("Adjust date range or timestep and tap generate.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .shadow(color: defaultPanelShadowColor, radius: 4, x: 0, y: 6)
    }
    
    // MARK: - Logic
    private func generate()
    {
        viewModel.setStartMonth(inputStart)
        viewModel.setEndMonth(inputEnd)
        viewModel.setTimestep(selectedTimestep)
        viewModel.generate()
    }
}
