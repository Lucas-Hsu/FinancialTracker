//
//  Timestep.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/23/25.
//

enum Timestep: String, CaseIterable, Identifiable
{
    var id: String { self.rawValue }
    case months = "Months"
    case years = "Years"
}
