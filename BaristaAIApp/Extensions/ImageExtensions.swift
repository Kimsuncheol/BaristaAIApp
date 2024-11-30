//
//  ViewExtensions.swift
//  BaristaAIApp
//
//  Created by 김선철 on 11/30/24.
//

import Foundation
import SwiftUI

extension View {
    func drinkCardImageStyleInChat() -> some View {
        self
            .resizable()
            .frame(width: .recommendedDrinkCardSideLength, height: .recommendedDrinkCardSideLength)
            .cornerRadius(8)
    }
    
}
