//
//  PriceFormatter.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/10/25.
//

import Foundation

/// Numerical prices (e.g. 13.1) into formatted string prices (e.g. "13.10") and parsing formatted strings back to Double.
public class PriceFormatter
{
    // For converting numerical price values to properly formatted string
    private static let priceFormatter: NumberFormatter =
    {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    // A copy of the formatter for direct access
    public static var formatter: NumberFormatter
    {
        let tempCopiedObject = priceFormatter.copy()
        guard let formatterCopy = tempCopiedObject as? NumberFormatter
        else
        {
            print("[ERROR] Copied formatter failed cast to NumberFormatter.")
            return priceFormatter
        }
        return formatterCopy
    }
    
    public static func format(price: Double) -> String
    {
        let number = NSNumber(value: price)
        if let formattedString = priceFormatter.string(from: number)
        { return formattedString }
        else
        { return "nan" }
    }
    
    public static func parse(string: String) -> Double?
    {
        guard let number = priceFormatter.number(from: string)
        else
        { return nil }
        return number.doubleValue
    }
    
    // For converting numerical price values to properly formatted string of 1 decimal place
    private static let priceFormatter1D: NumberFormatter =
    {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    public static func format1D(price: Double) -> String
    {
        let number = NSNumber(value: price)
        if let formattedString = priceFormatter1D.string(from: number)
        { return formattedString }
        else
        { return "nan" }
    }
}
