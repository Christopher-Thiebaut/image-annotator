//
//  AnnotationView.swift
//  ImageAnnotator
//
//  Created by Christopher Thiebaut on 3/13/19.
//  Copyright © 2019 Christopher Thiebaut. All rights reserved.
//

import Cocoa

class AnnotationView: NSView {
    
    var style: AnnotationStyle
    var titleLabel: NSTextField
    let borderWith: CGFloat = 2
    override var frame: NSRect {
        didSet {
            placeTitleLabel()
        }
    }
    
    init(frame frameRect: NSRect, style: AnnotationStyle) {
        self.style = style
        self.titleLabel = NSTextField(labelWithString: style.text)
        super.init(frame: frameRect)
        configureBorder()
        placeTitleLabel()
    }
    
    private func configureBorder() {
        wantsLayer = true
        layer?.borderColor = style.color.asNSColor.cgColor
        layer?.borderWidth = borderWith
        layer?.masksToBounds = true
    }
    
    private func placeTitleLabel() {
        titleLabel.removeFromSuperview()
        addSubview(titleLabel)
        let size = titleLabel.fittingSize
        let titleFrame = NSRect(origin: NSPoint(x: borderWith, y: borderWith),
                                size: size)
        titleLabel.frame = titleFrame
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
