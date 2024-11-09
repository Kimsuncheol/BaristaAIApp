//
//  Checkbox.swift
//  BaristaAI
//
//  Created by 김선철 on 9/24/24.
//

import SwiftUI

struct CheckBoxView: View {
    @Binding var isChecked: Bool
    var text: String

    var body: some View {
        HStack {
            Button(action: {
                isChecked.toggle()
            }) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .foregroundColor(isChecked ? .blue : .gray)
                    .font(.system(size: 24))
            }
            .buttonStyle(PlainButtonStyle()) // Remove button tap animation
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}
