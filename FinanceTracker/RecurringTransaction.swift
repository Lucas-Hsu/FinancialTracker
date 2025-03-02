//
//  RecurringTransaction.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 2/25/25.
//

import SwiftData
import Foundation

public struct Events: Hashable {
    var name: String
    var price: Double
    var date: Date
    var tag: Tag
    var intervalType: String
    var interval: Int
    init(name: String, price: Double, date: Date, tag: Tag, intervalType: String, interval: Int) {
        self.name = name
        self.price = price
        self.date = date
        self.tag = tag
        self.intervalType = intervalType
        self.interval = interval
    }
    
    func toString() -> String {
        if intervalType == "Custom" {
            return "\(name); ¥\(price); Started \(date.formatted(.dateTime.year().month(.abbreviated).day(.twoDigits))); Recurs every \(interval) Days"
        } else {
            return "\(name); ¥\(price); Started \(date.formatted(.dateTime.year().month(.abbreviated).day(.twoDigits))); Recurs \(intervalType)"
        }
    }
}

enum TypesOfRecurringTransaction: String, CaseIterable  {
    case Yearly, Monthly, Custom
}
private enum _TypesOfRecurringTransaction: String, CaseIterable  {
    case Yearly, Monthly, Custom, None
}

private struct TransactionPattern: Hashable {
    private var type: _TypesOfRecurringTransaction
    private var interval: Int

    init(type: _TypesOfRecurringTransaction, interval: Int) {
        self.type = type
        self.interval = interval
    }

    public func isValidInterval(_ interval: Int) -> Bool {
        switch self.type {
        case .Yearly:
            return interval >= 1 && interval <= 10
        case .Monthly:
            return interval >= 1 && interval <= 12
        case .Custom:
            return interval >= 1
        default:
            return false
        }
    }

    public func getType() -> TypesOfRecurringTransaction {
        if self.type == .None {
            print("Error: Wrong Type")
            return .Custom
        }
        return TypesOfRecurringTransaction(rawValue: self.type.rawValue)!
    }

    public func get_Type() -> _TypesOfRecurringTransaction {
        return self.type
    }

    public func getInterval() -> Int {
        return self.interval
    }

    public func toString() -> String {
        return "\(self.type.rawValue):\(self.interval)"
    }
    
    
    
    public func hasPattern() -> Bool {
        return self.type != .None && (self.type == .Custom && isValidInterval(self.interval) || self.type != .Custom)
    }

    private func hasSameTypeAndInterval(other: TransactionPattern) -> Bool {
        return self.type == other.type && self.interval == other.interval
    }
}



// Define the Transaction model as a class
@Model class RecurringTransaction {
    @Attribute(.unique) var id: UUID   // Unique identifier
    var date: Date
    var intervalType: String
    var interval: Int
    var name: String
    var tag: String // Storing Enum as String
    var price: Double
    var notes: [String]?  // Optional list of strings
    
    // Provide a custom initializer
    init(date: Date, intervalType: String, interval:Int, name: String, tag: String, price: Double, notes: [String]? = nil) {
        self.id = UUID()
        self.date = date
        self.intervalType = intervalType
        self.interval = interval
        self.name = name
        self.tag = tag
        self.price = price
        self.notes = notes
    }
    
    init() {
        self.id = UUID()
        self.date = Date()
        self.intervalType = "Monthly"
        self.interval = 0
        self.name = ""
        self.tag = Tag.other.rawValue
        self.price = 64.00
        self.notes = nil
    }
    
    public func toString() -> String {
        return "\(name), \(intervalType), \(tag)"
    }
    
    public func verboseDescriptionEvent() -> Events {
        return Events(name: name, price: price, date: date, tag:Tag.init(rawValue: tag) ?? Tag.other, intervalType: intervalType, interval: interval)
    }
    
    public func matchesFilter (tags: Set<String>) -> Bool {
        if (!tags.contains(self.tag)) {
            return false
        }
        return true
    }
    
    public func occursOnDate(date: Date) -> Bool {
        switch intervalType {
        case TypesOfRecurringTransaction.Yearly.rawValue:
                if isExactSameDayAndMonth(date1: date, date2: self.date) {
                    return true
                }
                break
                
        case TypesOfRecurringTransaction.Monthly.rawValue:
                if isExactSameDay(date1: self.date, date2: date){
                    return true
                }
                if canMapDown(dateInitial: self.date, dateNow: date) {
                    return true
                }
                break
                
        default:
            if isDaysAfter(dateInitial: self.date, interval: interval, dateNow: date) {
                return true
            }
            break
        }
        return false
    }
    
    public func occursOnDateButAfter(date: Date, initialDate: Date) -> Bool {
        
        if daysSinceEpoch(date: initialDate) > daysSinceEpoch(date: date) {
            return false
        }
        
        switch intervalType {
        case TypesOfRecurringTransaction.Yearly.rawValue:
                if isExactSameDayAndMonth(date1: date, date2: self.date) {
                    return true
                }
                break
                
        case TypesOfRecurringTransaction.Monthly.rawValue:
                if isExactSameDay(date1: self.date, date2: date){
                    return true
                }
                if canMapDown(dateInitial: self.date, dateNow: date) {
                    return true
                }
                break
                
        default:
            if isDaysAfter(dateInitial: self.date, interval: interval, dateNow: date) {
                return true
            }
            break
        }
        return false
    }
    
    public static func HasRelationship(dates: [Date]) -> Bool {
        var relationships : Set<TransactionPattern> = []
        for i in 1..<dates.count {
            relationships.insert(RelationshipBetween(date1: dates[i], date2: dates[i-1]))
        }
        if relationships.count > 1{
            return false
        }
        if relationships.first == nil {
            return false
        }
        return true
    }
    
    public static func HasRelationship(transactions: [Transaction]) -> Bool {
        if transactions == [] {
            print("Has Relationship : Empty transaction error")
            return false
        }
        var dates: [Date] = []
        for i in 0..<transactions.count {
            dates.append(transactions[i].date)
        }
            return HasRelationship(dates: dates)
        }
    
    public static func PrintRelationship(dates: [Date]) -> String {
        var relationships : [TransactionPattern] = []
        for i in 1..<dates.count {
            relationships.append(RelationshipBetween(date1: dates[i], date2: dates[i-1]))
        }
        for i in 1..<relationships.count {
            if relationships[i] != relationships[i-1] {
                return "No Relationship"
            }
        }
        return relationships[0].toString()
    }
    
    public static func PrintRelationship(transactions: [Transaction]) -> String {
        var dates: [Date] = []
        for i in 0..<transactions.count {
            dates.append(transactions[i].date)
        }
        return PrintRelationship(dates: dates)
    }
    
    public static func matchesPattern(date: Date, pattern: String, initialDate: Date) -> Bool {
        if pattern == "" {
            return false
        }
        if "No Relationship" == pattern {
            return false
        }

        if !dateOccursOnDate(date: date, initialDate: initialDate, type: toType(str: pattern), interval: toInterval(str: pattern)) {
            return false
        }
        return true
    }
    
    private static func dateOccursOnDate(date: Date, initialDate: Date, type: String, interval: Int) -> Bool {
        switch type {
        case TypesOfRecurringTransaction.Yearly.rawValue:
            if isExactSameDayAndMonth(date1: date, date2: initialDate) {
                    return true
                }
                break
                
        case TypesOfRecurringTransaction.Monthly.rawValue:
                if isExactSameDay(date1: initialDate, date2: date){
                    return true
                }
                if canMapDown(dateInitial: initialDate, dateNow: date) {
                    return true
                }
                break
                
        default:
            if isDaysAfter(dateInitial: initialDate, interval: interval, dateNow: date) {
                return true
            }
            break
        }
        return false
    }
}

public func toInterval(str: String) -> Int{
    return Int(str.split(separator: ":").map( {String($0)} )[1]) ?? 0
}

public func toType(str: String) -> String{
    return str.split(separator: ":").map( {String($0)} )[0]
}

private func is31Month(month: Int) -> Bool {
    return month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12
}

private func is31Month(date: Date) -> Bool {
    let components = Calendar.current.dateComponents([.month], from: date)
    let month = components.month!
    return month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12
}

private func is30Month(month: Int) -> Bool {
    return month == 4 || month == 6 || month == 9 || month == 11
}


private func canMapDown(dateInitial: Date, dateNow: Date) -> Bool {
    let componentsInitial = Calendar.current.dateComponents([.year, .month, .day], from: dateInitial)
    let componentsNow = Calendar.current.dateComponents([.year, .month, .day], from: dateNow)
    if componentsInitial.day! < componentsNow.day! {
        return false
    }
    if !isFinalDay(date: dateNow) {
        return false
    }
    return true
}


private func isLeapYear(year: Int) -> Bool {
    if year % 4 == 0 {
        if year % 100 == 0 {
            return year % 400 == 0
        }
        return true
    }
    return false
}

private func isFeb(date: Date) -> Bool {
    let components = Calendar.current.dateComponents([.month], from: date)
    return components.month! == 2
}

private func isFebFinalDay(year: Int, month: Int, day: Int) -> Bool {
    if month != 2 {
        return false
    }
    
    if isLeapYear(year: year) {
        if day != 29 {
            return false }
    } else {
        if day != 28 {
            return false }
    }
    return true
}

private func isFinalDay(year: Int, month: Int, day: Int) -> Bool {
    if is31Month(month: month) {
        if day == 31 {
            return true
        }
    }
    else if is30Month(month: month) {
        if day == 30 {
            return true
        }
    }
    else {
        return isFebFinalDay(year: year, month: month, day: day)
    }
    return false
}

private func isFinalDay(date: Date) -> Bool{
    let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
    return isFinalDay(year:components.year!, month:components.month!, day:components.day!)
}

private func isExactSameDayAndMonth(date1: Date, date2: Date) -> Bool {
    let date1Components = Calendar.current.dateComponents([.month, .day], from: date1)
    let date2Components = Calendar.current.dateComponents([.year, .month, .day], from: date2)
    if date1Components.day! == date2Components.day! && date1Components.month! == date2Components.month! {
        return true
    }
    return false
}

private func isExactSameDay(date1: Date, date2: Date) -> Bool {
    let date1Components = Calendar.current.dateComponents([.day], from: date1)
    let date2Components = Calendar.current.dateComponents([.day], from: date2)
    if date1Components.day! == date2Components.day!{
        return true
    }
    return false
}

private func daysSinceEpoch(date: Date) -> Int {
    let secondsInDay: TimeInterval = 60 * 60 * 24
    let timeInterval = Calendar.current.startOfDay(for: date).timeIntervalSince1970
    return Int(timeInterval / secondsInDay)
}

private func fitsIntoFebruary(dateNow: Date, dateInitial: Date) -> Bool {
    let dateN = Calendar.current.dateComponents([.year, .month, .day], from: dateNow)
    let dateI = Calendar.current.dateComponents([.month, .day], from: dateInitial)
    if dateI.month! == 2 {
        return false
    }
    if isLeapYear(year: dateN.year!) {
        if dateI.day! <= 29 {
            return false
        }
    } else {
        if dateI.day! <= 28 {
            return false
        }
    }
    if !isFinalDay(date: dateNow) {
        return false
    }
    
    return true
}
 
private func isDaysAfter(dateInitial: Date, interval: Int, dateNow: Date) -> Bool{
    let ref = daysSinceEpoch(date: dateInitial)
    let dur = interval
    let tar = daysSinceEpoch(date: dateNow)
    if dur > 0 && (tar - ref)%dur == 0 {
        return true
    }
    return false
}

private func daysAfter(dateInitial: Date, dateNow: Date) -> Int{
    let ref = daysSinceEpoch(date: dateInitial)
    let tar = daysSinceEpoch(date: dateNow)
    return abs(tar - ref)
}


private func RelationshipBetween(date1: Date, date2: Date) -> TransactionPattern {
    let components1 = Calendar.current.dateComponents([.year, .month, .day], from: date1)
    let components2 = Calendar.current.dateComponents([.year, .month, .day], from: date2)
    let sameYear = components1.year! == components2.year!
    let sameMonth = components1.month! == components2.month!
    let sameDay = components1.day! == components2.day! || canMapDown(dateInitial: date1, dateNow: date2) || canMapDown(dateInitial: date2, dateNow: date1)
    
    if !sameYear && sameMonth && sameDay {
        return TransactionPattern(type: .Yearly, interval: 0)
    }
    if !sameMonth && (isExactSameDay(date1: date1, date2: date2) || canMapDown(dateInitial: date1, dateNow: date2) || canMapDown(dateInitial: date2, dateNow: date1)) {
        return TransactionPattern(type: .Monthly, interval: 0)
    }
    let interval = abs(daysSinceEpoch(date: date1) - daysSinceEpoch(date: date2))
    return TransactionPattern(type: .Custom, interval: interval)
}

// the performance that is me
// forever monkeys
