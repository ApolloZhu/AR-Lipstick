//
//  Lipstick.swift
//  AR Lipstick
//
//  Created by Apollo Zhu on 2019/6/20.
//  Copyright © 2019 Apollo Zhu. All rights reserved.
//

import Foundation
import UIKit

extension Lipstick {
    struct Brand: Decodable {
        let name: String
        let series: [Series]
    }
}

extension Lipstick.Brand {
    struct Series: Decodable {
        let name: String
        let lipsticks: [Lipstick]
    }
}

struct Lipstick: Decodable {
    let color: UIColor
    let id: String
    let name: String
    
    enum CodingKeys: CodingKey {
        case color, id, name
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        
        // MARK: - UIColor.init(hexString:)
        guard let hex = Int(try container.decode(String.self, forKey: .color).dropFirst(), radix: 16) else {
            let error = DecodingError.Context(codingPath: [CodingKeys.color], debugDescription: "Color string has illegal format.")
            throw DecodingError.typeMismatch(UIColor.self, error)
        }
        let toColorComponent: (Int) -> CGFloat = { return CGFloat($0 & 0xFF) / 255 }
        self.color = UIColor(
            displayP3Red: toColorComponent(hex >> 16),
            green: toColorComponent(hex >> 8),
            blue: toColorComponent(hex),
            alpha: 1
        )
    }
}
