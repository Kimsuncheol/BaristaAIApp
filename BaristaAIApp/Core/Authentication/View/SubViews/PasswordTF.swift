//
//  PasswordTF.swift
//  BaristaAI
//
//  Created by 김선철 on 9/24/24.
//

import SwiftUI

struct PasswordTFView: View {
    var title: String
    @Binding var text: String
    @FocusState var isActive
    @State var showPassword = false
    var body: some View {
        ZStack(alignment: .leading) {
            SecureField("", text: $text)
                .padding(.leading)
                .frame(width: UIScreen.main.bounds.width - 40, height: 50).focused($isActive)
                .background(.gray.opacity(0.3), in: .rect(cornerRadius: 16))
                .opacity(showPassword ? 0 : 1)
                .autocapitalization(.none)
            
            TextField("", text: $text)
                .padding(.leading)
                .frame(width: UIScreen.main.bounds.width - 40, height: 50).focused($isActive)
                .background(.gray.opacity(0.3), in: .rect(cornerRadius: 16))
                .opacity(showPassword ? 1 : 0)
                .autocapitalization(.none)
            
            Text(title).padding(.leading)
                .offset(y: (isActive || !text.isEmpty) ? -45 : 0)
                .animation(.spring, value: isActive)
                .foregroundStyle(.secondary)
                .onTapGesture {
                    isActive = true
                }
        }
            .overlay(alignment: .trailing) {
                Image(systemName: showPassword ? "eye.fill" : "eye.slash.fill")
                    .padding(16)
                    .contentShape(Rectangle())
                    .foregroundStyle(showPassword ? .primary : .secondary)
                    .onTapGesture {
                        showPassword.toggle()
                    }
            }
        
    }
}

#Preview {
//    PasswordTF()
    ContentView()
}
