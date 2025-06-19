//
//  BarChartView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 6/19/25.
//

import SwiftUI
import Charts

public struct MonthlyTotal: Identifiable {
    public let id = UUID()
    let tag: Int   // e.g., 202506 for June 2025
    let total: Double
}


struct BarChartView: View {
    let grouped: [MonthlyTotal]
    let average: Double

    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) var displayScale
    
    private let barWidth: CGFloat = 100
    private let spacing: CGFloat = 40

    private func formattedDate(from tag: Int) -> String {
        let year = tag / 100
        let month = tag % 100
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        if let date = dateFormatter.date(from: "\(year)-\(month)") {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM yy"
            return displayFormatter.string(from: date)
        }
        return "\(month)/\(year)"
    }
    
    var body: some View {
        let chartWidth = CGFloat(grouped.count) * (barWidth + spacing) + 2 * spacing
        VStack {
            HStack {
                Spacer(minLength: 0)
                
                Chart {
                    ForEach(grouped) { entry in
                        BarMark(
                            x: .value("Month", formattedDate(from: entry.tag)),
                            y: .value("Total", entry.total)
                        )
                        .foregroundStyle(.blue)
                    }

                    RuleMark(y: .value("Average", average))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(.red)
                        .annotation(position: .top, alignment: .leading) {
                            Text("Average: \(average, format: .number.precision(.fractionLength(2)))")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                }
                .frame(width: chartWidth, height: 300)

                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .overlay(alignment: .topLeading) {
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 60, weight: .regular))
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .accentButton()
                .cornerRadius(100)
                .padding(.top, 20)
                
                Button(action: {
                    saveImageToAlbum(BarChartView(grouped: grouped, average: average)
                        .asUIImage(displayScale: displayScale).makeOpaque())
                    print("Saved image to album!")
                    dismiss()
                }) {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 60, weight: .regular))
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .accentButton()
                .cornerRadius(100)
                .padding(.top, 20)
            }
            .padding(.leading, 45)
        }
    }
}
