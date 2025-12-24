//
//  PieChartView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 6/3/25.
//
import SwiftUI
import Charts

struct PieChartView: View {
    let data: [(tag: Tag, total: Double)]
    let total: Double
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) var displayScale
    
    var body: some View {
        VStack {
            if (data.isEmpty) {
                Text("No transactions match the selected filters.")
                    .foregroundColor(.secondary)
                    .padding(.top, 16)
            } else {
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
                            .foregroundStyle(by: .value("Tag", entry.tag.rawValue + ": $\(String(format: "%.2f", entry.total))"))
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
                    PieChartView(data: data, total: total)
                        .asUIImage(displayScale: displayScale)
                        .makeOpaque()
                        .saveToAlbum()
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
