//
//  Junkyard.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 25.06.24.
//

import Foundation

func formatDateWithoutTime(_ dateTime: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .none
    formatter.dateStyle = .long
    return formatter.string(from: dateTime)
}
