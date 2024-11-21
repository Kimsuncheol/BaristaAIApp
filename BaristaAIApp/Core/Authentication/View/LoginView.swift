//
//  LoginView.swift
//  BaristaAI
//
//  Created by 김선철 on 9/16/24.
//

import SwiftUI
import FirebaseAuth
import GoogleSignIn
import Firebase
import _AuthenticationServices_SwiftUI
import GoogleSignInSwift

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @FocusState private var isPasswordFieldFocused: Bool
    @StateObject var viewModel = LoginViewModel() // Initialize your view model
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                VStack {
                    InfoTFView(title: "Enter your email", text: $viewModel.email)
                        .padding(.bottom, 36)
                    
                    PasswordTFView(title: "Enter your password", text: $viewModel.password)
                }
                
                NavigationLink {
                    ResetPasswordView()
                } label: {
                    Text("Forgot Password?")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .padding(.top)
                        .padding(.trailing, 28)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                
                Button {
                    Task {
                        try await viewModel.signIn()
                    }
                } label: {
                    Text("Login")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: UIScreen.main.bounds.width - 40, height: 50)
                        .background(Color(.systemBlue))
                        .cornerRadius(8)
                }
                .padding(.vertical)
                
                HStack {
                    Rectangle()
                        .frame(width: (UIScreen.main.bounds.width / 2) - 40, height: 0.5)
                    
                    Text("OR")
                        .font(.footnote)
                        .fontWeight(.semibold)
                    
                    Rectangle()
                        .frame(width: (UIScreen.main.bounds.width / 2) - 40, height: 0.5)
                }
                .foregroundColor(.gray)
                
                VStack(spacing: 26) {
                    Button {
//                        print("continue with google")
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let rootViewController = windowScene.windows.first?.rootViewController {
                            viewModel.signInWithGoogle(presentingViewController: rootViewController)
                        }
                    } label: {
                        HStack() {
                            Image("ios_neutral_sq_na")
                                .resizable()
                                .frame(width: 18, height: 18)
                            
                            Text("Sign in with Google")
                                .font(Font.custom("Roboto-Black", size: 14))
                                .foregroundStyle(.black)
                        }
                        .frame(width: UIScreen.main.bounds.width - 40, height: 40)
                        .overlay (
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 1)
                                
                        )
                    }
                    
//                    SignInWithAppleButton(.signIn,
//                        onRequest: { request in
//                            request.requestedScopes = [.fullName, .email]
//                        },
//                        onCompletion: { result in
//                            switch result {
//                            case .success(let authorization):
//                                viewModel.handleAppleSignIn(result: authorization)
//                            case .failure(let error):
//                                print("Authorization failed: " + error.localizedDescription)
//                            }
//                        }
//                    )
//                    .signInWithAppleButtonStyle(.black)
//                    .frame(width: UIScreen.main.bounds.width - 40, height: 40)
//                    .onTapGesture {
//                        viewModel.startSignInWithAppleFlow()
//                    }
                }
                .padding(.top, 20)
                
                Spacer()
                
                Divider()
                
                NavigationLink {
                    AddEmailView()
                        .navigationBarBackButtonHidden(true)
                } label: {
                    HStack(spacing: 3) {
                        Text("Don't have an account?")
                        Text("Sign Up")
                    }
                    .font(.footnote)
                }
                .padding(.vertical, 16)
            }
            // Make sure you're using the correct `isSignedIn` binding for navigation
            .ignoresSafeArea(.keyboard)
            .alert("Login Failed", isPresented: .constant(viewModel.loginError != nil), presenting: viewModel.loginError) { error in
                Button("OK", role: .cancel) {
                    viewModel.loginError = nil // 에러 초기화
                }
            } message: { error in
                Text(error)
            }
            .navigationDestination(isPresented: $viewModel.isSignedIn) {
                if let user = viewModel.currentUser {
                    MainTabView(user: user)
                        .navigationBarBackButtonHidden(true)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PaymentHistoryViewModel())
//    LoginView()
}
