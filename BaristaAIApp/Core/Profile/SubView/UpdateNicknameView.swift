//
//  ChangeNicknameView.swift
//  BaristaAI
//
//  Created by 김선철 on 9/25/24.
//

import SwiftUI
import FirebaseAuth

struct UpdateNicknameView: View {
    @State private var displayName: String = ""
    @StateObject var viewModel = ContentViewModel()
    @StateObject var registrationViewModel = RegistrationViewModel()
    var currentUser: User? {
        viewModel.currentUser
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("You can change your nickname here.")
                
                InfoTFView(title: "Nickname", text: $displayName)
                    .padding(.top, UIScreen.main.bounds.height / 20)
                
                Spacer()
                
                Button {
                    updateNickname()
                } label: {
                    Text("Update")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: UIScreen.main.bounds.width - 40)
                        .background(Color.blue)
                        .cornerRadius(10)                    
                }
                
                NavigationLink(destination: MainTabView(user: currentUser ?? nil)) {
                    EmptyView()
                }
            }
            .navigationTitle("Change Nickname")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func updateNickname() {
        guard let user = Auth.auth().currentUser else { return }
        
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        changeRequest.commitChanges { error in
            if let error {
                print("Error changing nickname: \(error.localizedDescription)")
            } else {
                print("Nickname changed successfully")
            }
        }
    }
}

#Preview {
//    UpdateNicknameView()
}
