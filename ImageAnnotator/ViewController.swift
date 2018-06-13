//
//  ViewController.swift
//  ImageAnnotator
//
//  Created by Christopher Thiebaut on 6/12/18.
//  Copyright © 2018 Christopher Thiebaut. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet private weak var mainImageView: NSImageView!
    
    private let fileManager = FileManager.default
    private let imageFileTypes: Set<String> = ["jpg", "png"]
    
    private var imagesDirectory: URL? {
        didSet {
            guard let imagesDirectory = imagesDirectory else { return }
            imageURLS = imagesIn(folder: imagesDirectory)
        }
    }
    
    private var imageURLS: [URL] = [] {
        didSet {
            guard imageURLS.count > 0 else { return }
            currentImageIndex = 0
        }
    }
    
    private var currentImage: NSImage? {
        didSet {
            mainImageView.image = currentImage
        }
    }
    
    private var currentImageIndex: Int = 0 {
        didSet {
            guard currentImageIndex >= 0 && currentImageIndex < imageURLS.count else { return }
            currentImage =  NSImage(byReferencing: imageURLS[currentImageIndex])
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    private func imagesIn(folder url: URL) -> [URL] {
        do {
            let directoryContents = try fileManager.contentsOfDirectory(atPath: url.path)
            let fileURLs = directoryContents
                .filter({isAnImageFileType(fileName: $0)})
                .map({url.appendingPathComponent($0)})
            return fileURLs
        } catch let error {
            NSLog("Failed to load contents of directory \(url.path) due to an error: \(error.localizedDescription)")
            return []
        }
    }
    
    private func isAnImageFileType(fileName: String) -> Bool {
        let fileNameParts = fileName.split(separator: ".")
        guard fileNameParts.count > 1, let fileExtension = fileNameParts.last else {
            return false
        }
        return imageFileTypes.contains(String(fileExtension))
    }
    
    private func incrementImageIndex(by indexChange: Int) {
        guard imageURLS.count > 0 else { return }
        //The new image index is set based on the number of images so that if the index would be out of bounds it will loop back around to the begining (or end) of the array
        currentImageIndex = (currentImageIndex + indexChange) % imageURLS.count
    }

}

//MARK: - Main App Menu Actions
extension ViewController {
    @IBAction func chooseDirectoryClicked(sender: Any?) {
        guard let window = view.window else {
            return
        }
        
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        
        panel.beginSheetModal(for: window) {[weak self] (response) in
            if response == .OK, let selectedFolder = panel.urls.first {
                self?.imagesDirectory = selectedFolder
            }
        }
    }
}

