//
//  StorableColor.swift
//  ImageAnnotator
//
//  Created by Christopher Thiebaut on 3/15/19.
//  Copyright © 2019 Christopher Thiebaut. All rights reserved.
//

import Cocoa

struct Color: Codable {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat
    
    var asNSColor: NSColor {
        return NSColor(deviceRed: red, green: green, blue: blue, alpha: alpha)
    }
}

extension NSColor {
    var asColor: Color {
        var red, green, blue, alpha: CGFloat
        (red, green, blue, alpha) = (0,0,0,0)
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return Color(red: red,
                     green: green,
                     blue: blue,
                     alpha: alpha)
    }
}
