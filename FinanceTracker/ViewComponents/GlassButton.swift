//
//  GlassButton.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/11/25.
//

import SwiftUI

// MARK: - Primitive Shapes
struct BaseButton: View
{
    let title: String
    var action: () -> Void
    
    var body: some View
    {
        Button(title, action: action)
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .clipShape(Capsule())
    }
}

// MARK: - Templates
struct PrimaryButton: View
{
    let title: String
    var action: () -> Void
    
    var body: some View
    {
        BaseButton(title: title, action: action)
            .tint(.accentColor)
    }
}
struct PrimarySaveButton: View
{
    let title: String = "Save"
    var action: () -> Void
    
    var body: some View
    {
        BaseButton(title: title, action: action)
            .tint(.accentColor)
    }
}
struct SecondaryCancelButton: View
{
    let title: String = "Cancel"
    var action: () -> Void
    
    var body: some View
    {
        BaseButton(title: title, action: action)
            .tint(Color(.white))
            .foregroundColor(.accentColor)
    }
}
struct DestructiveDeleteButton: View
{
    let title: String = "Delete"
    var action: () -> Void
    
    var body: some View
    {
        BaseButton(title: title, action: action)
            .tint(.red)
    }
}

// MARK: - Liquid Glass Themed
struct PrimaryButtonGlass: View
{
    let title: String
    var action: () -> Void
    var body: some View
    {
        if #available(iOS 26.0, *)
        { PrimaryButton(title: title, action: action).glassEffect(.regular.interactive()) }
        else
        { PrimaryButton(title: title, action: action) }
    }
}
struct PrimarySaveButtonGlass: View
{
    let title: String = "Save"
    var action: () -> Void
    var body: some View
    {
        if #available(iOS 26.0, *)
        { PrimarySaveButton(action: action).glassEffect(.regular.interactive()) }
        else
        { PrimarySaveButton(action: action) }
    }
}
struct SecondaryCancelButtonGlass: View
{
    let title: String = "Save"
    var action: () -> Void
    var body: some View
    {
        if #available(iOS 26.0, *)
        { SecondaryCancelButton(action: action).glassEffect(.regular.interactive()) }
        else
        { SecondaryCancelButton(action: action) }
    }
}
struct DestructiveDeleteButtonGlass: View
{
    let title: String = "Save"
    var action: () -> Void
    var body: some View
    {
        if #available(iOS 26.0, *)
        { DestructiveDeleteButton(action: action).glassEffect(.regular.interactive()) }
        else
        { DestructiveDeleteButton(action: action) }
    }
}
