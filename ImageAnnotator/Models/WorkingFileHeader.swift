//
//  WorkingFileHeader.swift
//  ImageAnnotator
//
//  Created by Christopher Thiebaut on 3/15/19.
//  Copyright © 2019 Christopher Thiebaut. All rights reserved.
//

import Foundation

struct WorkingFileHeader: Codable {
    let directoryImageURLs: [String]
    let lastViewedURL: String
    let annotationCategories: [AnnotationStyle]
}

typealias FileName = String

struct ScratchFile: Codable {
    
    let workingDirectory: URL
    var header: WorkingFileHeader
    var annotations: [FileName: [Annotation]]
    private var fileURL: URL {
        return workingDirectory.appendingPathComponent(".annotation_scratch")
    }
    var lastViewedFile: FileName {
        get { return header.lastViewedFile }
        set { header.lastViewedFile = newValue }
    }
    
    var categories: [AnnotationStyle] {
        get { return header.annotationCategories }
        set { header.annotationCategories = newValue }
    }
    
    init?(withDirectory url: URL) {
        guard url.hasDirectoryPath else { return nil }
        self.workingDirectory = url
        var archivedScratch: ScratchFile?
        if let archivedData = try? Data(contentsOf: workingDirectory.appendingPathComponent(".annotation_scratch")) {
            archivedScratch = try? JSONDecoder().decode(ScratchFile.self, from: archivedData)
        }
        self.header = WorkingFileHeader(imageFiles: archivedScratch?.header.imageFiles ?? [],
                                        lastViewedFile: archivedScratch?.lastViewedFile ?? "",
                                        annotationCategories: archivedScratch?.header.annotationCategories ?? [])
        self.annotations = archivedScratch?.annotations ?? [:]
    }
    
    struct WorkingFileHeader: Codable {
        var imageFiles: [FileName]
        var lastViewedFile: FileName
        var annotationCategories: [AnnotationStyle]
    }
    
    func write() throws {
        let data = try JSONEncoder().encode(self)
        try data.write(to: fileURL)
    }
    
    func fileURLwith(name: FileName) -> URL {
        return workingDirectory.appendingPathComponent(name)
    }
}

extension URL {
    var fileName: FileName {
        return lastPathComponent
    }
}
