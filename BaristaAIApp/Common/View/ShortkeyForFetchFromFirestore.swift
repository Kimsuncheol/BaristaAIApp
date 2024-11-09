//
//  File.swift
//  BaristaAIApp
//
//  Created by 김선철 on 9/28/24.
//

import Foundation
import FirebaseFirestore

class ShortkeyForFetchFromFirestore  {
    var myfavoriteDataFetch = Firestore.firestore().collection("myfavorite")
    var cartDataFetch = Firestore.firestore().collection("cart")
    var menuDataFetch = Firestore.firestore().collection("menu")
}
