//
//  EmailAuthView.swift
//  BaristaAI
//
//  Created by 김선철 on 9/25/24.
//

import SwiftUI
import FirebaseAuth

struct EmailVerificationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isVerified: Bool = false
    @State var isClickedSendBtn: Bool = false
    @State private var navigateToChangePassword: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Email Verification")
                .font(.largeTitle)
                .padding()
            
            Text("After receiving the verification email, please click the link to verify your email address.")
            
            Image(systemName: "envelope.open.badge.clock")
                .resizable()
                .frame(width: 100, height: 100)
            
            Button {
                sendVerificationEmail()
            } label: {
                Text("Send Verification Email")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Button {
                
            } label: {
                VStack {
                    Text("Verify")
                        .frame(maxWidth: .infinity)
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .padding(.vertical, 15)
                        .background(isClickedSendBtn ? Color.blue : Color.black.opacity(0.25))
                        .cornerRadius(8)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    func sendVerificationEmail() {
        guard let user = Auth.auth().currentUser else { return }
        
        user.sendEmailVerification { error in
            if let error = error {
                print("Error sending verification email: \(error.localizedDescription)")
            } else {
                isClickedSendBtn = true
                print("Verition email sent successfully!")
            }
        }
    }
    
    func checkEmailVerification() {
        guard let user = Auth.auth().currentUser else { return }
        
        user.reload { error in
            if let error = error {
                print("Error reloading user: \(error.localizedDescription)")
            } else {
                isVerified = user.isEmailVerified
                if isVerified {
                    print("User is verified!")
                } else {
                    print("User is not verified!")
                }
            }
        }
    }
}

#Preview {
    EmailVerificationView()
}
