//
//  RecurringPatternRecognitionTestView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/14/25.
//

import SwiftUI
import SwiftData

struct RecurringPatternRecognitionTestView: View {
    
    struct TestCase: Identifiable {
        let id = UUID()
        let name: String
        let dateStrings: [String]
        let expectedSuccess: Bool // Helper to visualize if we expect a pass or fail
    }
    
    let testCases: [TestCase] = [
        // --- FAILURE CASES (As requested) ---
        TestCase(name: "Fail: Jan 30 Mixed (Not EOM Start)",
                 dateStrings: ["2024-01-30", "2024-02-29", "2024-03-31", "2024-04-30", "2024-05-31"],
                 expectedSuccess: false),
        
        TestCase(name: "Fail: Jan 29 Mixed",
                 dateStrings: ["2024-01-29", "2024-02-29", "2024-03-31", "2024-04-30", "2024-05-31"],
                 expectedSuccess: false),
        
        // --- SUCCESS CASES ---
        TestCase(name: "Success: Valid EOM (Jan 31 Start)",
                 dateStrings: ["2024-01-31", "2024-02-29", "2024-03-31", "2024-04-30", "2024-05-31"],
                 expectedSuccess: true),
        
        TestCase(name: "Success: Valid Standard (Jan 30 Start)",
                 dateStrings: ["2024-01-30", "2024-02-29", "2024-03-30", "2024-04-30", "2024-05-30"],
                 expectedSuccess: true),
        
        TestCase(name: "Success: Leap Year (Feb 29 Start)",
                 dateStrings: ["2024-02-29", "2025-02-28", "2026-02-28", "2027-02-28", "2028-02-29"],
                 expectedSuccess: true),
        
        TestCase(name: "Success: Daily (Every 3 days)",
                 dateStrings: ["2024-01-01", "2024-01-04", "2024-01-07", "2024-01-10", "2024-01-13"],
                 expectedSuccess: true)
    ]
    
    var body: some View {
        NavigationStack {
            List(testCases) { testCase in
                TestCaseRow(testCase: testCase)
            }
            .navigationTitle("Pattern Tests")
        }
    }
}

struct TestCaseRow: View {
    let testCase: RecurringPatternRecognitionTestView.TestCase
    @State private var resultString: String? = nil
    @State private var resultColor: Color = .gray
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(testCase.name)
                    .font(.headline)
                Spacer()
                // Badge showing expected result
                Text(testCase.expectedSuccess ? "Expect PASS" : "Expect FAIL")
                    .font(.caption)
                    .padding(4)
                    .background(testCase.expectedSuccess ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .cornerRadius(4)
            }
            
            // Dates List
            ScrollView(.horizontal) {
                HStack {
                    ForEach(testCase.dateStrings, id: \.self) { date in
                        Text(shortDate(date))
                            .font(.system(.caption2, design: .monospaced))
                            .padding(4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
            
            Divider()
            
            HStack {
                Button(action: runTest) {
                    Text("Run Test")
                        .font(.subheadline)
                        .bold()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Spacer()
                
                if let result = resultString {
                    Text(result)
                        .font(.caption)
                        .foregroundColor(resultColor)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    func runTest() {
        let transactions = createTransactions(from: testCase.dateStrings)
        
        if let recurring = RecurringPatternRecognition.findRecurringTransaction(transactions: transactions) {
            let startStr = recurring.startDate.formatted(date: .abbreviated, time: .omitted)
            resultString = "FOUND: \(recurring.pattern.uppercased()) | Int: \(recurring.interval) | Start: \(startStr)"
            // If we expected success, green. If we expected fail but found one, orange/red.
            resultColor = testCase.expectedSuccess ? .green : .red
        } else {
            resultString = "No Pattern Found"
            // If we expected fail, green (good). If we expected success but failed, red.
            resultColor = testCase.expectedSuccess ? .red : .green
        }
    }
    
    func createTransactions(from strings: [String]) -> [Transaction] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return strings.compactMap { str in
            guard let date = formatter.date(from: str) else { return nil }
            return Transaction(date: date, name: "Test Tx", price: 10.0)
        }
    }
    
    func shortDate(_ str: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: str) {
            return date.formatted(.dateTime.month().day())
        }
        return str
    }
}

#Preview
{
    RecurringPatternRecognitionTestView()
}
