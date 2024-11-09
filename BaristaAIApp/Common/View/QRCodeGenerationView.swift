//
//  QRCodeGenerationView.swift
//  BaristaAIApp
//
//  Created by 김선철 on 11/7/24.
//

import SwiftUI
import CoreImage.CIFilterBuiltins
import FirebaseFirestore

struct QRCodeGenerationView: View {
    var notification: NotificationModel
    @State var qrCodeImage: UIImage?
    
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    let db = Firestore.firestore()
    
    var body: some View {
        VStack {
            if let qrCodeImage = qrCodeImage {
                Image(uiImage: qrCodeImage)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding()
            } else {
                Text("Generating QR Code...")
                    .foregroundStyle(.red)
            }
            
            Text("QR Code for Payment")
               .font(.headline)
               .padding(.vertical)
            
            Text("Customer Email: \(notification.customerEmail)")
            Text("Payment ID: \(notification.id)")      // 배포 시 삭제할 예정
            Text("Time: \(notification.time)")          // 배포 시 삭제할 예정
        }
        .onAppear {
            generateQRCode()
        }
        .navigationTitle("QR Code")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func generateQRCode() {
        let qrDataString = "\(notification.id)--\(notification.customerEmail)--\(notification.time)--\(notification.status)"
        filter.message = Data(qrDataString.utf8)
        
        if let outputImage = filter.outputImage,
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            qrCodeImage = UIImage(cgImage: cgImage)
        }
    }
}

#Preview {
//    QRCodeGenerationView()
}
