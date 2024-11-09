//
//  HorizontalDivider.swift
//  BaristaAI
//
//  Created by 김선철 on 9/15/24.
//

import SwiftUI

struct HorizontalDivider: View {
    var width: CGFloat
    var height: CGFloat
    var body: some View {
        Rectangle()
            .frame(width: width, height: height)
            .foregroundColor(Color.gray.opacity(0.3))
    }
}

//#Preview {
//    HorizontalDivider()
//}
