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
            main.addItem(NSMenuItem(title: "New File".localize(),
                                       action: #selector(createFile(_:))))
            
            if !spaceController.isEmptyTargetURL() {
                MenuCreator.createPresetMenuItems(menu: main,
                                                  action: #selector(alterPresetSpace(_:)),
                                                  container: container)
                
                createHiddenFilesDropdown(title: "Show File",
                                          main: main,
                                          action: #selector(show(_:)))
                
                
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
            }
        } else {
            main.addItem(NSMenuItem(title: "Hide".localize(),
                                       action: #selector(hide(_:))))
            
            main.addItem(NSMenuItem(title: "Show Only".localize(),
                                       action: #selector(showOnly(_:))))

            main.addItem(NSMenuItem(title: "New Space with Selection".localize(),
                                       action: #selector(createSpace(_:))))
            
            
            let spaces = spaceController.addableSpaces
            
            if spaces.count > 0 {
                let addToDropdown = NSMenuItem(title: "Add to Space".localize(),
                                               action: #selector(addToSpace(_:)))
                let addToSubmenu = NSMenu()
                
                MenuCreator.createAddMenu(menu: addToSubmenu,
                                          action: #selector(addToSpace(_:)),
                                          spaces: spaces)
                
                main.addItem(addToDropdown)
                main.setSubmenu(addToSubmenu, for: addToDropdown)
                
                if let currentContainer = container.current, !currentContainer.isPreset {
                    let moveToDropdown = NSMenuItem(title: "Move to Space".localize(),
                                                    action: #selector(moveToSpace(_:)))
                    let moveToSubmenu = NSMenu()

                    MenuCreator.createMoveMenu(menu: moveToSubmenu,
                                              action: #selector(moveToSpace(_:)),
                                              spaces: spaces)

                    main.addItem(moveToDropdown)
                    main.setSubmenu(moveToSubmenu, for: moveToDropdown)
                }
            }
        }
        return main
    }
    
    func createHiddenFilesDropdown(title: String,
                                   main: NSMenu,
                                   action selector: Selector?) {
        var hiddenItems = spaceController.hiddenItems
        
        if hiddenItems.count > 0 {
            let submenu = NSMenu()
            let dropdown = NSMenuItem(title: title.localize(),
                                          action: nil)

            main.addItem(dropdown)
            main.setSubmenu(submenu, for: dropdown)
            
            hiddenItems = spaceController.hiddenItems.sorted(by: {
                (item, _item) -> Bool in
                return item.localizedCompare(_item) == .orderedAscending
            })
            
            MenuCreator.createHiddenFilesMenu(menu: submenu,
                                              action: selector,
                                              items: hiddenItems)
        }
    }
    
    @IBAction func createFile(_ sender: AnyObject?) {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            [self] in
            NSApplication.shared.activate(ignoringOtherApps: true)
            let newFileName = DialogCreator.createFileDialog()
            let path = self.spaceController.currentTargetURL?
                .appendingPathComponent(newFileName).path
            let url = URL(fileURLWithPath: path!)
            do {
                try "".write(to: url, atomically: true, encoding: .utf8)
                    NSWorkspace.shared.open(url)
            } catch {
                print(error)
            }
        }
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
    
    @IBAction func moveToSpace(_ sender: NSMenuItem?) {
        spaceController.moveItems(spaceName: sender!.title,
                                  items: selectedItems)
    }
    
    @IBAction func show(_ sender: NSMenuItem?) {
        spaceController.showItem(item: sender!.title)
    }
    
    @IBAction func hide(_ sender: AnyObject?) {
        spaceController.hideItems(items: selectedItems)
    }
    
    @IBAction func showOnly(_ sender: AnyObject?) {
        spaceController.showOnly(items: selectedItems)
    }
    
    @IBAction func replace(_ sender: AnyObject?) {
        spaceController.replace(item: sender!.title,
                                 items: selectedItems)
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
