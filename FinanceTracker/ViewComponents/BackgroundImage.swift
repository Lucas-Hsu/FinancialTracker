//
//  BackgroundImage.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/21/25.
//

import SwiftUI

struct BackgroundImage: View
{
    let image: String = "iPad26Background"
    
    var body: some View
    {
        ZStack
        {
            Image(image)
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            Rectangle()
            .fill(defaultPanelBackgroundColor)
            .scaledToFit()
            .opacity(0.7)
        }
    }
}
