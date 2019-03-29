//
//  ViewController.swift
//  ImageAnnotator
//
//  Created by Christopher Thiebaut on 6/12/18.
//  Copyright © 2018 Christopher Thiebaut. All rights reserved.
//

import Cocoa

fileprivate enum CellIdentifiers {
    static let NameCell = "CategoryCellID"
}

class ImageAnnotationViewController: NSViewController {
    
    @IBOutlet private weak var mainImageView: TuriImageAnnotationView!
    @IBOutlet weak var labelsTableView: NSTableView!
    
    var styles = [AnnotationStyle]() {
        didSet {
            updateScratchFile()
        }
    }
    var selectedCategory: AnnotationStyle?
    var annotations = [FileName: [Annotation]]() {
        didSet {
            updateScratchFile()
        }
    }
    
    private let fileManager = FileManager.default
    private let imageFileTypes: Set<String> = ["jpg", "png"]
    
    private var imagesDirectory: URL? {
        didSet {
            guard let imagesDirectory = imagesDirectory else { return }
            imageURLS = imagesIn(folder: imagesDirectory)
            restoreStateFrom(directory: imagesDirectory)
        }
    }
    
    private func restoreStateFrom(directory: URL) {
        defer { finishedRestoringFromScratchFile = true }
        guard let scratchFile = ScratchFile(withDirectory: directory) else { return }
        let annotations = scratchFile.annotations
        let currentImage = scratchFile.lastViewedFile
        let categories = scratchFile.categories
        styles = categories
        labelsTableView.reloadData()
        self.annotations = annotations
        if let lastViewedIndex = imageURLS.firstIndex(where: { $0.fileName == currentImage}) {
            currentImageIndex = lastViewedIndex
        }
    }
    
    private var currentURL: URL {
        return imageURLS[currentImageIndex]
    }
    
    private var fileName: FileName {
        return currentURL.fileName
    }
    
    private var imageURLS: [URL] = [] {
        didSet {
            guard imageURLS.count > 0 else { return }
            currentImageIndex = 0
        }
    }
    
    private var currentImageIndex: Int = 0 {
        didSet {
            mainImageView.imageURL = currentURL
            updateScratchFile()
        }
    }
    
    private var finishedRestoringFromScratchFile = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        labelsTableView.dataSource = self
        labelsTableView.delegate = self
        mainImageView.dataSource = self
        mainImageView.delegate = self
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
        var newIndex = (currentImageIndex + indexChange) % imageURLS.count
        if newIndex < 0 { newIndex = imageURLS.count + newIndex }
        currentImageIndex = newIndex
    }
    
    @IBAction func previousButtonClicked(_ sender: Any) {
        incrementImageIndex(by: -1)
    }
    
    @IBAction func nextButtonClicked(_ sender: Any) {
        incrementImageIndex(by: 1)
    }
    
    @IBAction func createNewLabelPressed(_ sender: Any) {
        let nibName = String(describing: CreateCategoryModal.self)
        let modal = CreateCategoryModal(nibName: NSNib.Name(rawValue: nibName),
                                        bundle: Bundle.main)
        modal.title = "Configure Your New Category"
        modal.delegate = self
        presentViewControllerAsModalWindow(modal)
    }
    
    override func dismiss(_ sender: Any?) {
        super.dismiss(sender)
    }
    
    func updateScratchFile() {
        guard let directory = imagesDirectory, finishedRestoringFromScratchFile else { return }
        var scratchFile = ScratchFile(withDirectory: directory)
        scratchFile?.annotations = annotations
        scratchFile?.categories = styles
        scratchFile?.lastViewedFile = currentURL.fileName
        scratchFile?.header.imageFiles = imageURLS.map { $0.fileName }
        do {
            try scratchFile?.write()
        } catch let error {
            print(error)
        }
    }
}

//MARK: - Main App Menu Actions
extension ImageAnnotationViewController {
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

extension ImageAnnotationViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return styles.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
       return styles[row].text
    }
}

extension ImageAnnotationViewController: NSTableViewDelegate {
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = labelsTableView.selectedRow
        guard styles.containsIndex(selectedRow) else { return }
        selectedCategory = styles[selectedRow]
    }
    
    func tableView(_ tableView: NSTableView, shouldSelect tableColumn: NSTableColumn?) -> Bool {
        return false
    }
}

extension ImageAnnotationViewController: TuriImageAnnotationViewDelegate {
    func imageAnnotationView(_ view: TuriImageAnnotationView, annotationStyleForBox box: NSRect) -> AnnotationStyle? {
        guard let style = selectedCategory else { return nil }
        let annotation = Annotation(coordinates: box.asRectangle, style: style)
        if annotations[fileName] == nil {
            annotations[fileName] = [annotation]
        } else {
            annotations[fileName]?.append(annotation)
        }
        return style
    }
    
    func imageAnnotationView(_ view: TuriImageAnnotationView, removedAnnotationForBox box: NSRect) {
        var currentImageAnnotaions = annotations[fileName]
        guard let indexToDelete = currentImageAnnotaions?.firstIndex(where: { $0.coordinates.asCGRect == box } ) else { return }
        currentImageAnnotaions?.remove(at: indexToDelete)
        annotations[fileName] = currentImageAnnotaions
    }
}

extension ImageAnnotationViewController: TuriImageAnnotationViewDataSource {
    func getAnnotationForImageURL(_ url: URL) -> [Annotation] {
        return annotations[fileName] ?? []
    }
}

extension ImageAnnotationViewController: CreateCategoryModalDelegate {
    func modal(_ modal: CreateCategoryModal, finishedEditingWith style: AnnotationStyle) {
        var selectedIndex: Int
        if let indexOfStyle = styles.firstIndex(where: { $0.text == style.text }) {
            styles[indexOfStyle] = style
            selectedIndex = indexOfStyle
        } else {
            styles.append(style)
            selectedIndex = styles.count - 1
        }
        labelsTableView.reloadData()
        labelsTableView.selectRowIndexes(IndexSet(integer: selectedIndex), byExtendingSelection: false)
    }
}

extension Array {
    func containsIndex(_ index: Int) -> Bool {
        return index >= 0 && index < count
    }
}
