//
//  Junkyard.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 25.06.24.
//

import SwiftUI

extension URL {
    func appendingPathComponentNonDeprecated(_ pathComponent: String) -> URL {
        if #available(iOS 16.0, *) {
            return self.appending(path: pathComponent)
        } else {
            return self.appendingPathComponent(pathComponent)
        }
    }
    
    var normalPath: String {
        if #available(iOS 16.0, *) {
            return self.path(percentEncoded: false)
        } else {
            return self.path
        }
    }
}

extension Data {
    var hexString: String {
        var result = String(repeating: "x", count: self.count * 2)
        
        for i in 0..<self.count {
            let byte = String(format:"%02X", self[i])
            
            let startIndex = result.index(result.startIndex, offsetBy: i * 2)
            let endIndex = result.index(startIndex, offsetBy: 1)
            result.replaceSubrange(startIndex...endIndex, with: byte)
        }
        
        return result
    }
    
    func write(to url: URL, options: Data.WritingOptions = [], creatingDirectory: Bool) throws {
        if creatingDirectory {
            let dirPath = url.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dirPath, withIntermediateDirectories: true)
        }
        
        try self.write(to: url, options: options)
    }
}

func formatDateWithoutTime(_ dateTime: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .none
    formatter.dateStyle = .long
    return formatter.string(from: dateTime)
}

func formatLongDateTime(_ dateTime: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .medium
    formatter.dateStyle = .long
    return formatter.string(from: dateTime)
}

func divideIntoPairs<T>(_ array: [T]) -> [(id: Int, T, T?)] {
    var iterator = array.makeIterator()
    var result: [(id: Int, T, T?)] = []
    var pairNum = 0;
    
    while true {
        let first = iterator.next()
        
        guard let first = first else {
            break
        }
        
        let second = iterator.next()
        result.append((id: pairNum, first, second))
        pairNum += 1
        
        if second == nil {
            break
        }
    }
    
    return result
}

func escapeExpressionForSqlLike(_ str: String, usingEscapeChar escapeChar: Character) -> String {
    
    return str
        .replacingOccurrences(of: "\(escapeChar)", with: "\(escapeChar)\(escapeChar)")
        .replacingOccurrences(of: "_", with: "\(escapeChar)_")
        .replacingOccurrences(of: "%", with: "\(escapeChar)%")
}

extension Double {
    func toFixedString(digitsAfterDecimalPoint: UInt = 0) -> String {
        return String(format: "%.\(digitsAfterDecimalPoint)f", self)
    }
}

func pollOptionsWithNicePercentages(_ pollOptions: [APubPollOption], digitsAfterDecimalPoint: UInt = 0) -> [
    (
        pollOption: APubPollOption,
        proportion: Double,
        percentage: String
    )
] {
    guard pollOptions.count > 0 else {
        return []
    }
    
    let totalVotes = pollOptions.map(\.numVotes).reduce(0, +)
    
    guard totalVotes != 0 else {
        return pollOptions.map { pollOption in
            (
                pollOption: pollOption,
                proportion: 0,
                percentage: 0.0.toFixedString(digitsAfterDecimalPoint: digitsAfterDecimalPoint) + "%"
            )
        }
    }
    
    let tenPowDigits = pow(10.0, Double(digitsAfterDecimalPoint))
    
    var result = pollOptions.enumerated().map { (idx, pollOption) in
        let proportion = Double(pollOption.numVotes) / Double(totalVotes)
        let percentage = (proportion * 100.0 * tenPowDigits).rounded() / tenPowDigits
        return (pollOption: pollOption, proportion: proportion, percentage: percentage)
    }
    
    
    while result.map(\.percentage).reduce(0, +) < 100.0 {
        let (biggestIndex, _) = result.enumerated().max { a, b in
            a.element.percentage < b.element.percentage
        }!
        
        result[biggestIndex].percentage += 1.0 / tenPowDigits
    }
    
    while result.map(\.percentage).reduce(0, +) < 100.0 {
        let (smallestIndex, _) = result.enumerated().min { a, b in
            a.element.percentage < b.element.percentage
        }!
        
        result[smallestIndex].percentage -= 1.0 / tenPowDigits
    }
    
    return result.map { (pollOption, proportion, percentage) in
        (
            pollOption: pollOption,
            proportion: proportion,
            percentage: percentage.toFixedString(digitsAfterDecimalPoint: digitsAfterDecimalPoint) + "%"
        )
    }
}

extension Array {
    func get(indexSet: IndexSet) -> [Element] {
        var result: [Element] = Array()
        result.reserveCapacity(indexSet.count)
        
        for index in indexSet {
            result.append(self[index])
        }
        
        return result
    }
}

public extension UIApplication {
    var currentWindow: UIWindow? {
        let foregroundScene = UIApplication.shared.connectedScenes
            .first { scene in scene.activationState == .foregroundActive } as? UIWindowScene
        
        return foregroundScene?.windows.first(where: \.isKeyWindow)
    }
}

class OpenInBrowserActivity: UIActivity {
    var activityItem: URL? = nil
    
    override var activityTitle: String? {
        "Open in Browser"
    }
    
    override var activityImage: UIImage? {
        UIImage(systemName: "safari")
    }
    
    override var activityType: UIActivity.ActivityType? {
        UIActivity.ActivityType("works.ish.mastodon-archive-tool.open-in-browser")
    }
    
    override class var activityCategory: UIActivity.Category {
        .action
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return activityItems.contains { item in item is URL }
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        self.activityItem = (activityItems.first { item in item is URL } as! URL)
    }
    
    override func perform() {
        if let activityItem = activityItem {
            UIApplication.shared.open(activityItem)
        }
    }
}

class MacCatalystSaveFileActivity: UIActivity {
    let data: Data
    let originalFilename: String
    
    init(data: Data, originalFilename: String) {
        self.data = data
        self.originalFilename = originalFilename
    }
    
    override var activityTitle: String? {
        "Save File"
    }
    
    override var activityImage: UIImage? {
        UIImage(systemName: "doc")
    }
    
    override var activityType: UIActivity.ActivityType? {
        UIActivity.ActivityType("works.ish.mastodon-archive-tool.mac-catalyst-save-file")
    }
    
    override class var activityCategory: UIActivity.Category {
        .action
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return ProcessInfo.processInfo.isiOSAppOnMac || ProcessInfo.processInfo.isMacCatalystApp
    }
    
    override func perform() {
        // this is all so convoluted and i hate it so much
        
        let tmpDir = FileManager.default.temporaryDirectory
        let fileUrl = tmpDir.appendingPathComponentNonDeprecated(originalFilename)
        do {
            try data.write(to: fileUrl)
        } catch {
            print("Writing temp file \(fileUrl) encountered an error: \(error)")
            return
        }
        
        let picker = DocumentSaveDialogController(fileUrl: fileUrl) { url in
            if url == nil {
                do {
                    try FileManager.default.removeItem(at: fileUrl)
                } catch {
                    print("Removing temp file \(fileUrl) encountered an error: \(error)")
                }
                return
            }
        }
        
        var rootViewController = UIApplication.shared.currentWindow?.rootViewController
        while let presentedViewController = rootViewController?.presentedViewController {
            rootViewController = presentedViewController
        }
        rootViewController?.present(picker, animated: true)
    }
}

/// this class shouldn't have to exist and yet, in defiance of the will of Hashem may He be blessed, in defiance to the very ethical rules and conceptions that hold all of human society loosely together, as an affront to the universe itself, this class, undeinably, exists
class DocumentSaveDialogController: UIDocumentPickerViewController, UIDocumentPickerDelegate {
    private let onDone: (URL?) -> Void
    
    init(fileUrl: URL, onDone: @escaping (URL?) -> Void) {
        self.onDone = onDone
        
        super.init(forExporting: [fileUrl], asCopy: false)
        self.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        onDone(nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        onDone(urls[0])
    }
}

let mimetypesToExtensions = [
    "audio/aac": ".aac",
    "audio/midi": ".mid",
    "audio/x-midi": ".mid",
    "audio/mpeg": ".mp3",
    "audio/ogg": ".oga",
    "audio/wav": ".wav",
    "audio/webm": ".weba",
    "audio/3gpp": ".3gp",
    "audio/3gpp2": ".3g2",
    
    "application/ogg": ".ogx",
    "application/pdf": ".pdf",
    
    "image/apng": ".apng",
    "image/avif": ".avif",
    "image/bmp": ".bmp",
    "image/gif": ".gif",
    "image/vnd.microsoft.icon": ".ico",
    "image/jpeg": ".jpeg",
    "image/png": ".png",
    "image/svg+xml": ".svg",
    "image/tiff": ".tiff",
    "image/webp": ".webp",
    
    "video/x-msvideo": ".avi",
    "video/mp4": ".mp4",
    "video/mpeg": ".mpeg",
    "video/ogg": ".ogv",
    "video/mp2t": ".ts",
    "video/webm": ".webm",
    "video/3gpp": ".3gp",
    "video/3gpp2": ".3g2"
]
