//
//  CompleteSignUpView.swift
//  BaristaAI
//
//  Created by 김선철 on 9/24/24.
//

import SwiftUI

struct CompleteSignUpView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: RegistrationViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            
            Text("Welcome to BaristaAI!")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Button {
//                Task { try await viewModel.createUser() }
                if !viewModel.email.isEmpty && !viewModel.password.isEmpty &&
                    !viewModel.username.isEmpty && !viewModel.nickname.isEmpty {
                    
                    Task { try await viewModel.createUser() }
                } else {
                    print("DEBUG: Missing fields - please fill all fields before continuing.")
                }
            } label: {
                Text("Complete sign Up")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 360, height: 44)
                    .background(Color(.systemBlue))
                    .cornerRadius(8)
            }
            .padding(.vertical)
            
            Spacer()
        }
    }
}

#Preview {

}
