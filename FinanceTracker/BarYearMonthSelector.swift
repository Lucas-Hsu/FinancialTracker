//
//  BarYearMonthSelector.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 6/19/25.
//

import Foundation
import SwiftUI

struct BarYearMonthSelector: View {
    @Binding var startDate: Date
    @Binding var endDate: Date

    @State private var selectedStartMonth: Int
    @State private var selectedStartYear: Int
    @State private var selectedEndMonth: Int
    @State private var selectedEndYear: Int

    @Environment(\.dismiss) private var dismiss
    
    private let months = Calendar.current.monthSymbols
    private let years = Array(2000...2100)

    init(startDate: Binding<Date>, endDate: Binding<Date>) {
        self._startDate = startDate
        self._endDate = endDate

        let startComponents = Calendar.current.dateComponents([.year, .month], from: startDate.wrappedValue)
        let endComponents = Calendar.current.dateComponents([.year, .month], from: endDate.wrappedValue)

        _selectedStartMonth = State(initialValue: startComponents.month ?? 1)
        _selectedStartYear = State(initialValue: startComponents.year ?? 2000)

        _selectedEndMonth = State(initialValue: endComponents.month ?? 1)
        _selectedEndYear = State(initialValue: endComponents.year ?? 2000)
    }

    private func validateDates() -> Void {
        if (startDate > endDate) {
            selectedStartYear = selectedEndYear
            selectedStartMonth = selectedEndMonth
        }
        updateEndDate()
        updateStartDate()
    }
    
    private func updateStartDate() {
        if let newStart = Calendar.current.date(from: DateComponents(year: selectedStartYear, month: selectedStartMonth, day: 1)) {
            startDate = newStart
        }
    }

    private func updateEndDate() {
        if let newEnd = Calendar.current.date(from: DateComponents(year: selectedEndYear, month: selectedEndMonth, day: 1)) {
            endDate = newEnd
        }
    }
    
    var body: some View {
        
        VStack(spacing: 32) {
            HStack{
                Text("Select Start Date")
                    .font(.headline)
                    .accentButton()
                
                monthYearPicker(month: $selectedStartMonth, year: $selectedStartYear)
                    .onChange(of: selectedStartMonth) { _ in validateDates() }
                    .onChange(of: selectedStartYear) { _ in validateDates() }
            }
            HStack{
                Text("Select End Date")
                    .font(.headline)
                    .accentButton()
                
                monthYearPicker(month: $selectedEndMonth, year: $selectedEndYear)
                    .onChange(of: selectedEndMonth) { _ in validateDates() }
                    .onChange(of: selectedEndYear) { _ in validateDates() }
            }
            
            if startDate > endDate {
                Text("⚠️ Start date must be earlier than or equal to end date.")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button("Dismiss") {
                validateDates()
                dismiss()
            }
            .accentButton()
        }
        .padding()
        .frame(width: 500)
        .onAppear {
            updateStartDate()
            updateEndDate()
        }
    }

    private func monthYearPicker(month: Binding<Int>, year: Binding<Int>) -> some View {
        HStack {
            Picker("Month", selection: month) {
                ForEach(1...12, id: \.self) { monthIndex in
                    Text(months[monthIndex - 1]).tag(monthIndex)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)

            Picker("Year", selection: year) {
                ForEach(years, id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
        }
        .frame(height: 200)
    }

    
}



#Preview {
    BarYearMonthSelector(startDate: .constant(Date()), endDate: .constant(Calendar.current.date(byAdding: .day, value: 7, to: Date())!))
}
