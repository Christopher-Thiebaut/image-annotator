//
//  CreateCategoryModal.swift
//  ImageAnnotator
//
//  Created by Christopher Thiebaut on 3/14/19.
//  Copyright © 2019 Christopher Thiebaut. All rights reserved.
//

import Cocoa

protocol CreateCategoryModalDelegate: class {
    func modal(_ modal: CreateCategoryModal, finishedEditingWith style: AnnotationStyle)
}

class CreateCategoryModal: NSViewController {
    
    @IBOutlet weak var colorWell: NSColorWell!
    @IBOutlet weak var nameField: NSTextField!
    @IBOutlet weak var createButton: NSButton!
    weak var delegate: CreateCategoryModalDelegate?
    
    var annotationStyle: AnnotationStyle? {
        didSet {
            guard let style = annotationStyle else { return }
            colorWell.color = style.color.asNSColor
            nameField.stringValue = style.text
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        nameField.delegate = self
        createButton.isEnabled = false
        
    }
    
    @IBAction func createButtonTapped(_ sender: Any) {
        let color = colorWell.color.asColor
        let createdStyle = AnnotationStyle(text: nameField.stringValue.lowercased(), color: color)
        delegate?.modal(self, finishedEditingWith: createdStyle)
        dismiss(self)
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(self)
    }

}

extension CreateCategoryModal: NSTextFieldDelegate {
    override func controlTextDidChange(_ obj: Notification) {
        createButton.isEnabled = !nameField.stringValue.isEmpty
    }
}
