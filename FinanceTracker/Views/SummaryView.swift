//
//  SummaryView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/21/25.
//

import SwiftUI
import SwiftData

/// View that shows current month total spendings per `Tag` and corresponding predicted budget.
struct SummaryView: View
{
    // MARK: - Attributes
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @State private var viewModel: SummaryViewModel
    @State private var isVisible: Bool = false
    
    // MARK: - Constructor
    init()
    {
        _viewModel = State(initialValue: SummaryViewModel())
    }
    
    // MARK: - UI
    var body: some View
    {
        ZStack
        {
            if viewModel.isLoading
            {
                // MARK: Loading Message
                VStack(spacing: 15)
                {
                    ProgressView()
                    .controlSize(.large)
                    Text("Calculating budget...")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.clear)
            }
            else
            {
                // MARK: Summary Rows
                VStack
                {
                    ForEach(Tag.allCases, id: \.self)
                    { tag in
                        SpendingPredictionRowGlass(tag: tag,
                                                   current: viewModel.aggregates[tag] ?? 0.0,
                                                   prediction: viewModel.predictions[tag] ?? 0.0)
                        .padding(.horizontal, 12)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }
        .shadow(color: defaultPanelShadowColor, radius: 4, x: 0, y: 6)
        .onAppear
        {
            isVisible = true
            Task
            { await viewModel.refresh(transactions: transactions) }
        }
        .onDisappear
        {
            isVisible = false
            viewModel.clear()
        }
        .onChange(of: transactions)
        { _, newValue in
            if isVisible
            {
                Task
                { await viewModel.refresh(transactions: newValue) }
            }
        }
    }
}
