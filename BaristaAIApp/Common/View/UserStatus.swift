//
//  UserStatus.swift
//  BaristaAI
//
//  Created by 김선철 on 9/25/24.
//

import Foundation

enum UserStatus: String, Codable {
    case customer
    case manager
    
    func description() -> String {
        switch self {
        case .customer:
            return "Customer"
        case .manager:
            return "Manager"
        }
    }
}
