//
//  Statistics.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 1/31/25.
//

import SwiftUI
import SwiftData

struct Statistics: View {
    @Environment(\.modelContext) var modelContext
    @State private var dateStart = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    @State private var dateEnd = Date()
    
    @Query(sort: \Transaction.date, order: .reverse) var transactions: [Transaction]
    
    @State private var selectedTags: Set<String> = Set(Tag.allCases.map { $0.rawValue })
    @State private var isUnpaid: Bool = false
    
    @State private var showPieChart: Bool = false
    @State private var frozenGroupedByTag: [(tag: String, total: Double)] = []
    @State private var frozenTotalSum: Double = 0.0

    private var filteredTransactions: [Transaction] {
        transactions.filter {
            $0.date >= dateStart &&
            $0.date <= dateEnd &&
            $0.matchesFilter(tags: selectedTags, isUnpaid: isUnpaid)
        }
    }

    private func computePieChartData() {
        let groups = Dictionary(grouping: filteredTransactions, by: { $0.tag })
        let grouped = groups.map { (key, txns) in
            (tag: key, total: txns.reduce(0.0) { $0 + $1.price })
        }
        .filter { $0.total > 0 }
        .sorted { $0.total > $1.total }

        frozenGroupedByTag = grouped
        frozenTotalSum = grouped.reduce(0) { $0 + $1.total }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Statistics Page")
                .font(.largeTitle)
            
            Text("Bar")
            
            Form {
                HStack {
                    ForEach(Tag.allCases, id: \.self) { tag in
                        Image(systemName: symbolRepresentation[tag] ?? "questionmark")
                            .padding()
                            .frame(width: 80, height: 50)
                            .background(selectedTags.contains(tag.rawValue) ? Color.accentColor : Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(selectedTags.contains(tag.rawValue) ? .white : .secondary)
                            .onTapGesture {
                                if selectedTags.contains(tag.rawValue) {
                                    selectedTags.remove(tag.rawValue)
                                } else {
                                    selectedTags.insert(tag.rawValue)
                                }
                            }
                    }
                }
                .padding(.horizontal)
                
                Toggle("Show Only Payment Pending", isOn: $isUnpaid)
                    .toggleStyle(ButtonToggleStyle())
                    .scaleEffect(isUnpaid ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isUnpaid)

                DatePicker("Start Date", selection: $dateStart, displayedComponents: .date)
                DatePicker("End Date", selection: $dateEnd, displayedComponents: .date)
            }
            .frame(maxHeight: 300)

            Button(action: {
                computePieChartData()
                showPieChart = true
            }) {
                Text("Generate Pie Chart")
                    .font(.headline)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 24)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            if showPieChart {
                if frozenGroupedByTag.isEmpty {
                    Text("No transactions match the selected filters.")
                        .foregroundColor(.secondary)
                        .padding(.top, 16)
                } else {
                    PieChartView(data: frozenGroupedByTag, total: frozenTotalSum)
                }
            }

            Spacer()
        }
        .padding(.top)
    }
}

// This is the #Preview block for your Statistics view
#Preview {
    Statistics()
}
