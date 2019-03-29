//
//  CategoryLabelView.swift
//  ImageAnnotator
//
//  Created by Christopher Thiebaut on 2/23/19.
//  Copyright © 2019 Christopher Thiebaut. All rights reserved.
//

import Cocoa

class CategoryLabelView: NSView {
    
    var color: NSColor
    let label: String
    
    init(label: String, tagColor: NSColor) {
        self.label = label
        self.color = tagColor
        super.init(frame: NSRect.zero)
    }
    
    
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
