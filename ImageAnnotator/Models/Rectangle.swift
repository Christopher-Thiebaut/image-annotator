//
//  Rectangle.swift
//  ImageAnnotator
//
//  Created by Christopher Thiebaut on 3/15/19.
//  Copyright © 2019 Christopher Thiebaut. All rights reserved.
//

import Foundation

struct Rectangle: Codable {
    let origin: CGPoint
    let size: CGSize
    
    var asCGRect: CGRect {
        return CGRect(origin: origin, size: size)
    }
}

extension CGRect {
    var asRectangle: Rectangle {
        return Rectangle(origin: origin, size: size)
    }
}
