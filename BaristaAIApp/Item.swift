//
//  Item.swift
//  BaristaAIApp
//
//  Created by 김선철 on 9/26/24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
