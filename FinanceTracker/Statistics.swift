//
//  Statistics.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 1/31/25.
//

import SwiftUI
import SwiftData

import UIKit

func saveImageToAlbum(_ image: UIImage) {
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
}

extension View {
    func asUIImage(displayScale: CGFloat) -> UIImage {
        let renderer = ImageRenderer(content: self
                                                .background(.white)
                                                .frame(width: 800, height: 600)
                                    )
        renderer.scale = displayScale*2
        if let uiImage = renderer.uiImage {
            return uiImage
        }
        return ImageRenderer(content: Text("Empty")).uiImage!
    }
}

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
            $0.matchesFilter(tags: selectedTags, isUnpaid: isUnpaid)
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
            $0.matchesFilter(tags: Set([selectedBarTag.rawValue]), isUnpaid: isUnpaid)
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
    
    private func computeBarChartData() {
        let groups = Dictionary(grouping: barFilteredTransactions, by: { Calendar.current.component(.year, from: $0.date) * 100 + Calendar.current.component(.month, from: $0.date) })
        let grouped = groups.map { (key, txns) in
            (tag: key, total: txns.reduce(0.0) { $0 + $1.price })
        }
        frozenGroupedByMonth = convertToMonthlyTotal(grouped)
        frozenAverage = barFilteredTransactions.isEmpty ? 0 : barFilteredTransactions.reduce(0.0, { $0 + $1.price }) / Double(barFilteredTransactions.count)

        print(barFilteredTransactions)
        print(frozenGroupedByMonth)
        print(frozenAverage)
        print()
    }
    private func convertToMonthlyTotal(_ input: [(tag: Int, total: Double)]) -> [MonthlyTotal] {
        input.map { MonthlyTotal(tag: $0.tag, total: $0.total) }
    }
    
    enum ChartType: String, CaseIterable, Identifiable {
        case bar = "Bar"
        case mtsum = "Monthly Summary"
        case pie = "Pie"
        var id: String { self.rawValue }
    }
    @State private var selectedChart: ChartType = .bar
    
    @State private var selectedBarTag: Tag = .other
    @State private var showBarDates: Bool = false
    
    @State private var barStart: Date = Date()
    @State private var barEnd: Date = Date()
    
    @State private var scaleEffect: CGFloat = 1.0
    
    var body: some View {
        VStack {
            
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
                VStack(spacing: 16) {
                    VStack {
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
                        
                        VStack{
                            DatePicker("Start Date", selection: $dateStart, displayedComponents: .date)
                            DatePicker("End Date", selection: $dateEnd, displayedComponents: .date)
                        }
                        .frame(width: 500)
                    }
                    .padding()
                    
                    
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
                            Image(systemName: symbolRepresentation[tag] ?? "questionmark")
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
                VStack{
                    HStack{
                        Text("Clothing")
                        Text("current month expenditure")
                        Text("/")
                        Text("past 12 months average (excluding outliers)")
                    }
                    HStack{
                        Text("Commute")
                        Text("current month expenditure")
                        Text("/")
                        Text("past 12 months average (excluding outliers)")
                    }
                    HStack{
                        Text("Education")
                        Text("current month expenditure")
                        Text("/")
                        Text("past 12 months average (excluding outliers)")
                    }
                    HStack{
                        Text("Entertainment")
                        Text("current month expenditure")
                        Text("/")
                        Text("past 12 months average (excluding outliers)")
                    }
                    HStack{
                        Text("Food")
                        Text("current month expenditure")
                        Text("/")
                        Text("past 12 months average (excluding outliers)")
                    }
                    HStack{
                        Text("Other")
                        Text("current month expenditure")
                        Text("/")
                        Text("past 12 months average (excluding outliers)")
                    }
                }
            }
        }
    }
}

// This is the #Preview block for your Statistics view
#Preview {
    Statistics()
}
