//
//  FinderSync.swift
//  Space Finder Extension
//
//  Created by Yuguo Xie on 07/06/22.
//

import Cocoa
import FinderSync
import CoreData

class FinderSync: FIFinderSync {
    let userDefaults = UserDefaults.spaceDefaults
    let spaceController = SpaceController.shared
    
    override init() {
        super.init()
        NSLog("FinderSync() launched from %@",
                Bundle.main.bundlePath as NSString)

//        userDefaults.resetDefaults()
        FIFinderSyncController.default().directoryURLs =
                [URL(fileURLWithPath: "/")]
    }
    
    deinit {
       // alertInfo(info: "You need to restart Finder to reactivate Space")
    }
    
    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        spaceController.setup(targetURL: targetURL!)
        
        let main = NSMenu()
        
        if spaceController.hasUnavailableTargetURL() {
            return main
        }
        
        let container = spaceController.container
        
        if FIFinderSyncController.default().selectedItemURLs()!.contains(
            FIFinderSyncController.default().targetedURL()!
        ) {
            MenuCreator.createPresetMenuItems(menu: main,
                                              action: #selector(alterPresetSpace(_:)),
                                              container: container)
            // Exist customized spaces, add delete menu
            if container.spaces!.count > PresetSpaces.allCases.count {
                let submenu = NSMenu()
                let customizedDropdown = NSMenuItem(title: "Space Collection".localize(),
                                              action: nil)

                main.addItem(customizedDropdown)
                main.setSubmenu(submenu, for: customizedDropdown)
                
                MenuCreator.createCustomizedMenu(menu: submenu,
                                             action: #selector(alterSpace(_:)),
                                             container: container)
                
                let deleteDropdown = NSMenuItem(title: "Delete".localize(),
                                                  action: nil)
                let deletionSubmenu = NSMenu()
                
                MenuCreator.createDeleteMenu(menu: deletionSubmenu,
                                             action: #selector(deleteSpace(_:)),
                                             container: spaceController.container)
                
                submenu.addItem(deleteDropdown)
                submenu.setSubmenu(deletionSubmenu, for: deleteDropdown)
            }
        } else {
            main.addItem(NSMenuItem(title: "Hide".localize(),
                                       action: #selector(hide(_:))))
            
            main.addItem(NSMenuItem(title: "Show Only".localize(),
                                       action: #selector(showOnly(_:))))

            main.addItem(NSMenuItem(title: "New Space with Selection".localize(),
                                       action: #selector(createSpace(_:))))
            
            if container.spaces!.count > PresetSpaces.allCases.count {
                let addToDropdown = NSMenuItem(title: "Add to Space".localize(),
                                               action: #selector(addToSpace(_:)))
                let addToSubmenu = NSMenu()
                MenuCreator.createAddMenu(menu: addToSubmenu,
                                          action: #selector(addToSpace(_:)),
                                          container: container)
                
                main.addItem(addToDropdown)
                main.setSubmenu(addToSubmenu, for: addToDropdown)
            }
        }
        return main
    }
    
    @IBAction func createSpace(_ sender: AnyObject?) {
        let items: [URL]? = selectedItems
        // .now() + 0.3
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            [self] in
            NSApplication.shared.activate(ignoringOtherApps: true)
            let newSpaceName = DialogCreator.createSpaceDialog()
            if (!newSpaceName.isEmpty) {
                spaceController.create(spaceName: newSpaceName,
                                        items: items)
            }
        }
    }
    
    @IBAction func alterSpace(_ sender: AnyObject?) {
        spaceController.alter(spaceName: sender!.title)
    }
    
    @IBAction func alterPresetSpace(_ sender: AnyObject?) {
        spaceController.alterPreset(spaceName: sender!.title)
    }
    
    @IBAction func deleteSpace(_ sender: AnyObject?) {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            [self] in
            NSApplication.shared.activate(ignoringOtherApps: true)
            let confirmed =
            DialogCreator.deleteSpaceDialog(spaceName: sender!.title)
            if confirmed {
                spaceController.delete(spaceName: sender!.title)
            }
        }
    }
    
    @IBAction func addToSpace(_ sender: NSMenuItem?) {
        spaceController.addItems(spaceName: sender!.title,
                                  items: selectedItems)
    }
    
    @IBAction func hide(_ sender: AnyObject?) {
        spaceController.hideItems(items: selectedItems)
    }
    
    @IBAction func showOnly(_ sender: AnyObject?) {
        spaceController.showOnly(items: selectedItems)
    }
}

extension FinderSync {
    var selectedItems: [URL]? {
        get {
            FIFinderSyncController.default().selectedItemURLs()
        }
    }
    
    var targetURL: URL? {
        get {
            FIFinderSyncController.default().targetedURL()
        }
    }
}
