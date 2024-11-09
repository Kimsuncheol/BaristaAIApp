//
//  KeyboardResponder.swift
//  BaristaAIApp
//
//  Created by 김선철 on 10/5/24.
//

import SwiftUI
import Combine

class KeyboardResponder: ObservableObject {
    @Published var currentHeight: CGFloat = 0 // 키보드 높이를 저장할 변수
    private var cancellable: AnyCancellable?

    init() {
        self.cancellable = NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .compactMap { notification in
                (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height
            }
            .sink { [weak self] height in
                self?.currentHeight = height
            }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWillHide(notification: Notification) {
        self.currentHeight = 0 // 키보드가 숨겨질 때 높이를 0으로 설정
    }

    deinit {
        cancellable?.cancel()
        NotificationCenter.default.removeObserver(self)
    }
}
