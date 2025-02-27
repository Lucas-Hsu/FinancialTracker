//
//  RecurringTransaction.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 2/25/25.
//

import SwiftData
import Foundation

enum TypesOfRecurringTransaction: String, CaseIterable  {
    case Yearly, Monthly, Custom
}
private enum _TypesOfRecurringTransaction: String, CaseIterable  {
    case Yearly, Monthly, Custom, None
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
    
    public static func HasRelationship(dates: [Date]) -> Bool {
        var relationships : Set<_TypesOfRecurringTransaction> = []
        for i in 1..<dates.count {
            relationships.insert(RelationshipBetween(date1: dates[i], date2: dates[i-1]))
        }
        if relationships.count > 1{
            return false
        }
        if relationships.first! == .None {
            return false
        }
        return true
    }
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


private func RelationshipBetween(date1: Date, date2: Date) -> _TypesOfRecurringTransaction {
    let components1 = Calendar.current.dateComponents([.year, .month, .day], from: date1)
    let components2 = Calendar.current.dateComponents([.year, .month, .day], from: date2)
    let sameYear = components1.year! == components2.year!
    let sameMonth = components1.month! == components2.month!
    let sameDay = components1.day! == components2.day! || canMapDown(dateInitial: date1, dateNow: date2) || canMapDown(dateInitial: date2, dateNow: date1)
    
    if !sameYear && sameMonth && sameDay {
        return .Yearly
    }
    if !sameMonth && (isExactSameDay(date1: date1, date2: date2) || canMapDown(dateInitial: date1, dateNow: date2) || canMapDown(dateInitial: date2, dateNow: date1)) {
        return .Monthly
    }
    return .Custom
}
// the performance that is me
// forever monkeys
