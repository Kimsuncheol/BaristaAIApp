//
//  InfoTF.swift
//  BaristaAI
//
//  Created by 김선철 on 9/23/24.
//

import SwiftUI

struct InfoTFView: View {
    var title: String
    @Binding var text: String
    @FocusState var isFocused
    
    var body: some View {
        ZStack(alignment: .leading) {
            TextField("", text: $text)
                .padding(.leading)
                .frame(width: UIScreen.main.bounds.width - 40, height: 50)
                .focused($isFocused)
                .background(.gray.opacity(0.3), in: .rect(cornerRadius: 12))
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            Text(title)
                .padding(.leading)
                .offset(y: (isFocused || !text.isEmpty) ? -45 : 0)
                .animation(.spring, value: isFocused)
                .foregroundStyle(.secondary)
                .onTapGesture {
                    isFocused = true
                }
        }
        .animation(.spring(), value: isFocused || !text.isEmpty)
    }
}
