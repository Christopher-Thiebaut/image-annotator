//
//  BoxSelectingImageView.swift
//  ImageAnnotator
//
//  Created by Christopher Thiebaut on 2/23/19.
//  Copyright © 2019 Christopher Thiebaut. All rights reserved.
//

import Cocoa

protocol TuriImageAnnotationViewDelegate: class {
    func imageAnnotationView(_ view: TuriImageAnnotationView, annotationStyleForBox box: NSRect) -> AnnotationStyle?
    func imageAnnotationView(_ view: TuriImageAnnotationView, removedAnnotationForBox box: NSRect)
}

protocol TuriImageAnnotationViewDataSource: class {
    func getAnnotationForImageURL(_ url: URL) -> [Annotation]
}

struct AnnotationStyle: Codable {
    let text: String
    let color: Color
}

struct Annotation: Codable {
    let coordinates: Rectangle
    let style: AnnotationStyle
}

class TuriImageAnnotationView: NSView, BoxSelectingImageViewDelegate {
    var boxSelectingImageView: BoxSelectingImageView
    
    weak var delegate: TuriImageAnnotationViewDelegate?
    weak var dataSource: TuriImageAnnotationViewDataSource?
    
    var imageURL: URL? {
        didSet {
            guard let url = imageURL else {
                image = nil; return
            }
            image = NSImage(byReferencing: url)
        }
    }
    
    private(set) var image: NSImage? {
        get {
            return boxSelectingImageView.image
        }
        set {
            boxSelectingImageView.image = newValue
            reloadDisplayedBoxes()
        }
    }
    
    override init(frame frameRect: NSRect) {
        boxSelectingImageView = BoxSelectingImageView(frame: NSRect.zero)
        super.init(frame: frameRect)
        boxSelectingImageView.frame = bounds
        addSubview(boxSelectingImageView)
        boxSelectingImageView.delegate = self
        autoresizesSubviews = true
    }
    
    required init?(coder decoder: NSCoder) {
        boxSelectingImageView = BoxSelectingImageView(frame: NSRect.zero)
        super.init(coder: decoder)
        addSubview(boxSelectingImageView)
        boxSelectingImageView.frame = bounds
        boxSelectingImageView.delegate = self
        autoresizesSubviews = true
    }
    
    func clearDisplayedBoxes() {
        let annotationBoxes = subviews.filter { $0 is AnnotationView }
        annotationBoxes.forEach { $0.removeFromSuperview() }
    }
    
    func reloadDisplayedBoxes() {
        clearDisplayedBoxes()
        //get all the new boxes
        guard let imageURL = imageURL, let dataSource = dataSource else { return }
        let boxes = dataSource.getAnnotationForImageURL(imageURL)
        for box in boxes {
            guard let frame = try? boxSelectingImageView.getFrameForImageCoordinates(box.coordinates.asCGRect) else { return }
            let annotation = AnnotationView(frame: frame, style: box.style)
            addSubview(annotation)
        }
    }
    
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        boxSelectingImageView.frame = bounds
        reloadDisplayedBoxes()
    }

    //MARK: - BoxSelectingImageViewDelegate
    func boxSelectingView(_ view: BoxSelectingImageView, didSelectBox box: NSRect, withImageCoordinates imageBox: NSRect) {
        guard let style = delegate?.imageAnnotationView(self, annotationStyleForBox: imageBox) else { return }
        let annotation = AnnotationView(frame: box, style: style)
        addSubview(annotation)
    }
}

protocol BoxSelectingImageViewDelegate: class {
    func boxSelectingView(_ view: BoxSelectingImageView, didSelectBox box: NSRect, withImageCoordinates imageBox: NSRect)
}

class BoxSelectingImageView: NSImageView {
    
    enum CoordinateConversionError: Error {
        case noImageForFrameConversion
    }
    
    private var mouseDownLocation: NSPoint?
    private var didDrag = false
    var imageFrame: CGRect {
        guard let image = image else { return CGRect.zero }
        let size = image.size.scaledBy(factor: imageScale)
        let emptyX = frame.size.width - size.width
        let emptyY = frame.size.height - size.height
        let xOrigin = emptyX / 2
        let yOrigin = emptyY / 2
        return NSRect(origin: NSPoint(x: xOrigin, y: yOrigin), size: size)
    }
    
    var imageScale: CGFloat {
        guard let image = image else { return 0 }
        let xScale = frame.size.width / image.size.width
        let yScale = frame.size.height / image.size.height
        return min(xScale, yScale, 1)
    }
    
    weak var delegate: BoxSelectingImageViewDelegate?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configureWithDefaultSettings()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureWithDefaultSettings()
    }
    
    func configureWithDefaultSettings() {
        imageAlignment = .alignCenter
        imageScaling = .scaleProportionallyDown
    }
    
    override func mouseDown(with event: NSEvent) {
        let positionInView = convert(event.locationInWindow, from: nil)
        mouseDownLocation = positionInView
    }
    
    override func mouseDragged(with event: NSEvent) {
        didDrag = true
    }
    
    override func mouseUp(with event: NSEvent) {
        guard let mouseDownLocation = mouseDownLocation else { return }
        let mouseUpLocation = convert(event.locationInWindow, from: nil)
        guard imageFrame.contains(mouseUpLocation) else { return }
        let origin = getOriginForRectDefinedBy(mouseUpLocation, mouseDownLocation)
        let size = getSizeForRectDefinedBy(mouseDownLocation, mouseUpLocation)
        let selectedRect = NSRect(origin: origin, size: size)
        let imageCoordinates = getImageCoordinates(forBox: selectedRect)
        delegate?.boxSelectingView(self, didSelectBox: selectedRect, withImageCoordinates: imageCoordinates)
        reset()
    }
    
    private func getOriginForRectDefinedBy(_ point1: NSPoint, _ point2: NSPoint) -> NSPoint {
        let xOrigin = min(point1.x, point2.x)
        let yOrigin = min(point1.y, point2.y)
        return NSPoint(x: xOrigin, y: yOrigin)
    }
    
    private func getSizeForRectDefinedBy(_ point1: NSPoint, _ point2: NSPoint) -> NSSize {
        return NSSize(width: range(point1.x, point2.x), height: range(point1.y, point2.y))
    }
    
    private func getImageCoordinates(forBox box: NSRect) -> NSRect {
        let size = box.size.scaledBy(factor: 1/imageScale)
        let imageOrigin = imageFrame.origin
        let boxOrigin = CGPoint(x: (box.origin.x - imageOrigin.x)/imageScale,
                                y: (box.origin.y - imageOrigin.y)/imageScale)
        let rawBox = NSRect(origin: boxOrigin, size: size)
        return modifyBoxToFitImageBounds(rawBox)
    }
    
    private func modifyBoxToFitImageBounds(_ box: NSRect) -> NSRect {
        guard let image = image else { return NSRect.zero }
        let origin = NSPoint(x: max(0, box.origin.x), y: max(0, box.origin.y))
        let verticalSpace = image.size.height - origin.y
        let horizontalSpace = image.size.width - origin.x
        let xBeforeBounds = box.origin.x < 0 ? -box.origin.x : 0
        let yBeforeBounds = box.origin.y < 0 ? -box.origin.y : 0
        let size = NSSize(width: min(box.size.width - xBeforeBounds, horizontalSpace),
                          height: min(box.size.height - yBeforeBounds, verticalSpace))
        return NSRect(origin: origin, size: size)
    }
    
    func getFrameForImageCoordinates(_ imageBox: NSRect) throws -> NSRect {
        guard let image = image else { throw CoordinateConversionError.noImageForFrameConversion }
        let scale = imageFrame.size.width / image.size.width
        let size = imageBox.size.scaledBy(factor: scale)
        let x = (imageBox.origin.x * scale + imageFrame.origin.x)// * scale
        let y = (imageBox.origin.y * scale + imageFrame.origin.y)// * scale
        return NSRect(x: x, y: y, width: size.width, height: size.height)
    }
    
//    override func resize(withOldSuperviewSize oldSize: NSSize) {
////        frame = superview?.bounds ?? NSRect.zero
//    }
    
    func reset() {
        mouseDownLocation = nil
        didDrag = false
    }
    
}

extension NSSize {
    func scaledBy(factor scale: CGFloat) -> NSSize {
        return NSSize(width: width * scale, height: height * scale)
    }
}

extension NSPoint {
    func translateY(by distance: CGFloat) -> NSPoint {
        return NSPoint(x: x, y: y + distance)
    }
    
    func translateX(by distance: CGFloat) -> NSPoint {
        return NSPoint(x: x + distance, y: y)
    }
}

extension NSRect {
    var center: CGPoint {
        let centerX = origin.x + width/2
        let centerY = origin.y + height/2
        return CGPoint(x: centerX, y: centerY)
    }
}

fileprivate func range<T: Numeric & Comparable>(_ numbers: T...) -> T {
    guard let min = numbers.min(), let max = numbers.max() else { return -1 }
    return max - min
}
