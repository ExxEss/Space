//
//  NSMenuItem-Ext.swift
//  Space
//
//  Created by Yuguo Xie on 16/06/22.
//

import Foundation
import AppKit

extension NSMenuItem {
    convenience init(title: String, action: Selector?) {
        self.init(title: title,
                  action: action,
                  keyEquivalent: "")
    }
    
    
}
