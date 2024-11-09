//
//  CreateNicknameView.swift
//  BaristaAI
//
//  Created by 김선철 on 9/23/24.
//

import SwiftUI

struct CreateNicknameView: View {
    @State var isNextActive = false
    @State private var showNicknameError = false // To show empty nickname error
    @State private var showDuplicateError = false // To show duplicate nickname error
    @EnvironmentObject var viewModel: RegistrationViewModel
    
    var body: some View {
        VStack {
            TopView(title: "Add your nickname", details: "")
                .padding(.bottom, 20)
         
            InfoTFView(title: "Nickname", text: $viewModel.nickname)
                .padding(.bottom, 16)
            
            if showNicknameError {
                Text("Please enter a valid nickname.")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            if showDuplicateError {
                Text("This nickname is already in use. Please choose a different nickname.")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            CheckBoxView(isChecked: $viewModel.useNickname, text: "I'll use this nickname while using this app")
            
            Spacer()
            
            Button {
                Task {
                    if !viewModel.nickname.isEmpty {
                        showNicknameError = false
                        let isDuplicate = await viewModel.isNicknameDuplicate(nickname: viewModel.nickname)
                        if !isDuplicate {
                            showDuplicateError = false
                            isNextActive = true
                        } else {
                            showDuplicateError = true
                        }
                    } else {
                        showNicknameError = true
                    }
                }
            } label: {
                Text("Next")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: UIScreen.main.bounds.width - 40, height: 50)
                    .background(Color(.blue))
                    .cornerRadius(8)
            }
        }
        .padding()
        .navigationDestination(isPresented: $isNextActive) {
            CompleteSignUpView()
        }
    }
}

#Preview {
//    CreateNicknameView()
}
