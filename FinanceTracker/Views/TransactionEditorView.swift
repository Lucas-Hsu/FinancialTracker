//
//  TransactionEditorView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/11/25.
//

import SwiftUI

struct TransactionEditorView: View
{
    @Environment(\.dismiss) var dismiss
    var body: some View
    {
        ZStack
        {
            ScrollView
            {
            
            }
            
            HStack
            {
                PrimarySaveButtonGlass { print("Save!") }.padding()
                SecondaryCancelButtonGlass { dismiss() }.padding()
                DestructiveDeleteButtonGlass { print("Deleted") }.padding()
            }
        }
    }
}
