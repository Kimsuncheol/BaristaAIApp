//
//  AddEmailView.swift
//  BaristaAI
//
//  Created by 김선철 on 9/16/24.
//

import SwiftUI

extension String {
    var isEmailValid: Bool {
//        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: self)
    }
}

struct AddEmailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: RegistrationViewModel
    @State private var isNextActive = false     // To control the navigation manually
    @State private var showEmailError = false   // To show email validation error message
    @State private var showDuplicateError = false // To show duplicate email error message
    @FocusState var isFocused
    
    var body: some View {
        VStack(spacing: 60) {
            TopView(title: "Add your email", details: "You'll use this email to sign in to your account")
            
            InfoTFView(title: "Email", text: $viewModel.email)
                .focused($isFocused)
                .keyboardType(.emailAddress)
            
            if showEmailError {
                Text("Please enter a valid email address.")
                   .font(.caption)
                   .foregroundColor(.red)
            }
            
            if showDuplicateError {
                Text("This email is already in use. Please use a different email.")
                    .font(.caption)
                    .foregroundColor(.red)
            }
                        
            
            Button {
                Task {
                    if viewModel.email.isEmailValid {
                        showEmailError = false
                        let isDuplicate = await viewModel.isEmailDuplicate(email: viewModel.email)
                        if !isDuplicate {
                            showDuplicateError = false
                            isNextActive = true
                        } else {
                            showDuplicateError = true
                        }
                    } else {
                        showEmailError = true
                    }
                }
            } label: {
                Text("Next")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: UIScreen.main.bounds.width - 40, height: 50)
                    .background(viewModel.email.isEmailValid ? Color(.systemBlue) : Color(.gray))
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .onTapGesture {
            isFocused = false
        }
        .padding(.horizontal)
        .navigationDestination(isPresented: $isNextActive) {
            CreateUsernameView()
        }
    }
}

#Preview {
//    AddEmailView(userStatus: UserStatus.customer, email: .constant(""))
}
