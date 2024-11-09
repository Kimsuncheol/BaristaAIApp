//
//  ApplePayHandler.swift
//  BaristaAIApp
//
//  Created by 김선철 on 10/8/24.
//

import SwiftUI
import PassKit

// Helper class to handle Apple Pay authorization
class ApplePayHandler: NSObject, PKPaymentAuthorizationControllerDelegate {
    var onCompletion: (() -> Void)?
    var onDismiss: (() -> Void)?    // To transform this view after order complete and Add callback
    var onPaymentTokenReceived: ((PKPaymentToken) -> Void)?  // paymentToken을 전달하기 위한 클로저 추가

    // Function to handle Apple Pay process
    func startApplePayProcess(totalPrice: Int) {
        let paymentRequest = PKPaymentRequest()
        paymentRequest.merchantIdentifier = "your.merchant.identifier"
        paymentRequest.supportedNetworks = [.visa, .masterCard, .amex, .discover]
        paymentRequest.merchantCapabilities = .threeDSecure
        paymentRequest.countryCode = "KR"
        paymentRequest.currencyCode = "KRW"

        // Add payment summary items
        let totalAmount = NSDecimalNumber(value: totalPrice)
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Total", amount: totalAmount)
        ]

        // Present Apple Pay
        if PKPaymentAuthorizationController.canMakePayments(usingNetworks: paymentRequest.supportedNetworks) {
            let paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
            paymentController.delegate = self
            paymentController.present { (presented) in
                if presented {
                    print("Apple Pay presented successfully.")
                } else {
                    print("Failed to present Apple Pay.")
                    // 디버깅을 위한 추가 메시지
                    if !PKPaymentAuthorizationController.canMakePayments() {
                        print("이 기기는 결제를 할 수 없습니다.")
                    }
                    if !PKPaymentAuthorizationController.canMakePayments(usingNetworks: paymentRequest.supportedNetworks) {
                        print("이 기기는 지정된 네트워크로 결제를 할 수 없습니다...")
                    }
                    if paymentRequest.merchantIdentifier.isEmpty {
                        print("merchantIdentifier가 비어 있거나 잘못되었습니다.")
                    }
                }
            }
        } else {
            print("이 기기는 지정된 네트워크로 결제를 할 수 없습니다.")
        }
    }

    // PKPaymentAuthorizationControllerDelegate methods
    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        // Handle successful authorization
        print("Payment authorized successfully.")

        // paymentToken을 가져와서 클로저를 통해 전달
        let paymentToken = payment.token
        onPaymentTokenReceived?(paymentToken)

        // 결제 승인 결과 반환
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
    }

    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss {
            self.onCompletion?()
            self.onDismiss?()       // Callback so that view-transform
            print("Apple Pay dismissed.")
        }
    }
}
