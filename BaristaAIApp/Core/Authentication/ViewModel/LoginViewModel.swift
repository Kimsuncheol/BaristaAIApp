//
//  LoginViewModel.swift
//  BaristaAI
//
//  Created by 김선철 on 9/16/24.
//

import FirebaseAuth
import Combine
import GoogleSignIn
import Firebase
import AuthenticationServices
import CryptoKit

class LoginViewModel: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    @Published var email = ""
    @Published var password = ""
    @Published var isSignedIn: Bool = false
    @Published var currentUser: User?  // Track the current user
    
    fileprivate var currentNonce: String?

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Adjust this to return the correct window if using SwiftUI
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.windows.first { $0.isKeyWindow }!
        }
        fatalError("No key window found")
    }
    
    func signIn() async throws {
        do {
            try await AuthService.shared.login(withEmail: email, password: password)
            
            if let user = Auth.auth().currentUser {
                DispatchQueue.main.async {
                    self.currentUser = User(
                        id: user.uid,
                        username: user.displayName ?? "",
                        email: user.email ?? "",
                        nickname: user.displayName ?? "",
                        useNickname: true
                    )
                    self.isSignedIn = true
                }
            }
        } catch {
            print("Error during sign-in: \(error.localizedDescription)")
            throw error
        }
    }
    
    func signInWithGoogle(presentingViewController: UIViewController) {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [unowned self] signInResult, error in
            if let error = error {
                print("Error signing in with Google: \(error.localizedDescription)")
                return
            }
            
            guard let user = signInResult?.user else {
                print("Google Authentication failed.")
                return
            }
            
            let idToken = user.idToken!.tokenString
            let accessToken = user.accessToken.tokenString
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Error signing in with Google: \(error.localizedDescription)")
                    return
                }
                
                DispatchQueue.main.async {
                    if let user = authResult?.user {
                        self.currentUser = User(
                            id: user.uid,
                            username: user.displayName ?? "",
                            email: user.email ?? "",
                            nickname: user.displayName ?? "",
                            useNickname: true
                        )
                        self.isSignedIn = true
                    }
                }
            }
        }
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }

        return String(nonce)
    }

    @available(iOS 13, *)
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }

    @available(iOS 13, *)
    func startSignInWithAppleFlow() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
            
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error = error {
                    print("Error signing in with Apple: \(error.localizedDescription)")
                    return
                }
                
                DispatchQueue.main.async {
                    if let user = authResult?.user {
                        self.currentUser = User(
                            id: user.uid,
                            username: user.displayName ?? "",
                            email: user.email ?? "",
                            nickname: user.displayName ?? "",
                            useNickname: true
                        )
                        self.isSignedIn = true
                    }
                }
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Sign in with Apple errored: \(error.localizedDescription)")
    }

    func signOut() async throws {
        do {
            try await AuthService.shared.signout()
            GIDSignIn.sharedInstance.signOut()
            
            DispatchQueue.main.async {
                self.isSignedIn = false
                self.currentUser = nil
            }
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError.localizedDescription)")
        }
    }
}
