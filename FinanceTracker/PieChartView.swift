//
//  PieChartView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 6/3/25.
//
import SwiftUI
import Charts

struct PieChartView: View {
    let data: [(tag: String, total: Double)]
    let total: Double

    var body: some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.vertical, 4)
            Chart {
                ForEach(data, id: \.tag) { entry in
                    let percentage = total == 0 ? 0 : entry.total / total
                    SectorMark(
                        angle: .value("Amount", entry.total),
                        innerRadius: .ratio(0.4)
                    )
                    .foregroundStyle(by: .value("Tag", entry.tag + ": $\(String(format: "%.2f", entry.total))"))
                    .annotation(position: .overlay) {
                        Text(String(format: "%.0f%%", percentage * 100))
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(height: 360)
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 4) {
                Text("Total Expenditure: $\(String(format: "%.2f", total))")
                    .font(.footnote)
                    .bold()
                Divider()
                    .padding(.vertical, 4)
                
            }
            .padding(.horizontal)
        }
        .padding(.top)
    }
}
