//
//  BackupData.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/22/25.
//

import Foundation

struct BackupData: Codable
{
    let transactions: [TransactionCodable]
}
