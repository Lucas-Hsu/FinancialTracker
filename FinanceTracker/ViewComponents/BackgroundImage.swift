//
//  BackgroundImage.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/21/25.
//

import SwiftUI

struct BackgroundImage: View
{
    let image: String
    
    init(_ image: String = "Gradients")
    {
        self.image = image
    }
    
    var body: some View
    {
        ZStack(alignment: .topLeading)
        {
            Image(image)
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            Rectangle()
            .fill(defaultPanelBackgroundColor)
            .scaledToFill()
            .opacity(0.7)
        }
    }
}
