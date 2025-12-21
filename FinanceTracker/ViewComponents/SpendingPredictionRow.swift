//
//  SpendingPredictionRow.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/21/25.
//

import SwiftUI

struct SpendingPredictionRow: View
{
    // MARK: - Attributes
    let tag: Tag
    let current: Double
    let prediction: Double
    
    // MARK: - Computed Variables
    private var maxScale: Double
    {
        if current > prediction
        { return current * 1.002 }
        else
        { return max(prediction * 1.01, 1.0) }
    }
    
    // MARK: - UI
    var body: some View
    {
        VStack(alignment: .leading, spacing: 6)
        {
            // MARK: Labels
            HStack(alignment: .firstTextBaseline)
            {
                HStack(spacing: 6)
                {
                    Image(systemName: tagSymbols[tag] ?? "tag.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    Text(tag.rawValue.capitalized)
                    .font(.headline)
                    .foregroundStyle(.primary)
                }
                Spacer()
                // Status Text
                if current > prediction
                {
                    Text("¥\(PriceFormatter.format(price: current - prediction)) over")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fontWeight(.bold)
                }
                else
                {
                    Text("¥\(PriceFormatter.format(price: prediction - current)) left")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            
            // MARK: Bar
            GeometryReader
            { geometry in
                let width = geometry.size.width
                let predictionWidth = CGFloat(prediction / maxScale) * width
                let currentWidth = CGFloat(current / maxScale) * width
                let isOverBudget = current > prediction
                ZStack(alignment: .leading)
                {
                    // Base bar
                    Capsule()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: width, height: 12)
                    // Actual spending
                    Capsule()
                    .fill(isOverBudget ? Color.red : Color.accentColor)
                    .frame(width: max(0, currentWidth), height: 12)
                    .shadow(color: isOverBudget ? .red.opacity(0.4) : .accentColor.opacity(0.4), radius: 4, x: 0, y: 2)
                    // Expenditure forecast
                    ZStack(alignment: .trailing)
                    {
                        Capsule()
                        .fill(Color(isOverBudget ? .red : .accentColor).mix(with: .white, by: 0.5).opacity(0.25))
                        .frame(width: max(0, predictionWidth), height: 12)
                        .overlay
                        {
                            Capsule()
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        }
                        // Limit Line
                        Capsule()
                        .fill(Color(isOverBudget ? .red : .accentColor).mix(with: .white, by: 0.5).opacity(1))
                        .frame(width: 4, height: 16)
                    }
                    .frame(width: max(0, predictionWidth), alignment: .leading)
                }
            }
            .frame(height: 16)
            
            // MARK: Amount Labels
            HStack
            {
                Text("¥\(PriceFormatter.format(price: current))")
                .font(.caption2)
                .foregroundStyle(current > prediction ? .red : .primary)
                Spacer()
                Text("Forecasted Budget: ¥\(PriceFormatter.format(price: prediction))")
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .background(.clear)
        .padding(10)
    }
}

struct SpendingPredictionRowGlass: View
{
    // MARK: - Attributes
    let tag: Tag
    let current: Double
    let prediction: Double
    
    // MARK: - UI
    var body: some View
    {
        if #available(iOS 26.0, *)
        {
            SpendingPredictionRow(tag: tag,
                                  current: current,
                                  prediction: prediction)
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
        }
        else
        {
            SpendingPredictionRow(tag: tag,
                                  current: current,
                                  prediction: prediction)
        }
    }
}
