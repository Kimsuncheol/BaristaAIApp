//
//  ResetPasswordView.swift
//  BaristaAI
//
//  Created by 김선철 on 9/16/24.
//

import SwiftUI
@preconcurrency import WebKit
import FirebaseFirestore
import FirebaseAuth

struct ResetPasswordView: View {
    @State private var email = ""
    @State private var isValidEmail: Bool = false
    @State private var emailExists: Bool? = nil // 이메일 존재 여부
    @State private var isChecking: Bool = false // 확인 중인지 상태
    @State private var showWebView: Bool = false // 웹뷰 표시 여부
    @State private var domainURL: URL? = nil // 도메인 URL
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            /// 이메일 입력
            InfoTFView(title: "Enter your email", text: $email)
                .padding(.horizontal, 20)
                .onChange(of: email) {
                    validateEmail(email)
                }
            
            // 이메일 입력했으나 이메일 형식 검증 실패시
            VStack {
                if !email.isEmpty {
                    if !isValidEmail {
                        Text("Invalid email format")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(.leading, 20)
                    }
                }
                
                if let emailExists = emailExists {
                    Text(emailExists ? "Email exists in the system." : "Email not found.")
                        .font(.system(size: 14))
                        .foregroundColor(emailExists ? .green : .red)
                        .padding(.leading, 20)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 20)
            
            
            // customer 컬렉션에 해당 이메일이 있는지 확인하는 버튼 구현
            Button {
                isChecking = true // 확인 중 상태로 전환
                checkIfEmailExists(email) { exists in
                    isChecking = false // 확인 완료
                    emailExists = exists
                    if exists {
                        // 이메일이 존재하면 비밀번호 재설정 이메일을 보냄
                        Auth.auth().sendPasswordReset(withEmail: email) { error in
                            if let error = error {
                                print("Error sending password reset email: \(error.localizedDescription)")
                            } else {
                                print("Password reset email sent successfully")
                            }
                        }
                    }
                }
            } label: {
                Text(isChecking ? "Checking..." : "Check Email")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: UIScreen.main.bounds.width - 40, height: 50)
                    .background(isChecking ? Color.gray : Color.blue)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 20)
            .disabled(isChecking || email.isEmpty || !isValidEmail)
            
            Spacer()
        }
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert(isPresented: Binding<Bool>(
            get: { emailExists ?? false }, // 옵셔널 해제하여 기본값 false 설정
            set: { emailExists = $0 ? true : nil } // 상태에 따라 값 설정
        )) {
            Alert(
                title: Text("Email Exists"),
                message: Text("The email exists in the system."),
                dismissButton: .default(Text("OK")) {
                    if let domain = extractDomain(from: email) {
                        if let domainURL = URL(string: "https://\(domain)") {
                            openSafari(url: domainURL)
                            dismiss()
                        }
                    }
                }
            )
        }
    }
    
    /// I need to implement the email regex validation here
    // 이메일 정규식 검증
    func validateEmail(_ email: String) {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        isValidEmail = emailPredicate.evaluate(with: email)
    }
    
    // Firestore의 customer 컬렉션에 해당 이메일이 있는지 확인하는 함수
    func checkIfEmailExists(_ email: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("customer")
            .whereField("email", isEqualTo: email)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error checking email existence: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                if let documents = snapshot?.documents, !documents.isEmpty {
                    completion(true)
                } else {
                    completion(false)
                }
            }
    }
    
    // 이메일에서 도메인 추출
    func extractDomain(from email: String) -> String? {
        guard let atIndex = email.firstIndex(of: "@") else { return nil }
        let domain = email[email.index(after: atIndex)...]
        return String(domain)
    }
    
    // 사파리 브라우저에서 URL 열기
    func openSafari(url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

#Preview {
//    ResetPasswordView()
}
