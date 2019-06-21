/*
 AR Lipstick
 
 Lipstick.swift
 Created by Apollo Zhu on 2019/6/20.
 
 Copyright © 2019 Apollo Zhu.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

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
