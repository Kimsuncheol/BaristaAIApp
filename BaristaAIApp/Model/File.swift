//
//  File.swift
//  BaristaAIApp
//
//  Created by 김선철 on 9/26/24.
//

import Foundation
import InfinitePaging

struct Page: Pageable {
    var id = UUID()
    var number: Int
}
