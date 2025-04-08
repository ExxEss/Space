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
    var spaceController = SpaceController()
    
    override init() {
        super.init()
        NSLog(
            "FinderSync() launched from %@",
            Bundle.main.bundlePath as NSString
        )

//        userDefaults.resetDefaults()
        FIFinderSyncController
            .default()
            .directoryURLs
        = [URL(fileURLWithPath: "/")]
    }
    
    deinit {
       // alertInfo(info: "You need to restart Finder to reactivate Space")
    }
    
    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        spaceController = SpaceController()
        spaceController.setup(targetURL: targetURL!)
        
        let main = NSMenu()
        
        if spaceController.hasUnavailableTargetURL() {
            return main
        }
        
        let container = spaceController.container
        
        if FIFinderSyncController.default().selectedItemURLs()!.contains(
            FIFinderSyncController.default().targetedURL()!
        ) {
            main.addItem(
                NSMenuItem(
                    title: "New File".localize(),
                    action: #selector(createFile(_:))
                )
            )
            
            if !spaceController.isEmptyTargetURL() {
                MenuCreator.createPresetMenuItems(
                    menu: main,
                    action: #selector(alterPresetSpace(_:)),
                    container: container
                )
                
                createHiddenFilesDropdown(
                    title: "Show File",
                    main: main,
                    selector: #selector(show(_:))
                )
                
                // Exist customized spaces, add delete menu
                if container.spaces!.count > PresetSpaces.allCases.count {
                    let submenu = NSMenu()
                    let spaceCollectionDropdown = NSMenuItem(
                        title: "Space Collection".localize(),
                        action: nil
                    )
                    
                    main.addItem(spaceCollectionDropdown)
                    main.setSubmenu(submenu, for: spaceCollectionDropdown)
                    
                    MenuCreator.createSpaceCollectionMenu(
                        menu: submenu,
                        switchAction: #selector(alterSpace(_:)),
                        deleteAction: #selector(deleteSpace(_:)),
                        container: container
                    )
                }
            }
        } else {
            main.addItem(
                NSMenuItem(
                    title: "Hide".localize(),
                    action: #selector(hide(_:))
                )
            )
            
            main.addItem(
                NSMenuItem(
                    title: "Show Only".localize(),
                    action: #selector(showOnly(_:))
                )
            )

            main.addItem(
                NSMenuItem(
                    title: "New Space with Selection".localize(),
                    action: #selector(createSpace(_:))
                )
            )
            
            
            let spaces = spaceController.addableSpaces
            
            if spaces.count > 0 {
                let addToDropdown = NSMenuItem(
                    title: "Add to Space".localize(),
                    action: #selector(addToSpace(_:))
                )
                let addToSubmenu = NSMenu()
                
                MenuCreator.createAddMenu(
                    menu: addToSubmenu,
                    action: #selector(addToSpace(_:)),
                    spaces: spaces
                )
                
                main.addItem(addToDropdown)
                main.setSubmenu(addToSubmenu, for: addToDropdown)
                
                if let currentContainer =
                    container.current,
                    !currentContainer.isPreset
                {
                    let moveToDropdown = NSMenuItem(
                        title: "Move to Space".localize(),
                        action: #selector(moveToSpace(_:))
                    )
                    let moveToSubmenu = NSMenu()

                    MenuCreator.createMoveMenu(
                        menu: moveToSubmenu,
                        action: #selector(moveToSpace(_:)),
                        spaces: spaces
                    )

                    main.addItem(moveToDropdown)
                    main.setSubmenu(
                        moveToSubmenu,
                        for: moveToDropdown
                    )
                }
            }
        }
        return main
    }
    
    func createHiddenFilesDropdown(
        title: String,
        main: NSMenu,
        selector: Selector?
    ) {
        var hiddenItems = spaceController.hiddenItems
        
        if hiddenItems.count > 0 {
            let submenu = NSMenu()
            let dropdown = NSMenuItem(
                title: title.localize(),
                action: nil
            )

            main.addItem(dropdown)
            main.setSubmenu(submenu, for: dropdown)
            
            hiddenItems = spaceController.hiddenItems.sorted(by: {
                (item, _item) -> Bool in
                return item.localizedCompare(_item) == .orderedAscending
            })
            
            MenuCreator.createHiddenFileMenu(
                menu: submenu,
                action: selector,
                items: hiddenItems
            )
        }
    }
    
    @IBAction func createFile(_ sender: AnyObject?) {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            [self] in
            NSApplication.shared.activate(ignoringOtherApps: true)
            
            // Replace DialogCreator with TextInputPanelController
            TextInputPanelController.createFileDialog { [self] newFileName in
                if let fileName = newFileName, !fileName.isEmpty {
                    let path = self.spaceController.currentTargetURL?
                        .appendingPathComponent(fileName).path
                    let url = URL(fileURLWithPath: path!)
                    do {
                        try "".write(to: url, atomically: true, encoding: .utf8)
                        NSWorkspace.shared.open(url)
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
    
    @IBAction func createSpace(_ sender: AnyObject?) {
        let items: [URL]? = selectedItems
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            [self] in
            NSApplication.shared.activate(ignoringOtherApps: true)
            
            // Replace DialogCreator with TextInputPanelController
            TextInputPanelController.createSpaceDialog { [self] newSpaceName in
                if let spaceName = newSpaceName, !spaceName.isEmpty {
                    spaceController.create(
                        spaceName: spaceName,
                        items: items
                    )
                }
            }
        }
    }
    
    @IBAction func alterSpace(_ sender: AnyObject?) {
        guard let menuItem = sender as? NSMenuItem else { return }
        let tag = menuItem.tag
        
        if let spaceNames = UserDefaults.spaceDefaults.array(forKey: "CustomSpaceNames") as? [String],
           tag >= 0 && tag < spaceNames.count {
            let spaceName = spaceNames[tag]
            spaceController.alter(spaceName: spaceName)
        }
    }
    
    @IBAction func alterPresetSpace(_ sender: AnyObject?) {
        spaceController.alterPreset(spaceName: sender!.title)
    }
    
    @IBAction func deleteSpace(_ sender: AnyObject?) {
        guard let menuItem = sender as? NSMenuItem else { return }
        let tag = menuItem.tag
        
        if let spaceNames = UserDefaults.spaceDefaults.array(forKey: "CustomSpaceNames") as? [String],
           tag >= 0 && tag < spaceNames.count {
            let spaceName = spaceNames[tag]
            
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                [self] in
                NSApplication.shared.activate(ignoringOtherApps: true)
                
                TextInputPanelController.deleteSpaceDialog(
                    spaceName: spaceName
                ) { [self] confirmed in
                    if confirmed {
                        spaceController.delete(spaceName: spaceName)
                    }
                }
            }
        }
    }
    
    @IBAction func addToSpace(_ sender: NSMenuItem?) {
        spaceController.addItems(
            spaceName: sender!.title,
            items: selectedItems
        )
    }
    
    @IBAction func moveToSpace(_ sender: NSMenuItem?) {
        spaceController.moveItems(
            spaceName: sender!.title,
            items: selectedItems
        )
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
        spaceController.replace(
            item: sender!.title,
            items: selectedItems
        )
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
