//
//  Junkyard.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 25.06.24.
//

import SwiftUI

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

func showShareSheet(url: URL) {
    UIApplication.shared.currentWindow?.rootViewController?.present(
        UIActivityViewController(
            activityItems: [url],
            applicationActivities: [
                OpenInBrowserActivity()
            ]
        ),
        animated: true,
        completion: nil
    )
}
