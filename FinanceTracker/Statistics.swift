//
//  Statistics.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 1/31/25.
//

import SwiftUI
import SwiftData

extension UIImage {
    func makeOpaque() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = self.scale
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: self.size, format: format)
        return renderer.image { _ in
            UIColor.white.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: self.size)).fill()
            self.draw(in: CGRect(origin: .zero, size: self.size))
        }
    }
    
    func saveToAlbum() {
        UIImageWriteToSavedPhotosAlbum(self, nil, nil, nil)
    }
}

struct Statistics: View {
    @Environment(\.modelContext) var modelContext
    @State private var dateStart = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    @State private var dateEnd = Date()
    
    @Query(sort: \Transaction.date, order: .reverse) var transactions: [Transaction]
    
    @State private var selectedTags: Set<String> = Set(Tag.allCases.map { $0.rawValue })
    @State private var isUnpaid: Bool = false
    
    @State private var showPieChart: Bool = false
    @State private var showBarChart: Bool = false
    @State private var frozenGroupedByTag: [(tag: String, total: Double)] = []
    @State private var frozenTotalSum: Double = 0.0

    private var pieFilteredTransactions: [Transaction] {
        transactions.filter {
            $0.date >= dateStart &&
            $0.date <= dateEnd &&
            $0.matchesFilter(onlyUnpaid: isUnpaid, tags: selectedTags)
        }
    }
    
    private var barFilteredTransactions: [Transaction] {
        transactions.filter {
            let startYear = Calendar.current.component(.year, from: barStart)
            let endYear = Calendar.current.component(.year, from: barEnd)
            let startMonth = Calendar.current.component(.month, from: barStart)
            let endMonth = Calendar.current.component(.month, from: barEnd)
            
            // Get the transaction year once
            let tYear = Calendar.current.component(.year, from: $0.date)
            let tMonth = Calendar.current.component(.month, from: $0.date)

            return ( (tYear == startYear && tMonth >= startMonth) || (tYear > startYear) ) && ( (tYear == endYear && tMonth <= endMonth) || (tYear < endYear) ) &&
            $0.matchesFilter(onlyUnpaid: isUnpaid, tags: Set([selectedBarTag.rawValue]))
        }
    }
    
    private var past12MonthsTransactions: [Transaction] {
        transactions.filter {
            let pastYear = Calendar.current.date(byAdding: .year, value: -1, to: Date())
            let startYear = Calendar.current.component(.year, from: pastYear!)
            let startMonth = Calendar.current.component(.month, from: pastYear!)

            let tYear = Calendar.current.component(.year, from: $0.date)
            let tMonth = Calendar.current.component(.month, from: $0.date)

            return ( (tYear == startYear && tMonth >= startMonth) || (tYear > startYear) )
        }
    }

    private func computePieChartData() {
        let groups = Dictionary(grouping: pieFilteredTransactions, by: { $0.tag })
        let grouped = groups.map { (key, txns) in
            (tag: key, total: txns.reduce(0.0) { $0 + $1.price })
        }
        .filter { $0.total > 0 }
        .sorted { $0.total > $1.total }

        frozenGroupedByTag = grouped
        frozenTotalSum = grouped.reduce(0) { $0 + $1.total }
    }
    
    @State private var frozenGroupedByMonth: [MonthlyTotal] = []
    @State private var frozenAverage: Double = 0.0
    
    struct MonthKey: Hashable {
        let year: Int
        let month: Int
    }

    func calculateAverageMonthlyExpenditures(groups: [String: [Transaction]]) -> [String: Double] {
        var avg: [String: Double] = [:]
        
        // Iterate through all tags
        for tag in Tag.allCases {
            guard let transactions = groups[tag.rawValue] else { continue }
            
            // Group transactions by (year, month)
            let groupedByMonth: [MonthKey: [Transaction]] = Dictionary(
                grouping: transactions,
                by: { transaction in
                    let components = Calendar.current.dateComponents([.year, .month], from: transaction.date)
                    return MonthKey(year: components.year!, month: components.month!)
                }
            )
            
            // Store the sums of the total transaction prices per month
            var sums: [Double] = []
            
            for (_, monthTransactions) in groupedByMonth {
                let totalPrice = monthTransactions.reduce(0.0) { $0 + $1.price }
                sums.append(totalPrice)
            }
            
            // Step 1: Calculate Q1, Q3, and IQR
            let sortedSums = sums.sorted()
            let q1 = quantile(sortedSums, p: 0.25)
            let q3 = quantile(sortedSums, p: 0.75)
            let iqr = q3 - q1
            
            // Step 2: Remove outliers
            let nonOutlierSums = sums.filter { $0 >= q1 - 1.5 * iqr && $0 <= q3 + 1.5 * iqr }
            
            // Step 3: Calculate the average (divide by the number of non-outlier months)
            if !nonOutlierSums.isEmpty {
                let total = nonOutlierSums.reduce(0.0, +)
                avg[tag.rawValue] = total / Double(nonOutlierSums.count)  // Average based on non-outlier months
            }
        }
        
        return avg
    }

    func quantile(_ values: [Double], p: Double) -> Double {
        guard !values.isEmpty else { return 0.0 }
        let sorted = values.sorted()
        let pos = Double(sorted.count - 1) * p
        let index = Int(pos)
        let fraction = pos - Double(index)

        if index + 1 < sorted.count {
            return sorted[index] + fraction * (sorted[index + 1] - sorted[index])
        } else {
            return sorted[index]
        }
    }

    
    private func pastDataSummary() -> [String:Double]{
        let groups = Dictionary(grouping: past12MonthsTransactions, by: { $0.tag })
        return calculateAverageMonthlyExpenditures(groups: groups)
    }
    
    private func computeBarChartData() {
        let groups = Dictionary(grouping: barFilteredTransactions, by: { Calendar.current.component(.year, from: $0.date) * 100 + Calendar.current.component(.month, from: $0.date) })
        let grouped = groups.map { (key, txns) in
            (date: key, total: txns.reduce(0.0) { $0 + $1.price })
        }
        frozenGroupedByMonth = convertToMonthlyTotal(grouped)
        frozenAverage = barFilteredTransactions.isEmpty ? 0 : barFilteredTransactions.reduce(0.0, { $0 + $1.price }) / Double(barFilteredTransactions.count)

        print(barFilteredTransactions)
        print(frozenGroupedByMonth)
        print(frozenAverage)
        print()
    }
    private func convertToMonthlyTotal(_ input: [(date: Int, total: Double)]) -> [MonthlyTotal] {
        input.map { MonthlyTotal(date: $0.date, total: $0.total) }
    }
    
    enum ChartType: String, CaseIterable, Identifiable {
        case bar = "Bar"
        case mtsum = "Monthly Summary"
        case pie = "Pie"
        var id: String { self.rawValue }
    }
    @State private var selectedChart: ChartType = .mtsum 
    
    @State private var selectedBarTag: Tag = .other
    @State private var showBarDates: Bool = false
    
    @State private var barStart: Date = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    @State private var barEnd: Date = Date()
    
    @State private var scaleEffect: CGFloat = 1.0
    
    var body: some View {
        VStack (alignment: .leading, spacing: 8)
        {
            
            Text("Statistics Page")
                .font(.largeTitle)
            
            Picker("Chart Type", selection: $selectedChart) {
                ForEach(ChartType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }.pickerStyle(SegmentedPickerStyle())
                .frame(width: 500)
            
            switch (selectedChart) {
            case .pie:
                VStack(spacing: 16)
                {

                    HStack {
                        ForEach(Tag.allCases, id: \.self) { tag in
                            Image(systemName: tagSymbol[tag] ?? "questionmark")
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
                    
                    VStack{
                        DatePicker("Start Date", selection: $dateStart, displayedComponents: .date)
                        DatePicker("End Date", selection: $dateEnd, displayedComponents: .date)
                    }
                    .frame(width: 500)
                
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
                    .fullScreenCover(isPresented: $showPieChart) {
                        ZStack {
                            Color.clear
                                .background(.ultraThinMaterial)
                                .ignoresSafeArea()
                            PieChartView(data: frozenGroupedByTag, total: frozenTotalSum)
                        }
                    }
                }
                
            case .bar:
                VStack(spacing: 16) {
                    Picker("Tag", selection: $selectedBarTag) {
                        ForEach(Tag.allCases) { tag in
                            Image(systemName: tagSymbol[tag] ?? "questionmark")
                                .tag(tag)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 500)
                    
                    Toggle("Show Only Payment Pending", isOn: $isUnpaid)
                        .toggleStyle(ButtonToggleStyle())
                        .scaleEffect(isUnpaid ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isUnpaid)
                    
                    Button(action: {
                        scaleEffect = 1.1
                        showBarDates = true
                        withAnimation {
                            scaleEffect = 1.0
                        }
                    }) {
                        Text("Start Date \(barStart.formatted(.dateTime.year().month()))\nEnd Date \(barEnd.formatted(.dateTime.year().month()))")
                            .padding()
                    }
                    .sheet(isPresented: $showBarDates){ BarYearMonthSelector(startDate: $barStart, endDate: $barEnd)
                    }
                    .accentButton()
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                    .scaleEffect(scaleEffect)
                    .padding()
                    
                    Button(action: {
                        computeBarChartData()
                        showBarChart = true
                    }) {
                        Text("Generate Bar Chart")
                            .font(.headline)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 24)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .fullScreenCover(isPresented: $showBarChart) {
                        ZStack {
                            Color.clear
                                .background(.ultraThinMaterial)
                                .ignoresSafeArea()
                            BarChartView(grouped: frozenGroupedByMonth, average: frozenAverage)
                        }
                    }
                    
                }
                
            case .mtsum:
                VStack(spacing: 12) {
                    ForEach(Tag.allCases, id: \.self) { tag in
                        HStack {
                            
                            let calendar = Calendar.current
                            let currentMonth = calendar.component(.month, from: Date())
                            let currentYear = calendar.component(.year, from: Date())

                            let currentMonthTotals: [String: Double] = Dictionary(
                                grouping: transactions.filter {
                                    let comp = calendar.dateComponents([.month, .year], from: $0.date)
                                    return comp.month == currentMonth && comp.year == currentYear
                                },
                                by: { $0.tag }
                            ).mapValues { txns in
                                txns.reduce(0.0) { $0 + $1.price }
                            }

                            let past12MonthsAvg = pastDataSummary()
                            
                            Text(tag.rawValue.capitalized)
                                .frame(width: 120, alignment: .leading)
                            Spacer()
                            Text("$\(String(format: "%.2f", currentMonthTotals[tag.rawValue] ?? 0))")
                                .foregroundColor(.blue)
                            Text("/")
                            Text("$\(String(format: "%.2f", past12MonthsAvg[tag.rawValue] ?? 0))")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .frame(width: 300)
                .padding()
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .onAppear {
            computePieChartData()
            computeBarChartData()
        }
    }
}

// This is the #Preview block for your Statistics view
#Preview {
    Statistics()
}
