//
//  RecordsListView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/11/25.
//

import SwiftUI

struct RecordsListView: View
{
    @State private var isShowingTransactionEditorSheet = false
    var body: some View
    {
        VStack
        {
            Button(action:
            {
                isShowingTransactionEditorSheet = true
            })
            {
                Text("Save")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            Text("List")
        }
        .fullScreenCover(isPresented: $isShowingTransactionEditorSheet)
        {
            TransactionEditorView()
        }
    }
}
