//
//  Suggestions.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 2/24/25.
//

import SwiftUI
import SwiftData

struct Suggestions: View {
    
    @Query(sort: \Transaction.price, order: .forward) var transactions: [Transaction]
    
    func checkSuggestions(price: Double) -> Transaction {
        let similarTransations: [Transaction] = transactions.filter {transation in abs(transation.price - price) < 10
        }
        if !similarTransations.isEmpty {
            return similarTransations.randomElement() ?? Transaction()
        }
        return Transaction()
    }
    
    var body: some View {
        Text("Suggestions")
    }
}

#Preview {
    Suggestions()
}
