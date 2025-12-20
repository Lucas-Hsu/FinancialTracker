//
//  CalendarView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/16/25.
//

import SwiftUI
import SwiftData

struct CalendarView: View
{
    // MARK: - State Variables
    @State private var viewModel: CalendarViewModel
    @State private var selectedTransaction: Transaction?
    @State private var isSelectedNewTransaction: Bool = true
    @State private var isNewTransactionSheetActivated = false
    @State private var daysWithEvents: [Int] = []
    
    // MARK: - Private Attributes
    private var modelContext: ModelContext
    
    // MARK: - Constructors
    init(modelContext: ModelContext)
    {
        _viewModel = State(initialValue: CalendarViewModel(modelContext: modelContext))
        self.modelContext = modelContext
    }
    
    // MARK: - UI
    var body: some View
    {
        VStack(spacing: 10)
        {
            if #available(iOS 26.0, *)
            {
                calendarView
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
                .shadow(color: Color(hue: 0.58, saturation: 0.5, brightness: 0.5, opacity: 0.1), radius: 4, x: 0, y: 6)
            }
            else
            { calendarView }
            if #available(iOS 26.0, *)
            {
                detailsView
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
                .shadow(color: Color(hue: 0.58, saturation: 0.5, brightness: 0.5, opacity: 0.1), radius: 4, x: 0, y: 6)
            }
            else
            { detailsView }
        }
        .frame(maxWidth: .infinity, minHeight: 700, maxHeight: 700)
        .onAppear
        {
            refresh()
        }
        .fullScreenCover(item: $selectedTransaction)
        { transaction in
            TransactionEditorView(modelContext: modelContext,
                                  isNew: isSelectedNewTransaction,
                                  transaction: transaction)
        }
    }
    
    private var calendarView: some View
    {
        VStack(spacing: 0)
        {
            // MARK: Header
            HStack
            {
                // Prev Month
                CircleIconButtonGlass(icon: "chevron.left", shadow: true)
                {
                    viewModel.previousMonth()
                    updateDaysWithEvents()
                }
                Spacer()
                // Month Year
                Text(DateFormatters.MMMMyyyy(date: viewModel.currentMonth))
                .font(.title3)
                .fontWeight(.semibold)
                .onTapGesture
                { viewModel.resetMonth() }
                Spacer()
                // Next Month
                CircleIconButtonGlass(icon: "chevron.right", shadow: true)
                {
                    viewModel.nextMonth()
                    updateDaysWithEvents()
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
            
            // MARK: Weekdays
            HStack(spacing: 0)
            {
                ForEach(viewModel.weekdays, id: \.self)
                { weekday in
                    Text(weekday)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                }
            }
            
            // MARK: Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 5)
            {
                ForEach(viewModel.getMonthGrid().flatMap { $0 }.indices, id: \.self)
                { index in
                    let day = viewModel.getMonthGrid().flatMap { $0 }[index]
                    if day != 0
                    {
                        CalendarDayCellGlass(day: day.description, toggle: viewModel.isSelectedDay(day), state: viewModel.isToday(day))
                        {
                            if viewModel.isSelectedDay(day)
                            { viewModel.clearSelection() }
                            else
                            { viewModel.selectDay(day) }
                        }
                        .frame(width: 60, height: 40)
                    }
                    else
                    {
                        Rectangle()
                        .fill(Color.clear)
                        .frame(height: 40)
                    }
                }
            }
            .padding(.horizontal, 5)
            .frame(maxWidth: .infinity, minHeight: 300, maxHeight: 300)
        }
        .padding(.vertical)
        .background(.clear)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var detailsView: some View
    {
        VStack(alignment: .leading, spacing: 15)
        {
            if let selectedDay = viewModel.selectedDay
            {
                if viewModel.eventsForSelectedDay.isEmpty
                {
                    ContentUnavailableView("No Events",
                                           systemImage: "calendar",
                                           description: Text("No recurring transactions scheduled for this day"))
                }
                else
                {
                    List
                    {
                        ForEach(viewModel.eventsForSelectedDay)
                        { recurringTransaction in
                            Button(action:
                            {
                                let foundTransaction = viewModel.findTransaction(matches: recurringTransaction,
                                                                                 selectedDate: viewModel.getDateOfDay(selectedDay) ?? Date())
                                selectedTransaction = foundTransaction.keys.first
                                isSelectedNewTransaction = foundTransaction.values.first ?? true
                                isNewTransactionSheetActivated = true
                            })
                            {
                                HStack
                                {
                                    VStack(alignment: .leading, spacing: 4)
                                    {
                                        RecurringTransactionView(recurringTransaction: recurringTransaction)
                                        .shadow(color: Color(hue: 0.58, saturation: 0.5, brightness: 0.5, opacity: 0.1), radius: 4, x: 0, y: 6)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            else
            {
                ContentUnavailableView("Select a Day",
                                       systemImage: "calendar.day.timeline.left",
                                       description: Text("Tap on a day to view scheduled transactions"))
            }
        }
        .background(.clear)
        .cornerRadius(12)
        .padding(.horizontal)
        .frame(maxWidth: .infinity, minHeight: 300, maxHeight: 300)
    }
    
    private func refresh()
    {
        updateDaysWithEvents()
    }
    private func updateDaysWithEvents()
    {
        daysWithEvents = viewModel.getDaysWithEvents()
    }
}
