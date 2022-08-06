//
//  Space.swift
//  Space
//
//  Created by Yuguo Xie on 10/06/22.
//

import Foundation

struct Space: Codable {
    var name: String
    var isPreset: Bool = false
    var urlBookmarks: [Data]?
}

struct SpaceContainer: Codable {
    var targetURL: URL
    var current: Space?
    var spaces: [Space]?
}
