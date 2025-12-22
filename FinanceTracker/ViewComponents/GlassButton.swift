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

struct TintedLabelButton: View
{
    let imageSystemName: String
    let text: String
    let tint: Color
    let color: Color
    var action: () -> Void
    
    var body: some View
    {
        Button(action: action)
        {
            HStack
            {
                Image(systemName: imageSystemName)
                .foregroundStyle(color)
                Text("Take Photo")
                .foregroundStyle(color)
            }
        }
        .controlSize(.large)
        .buttonStyle(.borderedProminent)
        .clipShape(Capsule())
        .tint(tint)
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
        .tint(Color.accentColor)
    }
}
struct SecondaryButton: View
{
    let title: String
    var action: () -> Void
    
    var body: some View
    {
        BaseButton(title: title, action: action)
        .tint(Color.white)
        .foregroundColor(Color.accentColor)
    }
}
struct DestructiveButton: View
{
    let title: String
    var action: () -> Void
    
    var body: some View
    {
        BaseButton(title: title, action: action)
        .tint(Color.red)
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
struct SecondaryButtonGlass: View
{
    let title: String
    var action: () -> Void
    var body: some View
    {
        if #available(iOS 26.0, *)
        { SecondaryButton(title: title, action: action).glassEffect(.regular.interactive()) }
        else
        { SecondaryButton(title: title, action: action) }
    }
}
struct DestructiveButtonGlass: View
{
    let title: String
    var action: () -> Void
    var body: some View
    {
        if #available(iOS 26.0, *)
        { DestructiveButton(title: title, action: action).glassEffect(.regular.interactive()) }
        else
        { DestructiveButton(title: title, action: action) }
    }
}
struct TintedLabelButtonGlass: View
{
    let imageSystemName: String
    let text: String
    let tint: Color
    let color: Color
    var action: () -> Void
    
    var body: some View
    {
        if #available(iOS 26.0, *)
        {
            TintedLabelButton(imageSystemName: self.imageSystemName, text: self.text, tint: self.tint, color: self.color, action: self.action)
            .glassEffect(.regular.interactive())
        }
        else
        { TintedLabelButton(imageSystemName: self.imageSystemName, text: self.text, tint: self.tint, color: self.color, action: self.action) }
    }
}
