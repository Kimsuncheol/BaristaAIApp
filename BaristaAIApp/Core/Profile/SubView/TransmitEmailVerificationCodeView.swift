//
//  TransmitEmailVerificationCodeView.swift
//  BaristaAIApp
//
//  Created by 김선철 on 10/4/24.
//

import SwiftUI
import FirebaseAuth

struct TransmitEmailVerificationCodeView: View {
    var previousViewName: String
    @State var password: String = ""
    @State var isVerified: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    var buttonWidth = UIScreen.main.bounds.width - 40
    
    var body: some View {
        VStack(spacing: 40) {
            VStack(alignment: .leading, spacing: 20) {
                // user email
                Text("Email : user email")
                    .font(.headline.bold())
                
                Text("To make sure that you update your \(previousViewName == "password" ? "password" : "nickname"), you need to get a verification code from your email.")
            }
            
            // NavigationLink to navigate to the appropriate view based on previousViewName
            
            Button {
                sendVerificationCode()
            } label: {
                Text("Send Verification Code")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
            }
            .frame(width: buttonWidth, height: 50)
            .background(Color.blue.opacity(0.8))
            .cornerRadius(10)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Notification"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            
            Spacer()
        }
        .padding()
        .navigationDestination(isPresented: $isVerified) {
            previousViewName == "password" ? AnyView(PasswordUpdateView()) : AnyView(NicknameUpdateView())
        }
    }
    
    func sendVerificationCode() {
        guard let user = Auth.auth().currentUser else {
            alertMessage = "User not logged in."
            showAlert = true
            return
        }
        
        user.sendEmailVerification { error in
            if let error = error {
                alertMessage = "Failed to send verification code: \(error.localizedDescription)"
                showAlert = true
            } else {
                alertMessage = "Verification code has been sent to your email."
                showAlert = true
                isVerified = true  // Trigger the NavigationLink
                openEmailApp()
            }
        }
    }
    
    func openEmailApp() {
        if let url = URL(string: "message://") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                alertMessage = "No email app is available."
                showAlert = true
            }
        }
    }
}

// Placeholder Views for Nickname and Password update
struct NicknameUpdateView: View {
    var body: some View {
        Text("Nickname Update View")
    }
}

struct PasswordUpdateView: View {
    var body: some View {
        Text("Password Update View")
    }
}

#Preview {
    TransmitEmailVerificationCodeView(previousViewName: "")
}
