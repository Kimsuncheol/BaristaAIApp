//
//  UpdatePasswordView.swift
//  BaristaAIApp
//
//  Created by 김선철 on 10/4/24.
//

import SwiftUI

struct UpdatePasswordView: View {
    @StateObject var viewModel = ContentViewModel()
    @StateObject var registrationViewModel = RegistrationViewModel()
    var currentUser: User? {
        viewModel.currentUser
    }
    @State private var password = ""
    @Environment(\.dismiss) var dismiss
    @FocusState var isPasswordCreatingActive
    @State private var checkMinChars = false
    @State private var checkLetter = false
    @State private var checkPunctuation = false
    @State private var checkNumber = false
    
    @State private var showPassword = false
    @State private var isNextActive = false
    
    var progressColor: Color {
        let containsLetters = password.rangeOfCharacter(from: .letters) != nil
        let containsNumbers = password.rangeOfCharacter(from: .decimalDigits) != nil
        let containsPunctuation = password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#%^&$")) != nil
        
        if containsLetters && containsNumbers && containsPunctuation && password.count >= 8 {
            return Color.green
        } else if containsLetters && !containsNumbers && !containsPunctuation {
            return Color.red
        } else if containsNumbers && !containsLetters && !containsPunctuation {
            return Color.red
        } else if containsLetters  && containsNumbers && !containsPunctuation {
            return Color.yellow
        } else if containsLetters && containsNumbers && containsPunctuation {
            return Color.blue
        } else {
            return .gray
        }
    }
    
    private var isEnabledNext: Bool {
        return checkLetter && checkNumber && checkPunctuation && checkMinChars
    }
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text("Update password")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Your must be at least 6 characters in length")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.bottom, 30)
            
            VStack(alignment: .leading, spacing: 24) {
                ZStack(alignment: .leading) {
                    ZStack {
                        SecureField("", text: $password)
                            .padding(.leading)
                            .frame(width: UIScreen.main.bounds.width - 40, height: 50).focused($isPasswordCreatingActive)
                            .background(.gray.opacity(0.3), in:  .rect(cornerRadius: 16))
                            .opacity(showPassword ? 0 : 1)
                        TextField("", text: $password)
                            .padding(.leading)
                            .frame(width: UIScreen.main.bounds.width - 40, height: 50).focused($isPasswordCreatingActive)
                            .background(.gray.opacity(0.3), in:  .rect(cornerRadius: 16))
                            .opacity(showPassword ? 1 : 0)
                    }
                    Text("Password").padding(.horizontal)
                        .offset(y: (isPasswordCreatingActive || !password.isEmpty) ? -50 : 0)
                        .foregroundStyle(isPasswordCreatingActive ? .primary : .secondary)
                        .animation(.spring, value: isPasswordCreatingActive)
                        .onTapGesture {
                            isPasswordCreatingActive = true
                        }
                        .onChange(of: password, { oldValue, newValue in
                            withAnimation {
                                checkMinChars = newValue.count >= 8
                                checkLetter = newValue.rangeOfCharacter(from: .letters) != nil
                                checkNumber = newValue.rangeOfCharacter(from: .decimalDigits) != nil
                                checkPunctuation = newValue.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#%^&$")) != nil
                            }
                        })
                }
                .overlay(alignment: .trailing) {
                    Image(systemName: showPassword ? "eye.fill" : "eye.slash.fill")
                        .foregroundStyle(showPassword ? .primary : .secondary)
                        .padding(16)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showPassword.toggle()
                        }
                }
                VStack(alignment: .leading, spacing: 10) {
                    CheckText(text: "Minimum 8 characters", check: $checkMinChars)
                    CheckText(text: "At least one letter", check: $checkLetter)
                    CheckText(text: "(!@#$%*^&)", check: $checkPunctuation)
                    CheckText(text: "Number", check: $checkNumber)
                }
            }
            
            Spacer()
            
            Button {
                if isEnabledNext {
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
                    .background(isEnabledNext ? Color(.blue) : Color(.gray))
                    .cornerRadius(8)
            }
            .padding(.vertical)
        }
        .navigationDestination(isPresented: $isNextActive) {
            MainTabView(user: currentUser ?? nil)
        }
    }
}

#Preview {
//    UpdatePasswordView()
}
