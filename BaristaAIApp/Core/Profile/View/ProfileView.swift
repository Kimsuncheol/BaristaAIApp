//
//  ProfileView.swift
//  BaristaAI
//
//  Created by 김선철 on 9/25/24.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    let user: User?
    @Environment(\.dismiss) var dismiss
    @State private var password: String = "" // 유의
    @State private var showDeleteAccountSheet: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var navigateToLoginView: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section("Account Information") {
                    NavigationLink(destination: TransmitEmailVerificationCodeView(previousViewName: "nickname")) {
                        HStack {
                            Text("Nickname")
                            Spacer()
                            Text(Auth.auth().currentUser?.displayName ?? "")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(Auth.auth().currentUser?.email ?? "")
                            .foregroundColor(.gray)
                    }
                }
                
                Section("Account Security") {
                    NavigationLink(destination: TransmitEmailVerificationCodeView(previousViewName: "password")) {
                        Text("Update Password")
                    }
                }
                
                Section("Payment") {
                    Text("Change Payment")
                    NavigationLink(destination: PaymentHistoryView()) {
                        Text("Payment History")
                    }
                }
                
                Section {
                    Button("Sign out") {
                        signOut()
                    }
                    .foregroundStyle(.red)
                }
                
                Section {
                    Button("Delete Account") {
                        showDeleteAccountSheet = true
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .padding(.vertical)
        .sheet(isPresented: $showDeleteAccountSheet) {
            DeleteAccountSheet(
                password: $password, showError: $showError, errorMessage: $errorMessage, onCancel: { showDeleteAccountSheet = false }, onDelete: { deleteAccount() }
            )
        }
    }
    func signOut() {
        AuthService.shared.signout()
        //            try Auth.auth().signOut()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if Auth.auth().currentUser == nil {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController = UIHostingController(rootView: ContentView())
                    window.makeKeyAndVisible()
                }
            } else {
                print("로그아웃 실패: 사용자 세션이 여전히 존재합니다.")
            }
        }
    }
    
    func deleteAccount() {
        guard let user = Auth.auth().currentUser else { return }
        
        print("-------- profile view delete Account method --------")
        
        // 사용자가 입력한 비밀번호를 사용하여 자격 증명 생성
        let credential = EmailAuthProvider.credential(withEmail: user.email ?? "", password: password)

        user.reauthenticate(with: credential) { result, error in
            if let error {
                print("Reauthentication failed: \(error.localizedDescription)")
                return
            }
            
            user.delete { error in
                if let error {
                    print("Error deleting user: \(error.localizedDescription)")
                } else {
                    do {
                        try Auth.auth().signOut()
                        DispatchQueue.main.async {
                            dismiss()
                        }
                    } catch let signOutError as NSError {
                        print("Error signing out: \(signOutError.localizedDescription)")
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

struct DeleteAccountSheet: View {
    @Binding var password: String
    @Binding var showError: Bool
    @Binding var errorMessage: String
    var onCancel: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Delete Account")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("Please enter your password to confirm account deletion. This action cannot be undone.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            SecureField("Enter your password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .padding(.top, -10)
            }

            HStack(spacing: 20) {
                Button(action: onCancel) {
                    Text("Cancel")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                
                Button(action: onDelete) {
                    Text("Delete")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}
