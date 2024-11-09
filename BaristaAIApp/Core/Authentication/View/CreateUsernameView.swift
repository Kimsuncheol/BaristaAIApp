//
//  AddUsernameView.swift
//  BaristaAI
//
//  Created by 김선철 on 9/16/24.
//

import SwiftUI

struct CreateUsernameView: View {
    @State private var isNextActive = false     // To control the navigation manually
    @State private var showUsernameError = false // To show empty username error
    @FocusState var isUsernameFocused
    @EnvironmentObject var viewModel: RegistrationViewModel
    
    var body: some View {
        VStack(spacing: 60) {
            TopView(title: "Add your username", details: "You'll see your name while using this app")
            
            InfoTFView(title: "Name", text: $viewModel.username, isFocused: _isUsernameFocused)
            
            if showUsernameError {
                Text("Please enter a valid username.")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Button {
                if !viewModel.username.isEmpty {
                    isNextActive = true
                } else {
                    isNextActive = false
                }
            } label: {
                Text("Next")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: UIScreen.main.bounds.width - 40, height: 50)
                    .background(!viewModel.username.isEmpty ? Color(.systemBlue) : Color(.gray))
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .navigationDestination(isPresented: $isNextActive) {
            CreatePasswordView().navigationBarBackButtonHidden()
        }
    }
}

#Preview {
    CreateUsernameView()
}
