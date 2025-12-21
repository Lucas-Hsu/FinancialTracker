//
//  SummaryView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/21/25.
//

import SwiftUI
import SwiftData

struct SummaryView: View
{
    // MARK: - Attributes
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @State private var viewModel: SummaryViewModel
    
    // MARK: - Constructor
    init()
    {
        _viewModel = State(initialValue: SummaryViewModel(transactions: []))
    }
    
    // MARK: - UI
    var body: some View
    {
        VStack
        {
            ForEach(Tag.allCases, id: \.self)
            { tag in
                SpendingPredictionRowGlass(tag: tag,
                                           current: viewModel.aggregates[tag] ?? 0.0,
                                           prediction: viewModel.predictions[tag] ?? 0.0)
                .padding(.horizontal, 20)
            }
            .frame(maxHeight: .infinity)
        }
        .shadow(color: defaultPanelShadowColor, radius: 4, x: 0, y: 6)
        .onChange(of: transactions, initial: true)
        { oldValue, newValue in
            viewModel.refresh(transactions: newValue)
        }
    }
}
