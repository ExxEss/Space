//
//  String-Extension.swift
//  Space Finder Extension
//
//  Created by Yuguo Xie on 31/07/22.
//  Copyright © 2022 Xie Yuguo. All rights reserved.
//

import Foundation

extension String {
    func localize(withComment comment: String? = nil) -> String {
        return NSLocalizedString(self, comment: comment ?? "")
    }
}
