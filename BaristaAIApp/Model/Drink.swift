//
//  Coffee.swift
//  BaristaAIApp
//
//  Created by 김선철 on 9/27/24.
//

import SwiftUI

struct Drink: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    let image: String?
    let flavor_profile: [String]
    let type: String            // drink type
    let temperature: String     // Hot or Cold
    let is_lactose_free: Bool   // 유당 유무
    var description: String     // 음료 설명
    var price: Int           // 음료 가격
    var sales: Int          // -> 유의
    
    // Add this initializer for Firestore decoding
    init(id: String, name: String, image: String?, flavor_profile: [String], type: String, temperature: String, is_lactose_free: Bool, description: String, price: Int, sales: Int) {
        self.id = id
        self.name = name
        self.image = image
        self.flavor_profile = flavor_profile
        self.type = type
        self.temperature = temperature
        self.is_lactose_free = is_lactose_free
        self.description = description
        self.price = price
        self.sales = sales
    }
}

extension Drink{
    var dictionary: [String: Any] {
        return [
            "id": id,
            "name": name,
            "image": image ?? "",
            "flavor_profile": flavor_profile,
            "type": type,
            "temperature": temperature,
            "is_lactose_free": is_lactose_free,
            "description": description,
            "price": price,
            "sales": sales
        ]
    }
}

extension Drink {
    static var MOCK_Menu: [Drink] = [
        .init(id: UUID().uuidString, name: "아메리카노", image: "americano", flavor_profile: ["Bitter", "Smooth"], type: "Base", temperature: "Hot", is_lactose_free: true, description: "쌀쌀한 날엔 따뜻한 아메리카노로, 더운 날엔 얼음 가득 아이스 아메리카노로 시원함과 진한 풍미를 즐겨보세요.", price: 3800, sales: 0),
        .init(id: UUID().uuidString, name: "아이스 아메리카노", image: "iced_americano", flavor_profile: ["Bitter", "Smooth"], type: "Base", temperature: "Cold", is_lactose_free: true, description: "시원한 아이스 아메리카노로 더운 여름을 즐겨보세요.", price: 3800, sales: 0),
        
            .init(id: UUID().uuidString, name: "라떼", image: "latte", flavor_profile: ["Creamy", "Mild"], type: "Latte", temperature: "Hot", is_lactose_free: false, description: "비 오는 날엔 따뜻한 라떼 한 잔으로 마음을 녹이고, 맑은 날엔 부드러운 아이스 라떼로 기분 좋게 시작해보세요.", price: 4000, sales: 0),
        .init(id: UUID().uuidString, name: "아이스 라떼", image: "iced_latte", flavor_profile: ["Creamy", "Mild"], type: "Latte", temperature: "Cold", is_lactose_free: false, description: "부드러운 아이스 라떼로 더위를 날려보세요.", price: 4000, sales: 0),
        
            .init(id: UUID().uuidString, name: "카푸치노", image: "cappuccino", flavor_profile: ["Frothy", "Rich"], type: "Latte", temperature: "Hot", is_lactose_free: false, description: "쌀쌀한 날씨에 부드러운 거품 가득한 따뜻한 카푸치노를 마시면, 몸과 마음이 함께 포근해지는 느낌을 즐겨보세요.", price: 4500, sales: 0),
        .init(id: UUID().uuidString, name: "아이스 카푸치노", image: "iced_cappuccino", flavor_profile: ["Frothy", "Rich"], type: "Latte", temperature: "Cold", is_lactose_free: false, description: "시원한 아이스 카푸치노로 여름을 만끽하세요.", price: 4500, sales: 0),
        
            .init(id: UUID().uuidString, name: "바닐라 라떼", image: "vanilla_latte", flavor_profile: ["Sweet", "Creamy"], type: "Latte", temperature: "Hot", is_lactose_free: false, description: "추운 겨울엔 따뜻하게, 더운 여름엔 시원하게! 달콤한 바닐라 라떼로 사계절 내내 행복한 맛을 경험해보세요.", price: 4500, sales: 0),
        .init(id: UUID().uuidString, name: "아이스 바닐라 라떼", image: "iced_vanilla_latte", flavor_profile: ["Sweet", "Creamy"], type: "Latte", temperature: "Cold", is_lactose_free: false, description: "부드러운 아이스 바닐라 라떼로 기분을 전환하세요.", price: 4500, sales: 0),
        
            .init(id: UUID().uuidString, name: "콜드브루", image: "cold_brew", flavor_profile: ["Smooth", "Bold"], type: "Drink", temperature: "Cold", is_lactose_free: true, description: "무더운 여름날엔 청량한 콜드브루 한 잔으로 시원함과 깊은 커피의 맛을 동시에 느껴보세요. 상쾌함이 가득!", price: 5000, sales: 0),
        .init(id: UUID().uuidString, name: "아이스 콜드브루", image: "iced_cold_brew", flavor_profile: ["Smooth", "Bold"], type: "Drink", temperature: "Cold", is_lactose_free: true, description: "시원한 아이스 콜드브루로 더위를 날려보세요.", price: 5000, sales: 0),
        
            .init(id: UUID().uuidString, name: "카라멜 마키아토", image: "caramel_macchiato", flavor_profile: ["Sweet", "Creamy"], type: "Macchiato", temperature: "Hot", is_lactose_free: false, description: "쌀쌀한 날씨엔 달콤한 카라멜 마키아토로 하루를 달콤하게 시작해보세요. 따뜻함과 함께 기분까지 좋아져요!", price: 5000, sales: 0),
        .init(id: UUID().uuidString, name: "아이스 카라멜 마키아토", image: "iced_caramel_macchiato", flavor_profile: ["Sweet", "Creamy"], type: "Macchiato", temperature: "Cold", is_lactose_free: false, description: "시원한 아이스 카라멜 마키아토로 더위를 날려보세요!", price: 5000, sales: 0),
        
            .init(id: UUID().uuidString, name: "라임 에이드", image: "lime_ade", flavor_profile: ["Sour", "Refreshing"], type: "Refresher", temperature: "Cold", is_lactose_free: true, description: "상큼한 라임으로 만든 에이드로 여름의 더위를 날려보세요!", price: 4400, sales: 0),
        .init(id: UUID().uuidString, name: "청포도 에이드", image: "green_grape_ade", flavor_profile: ["Sweet", "Refreshing"], type: "Refresher", temperature: "Cold", is_lactose_free: true, description: "상큼한 청포도로 만든 에이드로 기분을 전환하세요!", price: 4300, sales: 0),
        
            .init(id: UUID().uuidString, name: "아이스티", image: "iced_tea", flavor_profile: ["Herbal", "Refreshing"], type: "Tea", temperature: "Cold", is_lactose_free: true, description: "시원한 아이스티로 더위를 날리세요!", price: 3900, sales: 0),
        .init(id: UUID().uuidString, name: "얼그레이 밀크티", image: "earl_grey_tea", flavor_profile: ["Floral", "Creamy"], type: "Tea", temperature: "Hot", is_lactose_free: false, description: "부드럽고 향긋한 얼그레이와 진한 우유의 조화!", price: 4500, sales: 0),
        
            .init(id: UUID().uuidString, name: "민트 초코", image: "mint_choco", flavor_profile: ["Mint", "Chocolate"], type: "Drink", temperature: "Hot", is_lactose_free: false, description: "상큼한 민트와 달콤한 초콜릿의 조화!", price: 4700, sales: 0),
        .init(id: UUID().uuidString, name: "체리 아이스티", image: "cherry_ice_tea", flavor_profile: ["Fruity", "Refreshing"], type: "Tea", temperature: "Cold", is_lactose_free: true, description: "상큼한 체리와 얼음으로 만든 아이스티!", price: 4200, sales: 0),
        
            .init(id: UUID().uuidString, name: "코코넛 라떼", image: "coconut_latte", flavor_profile: ["Creamy", "Nutty"], type: "Latte", temperature: "Hot", is_lactose_free: false, description: "코코넛의 고소한 맛과 부드러운 라떼의 조화!", price: 4600, sales: 0),
        .init(id: UUID().uuidString, name: "아이스 코코넛 라떼", image: "iced_coconut_latte", flavor_profile: ["Creamy", "Nutty"], type: "Latte", temperature: "Cold", is_lactose_free: false, description: "부드러운 아이스 코코넛 라떼로 더위를 날려보세요!", price: 4600, sales: 0),

            .init(id: UUID().uuidString, name: "라즈베리 레모네이드", image: "raspberry_lemonade", flavor_profile: ["Sweet", "Sour"], type: "Refresher", temperature: "Cold", is_lactose_free: true, description: "상큼한 라즈베리와 레몬의 조화!", price: 4200, sales: 0),
        .init(id: UUID().uuidString, name: "핑크 드링크", image: "pink_drink", flavor_profile: ["Sweet", "Fruity"], type: "Drink", temperature: "Cold", is_lactose_free: true, description: "달콤하고 상큼한 핑크 드링크로 기분을 전환하세요!", price: 4500, sales: 0),

            .init(id: UUID().uuidString, name: "망고 스무디", image: "mango_smoothie", flavor_profile: ["Sweet", "Tropical"], type: "Smoothie", temperature: "Cold", is_lactose_free: true, description: "상큼한 망고로 만든 시원한 스무디!", price: 4900, sales: 0),
        .init(id: UUID().uuidString, name: "바나나 스무디", image: "banana_smoothie", flavor_profile: ["Sweet", "Creamy"], type: "Smoothie", temperature: "Cold", is_lactose_free: true, description: "부드럽고 달콤한 바나나 스무디로 기분을 전환하세요!", price: 4900, sales: 0),

            .init(id: UUID().uuidString, name: "피치 아이스티", image: "peach_iced_tea", flavor_profile: ["Fruity", "Refreshing"], type: "Tea", temperature: "Cold", is_lactose_free: true, description: "상큼한 복숭아로 만든 아이스티!", price: 3900, sales: 0),
        .init(id: UUID().uuidString, name: "딸기 밀크쉐이크", image: "strawberry_milkshake", flavor_profile: ["Sweet", "Creamy"], type: "Drink", temperature: "Cold", is_lactose_free: false, description: "달콤한 딸기로 만든 밀크쉐이크!", price: 5100, sales: 0),

            .init(id: UUID().uuidString, name: "민트 모히토", image: "mint_mojito", flavor_profile: ["Mint", "Refreshing"], type: "Refresher", temperature: "Cold", is_lactose_free: true, description: "상큼한 민트와 라임이 어우러진 시원한 음료!", price: 4400, sales: 0),
        .init(id: UUID().uuidString, name: "카라멜 프라푸치노", image: "caramel_frappuccino", flavor_profile: ["Sweet", "Rich"], type: "Frappuccino", temperature: "Cold", is_lactose_free: false, description: "달콤한 카라멜 시럽이 가득한 프라푸치노!", price: 5100, sales: 0),

            .init(id: UUID().uuidString, name: "망고 프라푸치노", image: "mango_frappuccino", flavor_profile: ["Sweet", "Tropical"], type: "Frappuccino", temperature: "Cold", is_lactose_free: true, description: "상큼한 망고로 만든 프라푸치노!", price: 5200, sales: 0),
        .init(id: UUID().uuidString, name: "초코 프라푸치노", image: "chocolate_frappuccino", flavor_profile: ["Chocolate", "Rich"], type: "Frappuccino", temperature: "Cold", is_lactose_free: false, description: "진한 초콜릿의 맛을 느낄 수 있는 프라푸치노!", price: 5200, sales: 0),

            .init(id: UUID().uuidString, name: "스모크드 바닐라", image: "smoked_vanilla", flavor_profile: ["Sweet", "Rich"], type: "Coffee", temperature: "Hot", is_lactose_free: false, description: "스모크드 바닐라의 향긋함을 즐겨보세요!", price: 4800, sales: 0),
        .init(id: UUID().uuidString, name: "헤이즐넛 라떼", image: "hazelnut_latte", flavor_profile: ["Nutty", "Sweet"], type: "Latte", temperature: "Hot", is_lactose_free: false, description: "고소한 헤이즐넛의 풍미를 느껴보세요!", price: 4500, sales: 0),

            .init(id: UUID().uuidString, name: "우유", image: "milk", flavor_profile: ["Creamy"], type: "Drink", temperature: "Cold", is_lactose_free: false, description: "부드러운 우유로 시원함을 느껴보세요!", price: 3000, sales: 0),
        .init(id: UUID().uuidString, name: "유자차", image: "yuzu_tea", flavor_profile: ["Citrus", "Sweet"], type: "Drink", temperature: "Hot", is_lactose_free: true, description: "상큼한 유자차로 기분을 전환하세요!", price: 4000, sales: 0),

            .init(id: UUID().uuidString, name: "딸기 주스", image: "strawberry_juice", flavor_profile: ["Sweet", "Fruity"], type: "Refresher", temperature: "Cold", is_lactose_free: true, description: "상큼한 딸기로 만든 주스!", price: 4000, sales: 0),
        .init(id: UUID().uuidString, name: "사과 주스", image: "apple_juice", flavor_profile: ["Sweet", "Fruity"], type: "Refresher", temperature: "Cold", is_lactose_free: true, description: "신선한 사과로 만든 주스!", price: 4000, sales: 0),

            .init(id: UUID().uuidString, name: "오렌지 주스", image: "orange_juice", flavor_profile: ["Sweet", "Fruity"], type: "Refresher", temperature: "Cold", is_lactose_free: true, description: "상큼한 오렌지로 만든 주스!", price: 4000, sales: 0),
        .init(id: UUID().uuidString, name: "유자 에이드", image: "yuzu_ade", flavor_profile: ["Citrus", "Refreshing"], type: "Refresher", temperature: "Cold", is_lactose_free: true, description: "상큼한 유자로 만든 에이드!", price: 4400, sales: 0),

            .init(id: UUID().uuidString, name: "레몬 에이드", image: "lemonade", flavor_profile: ["Citrus", "Refreshing"], type: "Refresher", temperature: "Cold", is_lactose_free: true, description: "상큼한 레몬으로 만든 에이드!", price: 4400, sales: 0),
        .init(id: UUID().uuidString, name: "복숭아 아이스티", image: "peach_iced_tea", flavor_profile: ["Sweet", "Fruity"], type: "Tea", temperature: "Cold", is_lactose_free: true, description: "상큼한 복숭아로 만든 아이스티!", price: 3900, sales: 0),

            .init(id: UUID().uuidString, name: "피치 밀크티", image: "peach_milk_tea", flavor_profile: ["Sweet", "Creamy"], type: "Tea", temperature: "Cold", is_lactose_free: false, description: "부드러운 피치 밀크티로 기분 전환하세요!", price: 4500, sales: 0),
        .init(id: UUID().uuidString, name: "화이트 초콜릿 모카", image: "white_chocolate_mocha", flavor_profile: ["Sweet", "Creamy"], type: "Coffee", temperature: "Hot", is_lactose_free: false, description: "부드러운 화이트 초콜릿 모카로 따뜻함을 느껴보세요!", price: 4800, sales: 0)
    ]
}
