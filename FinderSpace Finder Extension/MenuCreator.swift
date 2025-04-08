//
//  Menu.swift
//  Space
//
//  Created by Yuguo Xie on 16/06/22.
//

import Cocoa

class MenuCreator {
    static func createPresetMenuItems(
        menu: NSMenu,
        action selector: Selector?,
        container: SpaceContainer
    ) {
        for spaceKey in PresetSpaces.allCases {
            if spaceKey.rawValue != container.current?.name {
                menu.addItem(
                    NSMenuItem(
                        title: spaceKey.localize(),
                        action: selector
                    )
                )
            }
        }
    }
    
    static func createHiddenFileMenu(
        menu: NSMenu,
        action selector: Selector?,
        items: [String]
    ) {
        for item in items {
            menu.addItem(
                NSMenuItem(
                    title: item,
                    action: selector
                )
            )
        }
    }
    
    static func createSpaceCollectionMenu(
        menu: NSMenu,
        switchAction: Selector?,
        deleteAction: Selector?,
        container: SpaceContainer
    ) {
        // Filter non-preset spaces
        let customSpaces = container.spaces!.filter { !$0.isPreset }
        
        // Store the space names in UserDefaults for later retrieval
        let spaceNames = customSpaces.map { $0.name }
        UserDefaults.spaceDefaults.set(spaceNames, forKey: "CustomSpaceNames")
        
        // Create menu items for each space
        for (index, space) in customSpaces.enumerated() {
            var title = space.name
            
            if let name = container.current?.name {
                title = (space.name == name)
                    ? "• \(space.name)"
                    : space.name
            }
            
            let spaceDropdown = NSMenuItem(
                title: title,
                action: nil
            )
            
            menu.addItem(spaceDropdown)
            
            let submenu = NSMenu()
            menu.setSubmenu(submenu, for: spaceDropdown)
            
            let switchSpaceItem = NSMenuItem(
                title: "Switch to \(space.name)",
                action: switchAction
            )
            
            // Set the tag to the index of the space in our array
            switchSpaceItem.tag = index
            
            if let name = container.current?.name {
                switchSpaceItem.isEnabled = !(space.name == name)
            }
            
            let deleteSpaceItem = NSMenuItem(
                title: "Delete \(space.name)",
                action: deleteAction
            )
            
            // Set the tag to the index of the space in our array
            deleteSpaceItem.tag = index
            
            submenu.addItem(switchSpaceItem)
            submenu.addItem(deleteSpaceItem)
        }
    }
    
    static func createAddMenu(
        menu: NSMenu,
        action selector: Selector?,
        spaces: [Space]
    ) {
        for space in spaces {
            menu.addItem(
                NSMenuItem(
                    title: space.name,
                    action: selector
                )
            )
        }
    }
    
    static func createMoveMenu(
        menu: NSMenu,
        action selector: Selector?,
        spaces: [Space]
    ) {
        for space in spaces {
            menu.addItem(
                NSMenuItem(
                    title: space.name,
                    action: selector
                )
            )
        }
    }
}

