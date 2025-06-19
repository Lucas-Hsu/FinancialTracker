//
//  TransactionCodable.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 6/19/25.
//

import Foundation

struct CodableTransaction: Codable, Identifiable {
    var id: UUID
    var date: Date
    var name: String
    var tag: String
    var price: Double
    var paid: Bool
    var notes: [String]?
    var image: Data?

    init(from transaction: Transaction) {
        self.id = transaction.id
        self.date = transaction.date
        self.name = transaction.name
        self.tag = transaction.tag
        self.price = transaction.price
        self.paid = transaction.paid
        self.notes = transaction.notes
        self.image = transaction.image
    }

    func toModel() -> Transaction {
        let transaction = Transaction(
            date: self.date,
            name: self.name,
            tag: self.tag,
            price: self.price,
            paid: self.paid,
            notes: self.notes,
            image: self.image
        )
        transaction.id = self.id // Manually override the generated UUID
        return transaction
    }
}
