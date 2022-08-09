//
//  Menu.swift
//  Space
//
//  Created by Yuguo Xie on 16/06/22.
//

import Cocoa

class MenuCreator {
    static func createPresetMenuItems(menu: NSMenu,
                                      action selector: Selector?,
                                      container: SpaceContainer) {
        for spaceKey in PresetSpaces.allCases {
            if spaceKey.rawValue != container.current?.name {
                menu.addItem(NSMenuItem(title: spaceKey.localize(),
                                        action: selector))
            }
        }
    }
    
    static func createHiddenFilesMenu(menu: NSMenu,
                                   action selector: Selector?,
                                   items: [String]) {
        for item in items {
            menu.addItem(NSMenuItem(title: item,
                                    action: selector))
        }
    }
    
    static func createCustomizedMenu(menu: NSMenu,
                                     action selector: Selector?,
                                     container: SpaceContainer) {
        container.spaces!.filter {
            !$0.isPreset
        }.forEach { space in
            let spaceMenuItem = NSMenuItem(title: space.name,
                                           action: selector)
            if let name = container.current?.name {
                spaceMenuItem.isEnabled = !(space.name == name)
            }
            menu.addItem(spaceMenuItem)
        }
    }
    
    static func createDeleteMenu(menu: NSMenu,
                                 action selector: Selector?,
                                 container: SpaceContainer) {
        container.spaces!.filter {
            !$0.isPreset
        }.forEach { space in
            menu.addItem(NSMenuItem(title: space.name,
                                    action: selector))
        }
    }
    
    static func createAddMenu(menu: NSMenu,
                              action selector: Selector?,
                              spaces: [Space]) {
        for space in spaces {
            menu.addItem(NSMenuItem(title: space.name,
                                    action: selector))
        }
    }
}

