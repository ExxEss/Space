//
//  Dialog.swift
//  Space
//
//  Created by Yuguo Xie on 16/06/22.
//

import Cocoa

// Custom NSPanel subclass that can become key window
class TextInputPanel: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }
    
    override init(contentRect: NSRect,
                  styleMask style: NSWindow.StyleMask,
                  backing backingStoreType: NSWindow.BackingStoreType,
                  defer flag: Bool) {
        
        super.init(contentRect: contentRect,
                   styleMask: [.titled, .closable, .nonactivatingPanel],
                   backing: backingStoreType, defer: flag)
        
        self.level = .floating
        self.isMovableByWindowBackground = true
        self.becomesKeyOnlyIfNeeded = false
        self.titlebarAppearsTransparent = true
        self.isReleasedWhenClosed = false
    }
}

// View controller for the text input panel
class TextInputViewController: NSViewController {
    private var textField: NSTextField!
    private var createButton: NSButton!
    private var cancelButton: NSButton!
    private var completionHandler: ((String?) -> Void)?
    
    convenience init(placeholder: String, completionHandler: @escaping (String?) -> Void) {
        self.init(nibName: nil, bundle: nil)
        self.completionHandler = completionHandler
        
        // Create text field
        textField = NSTextField(frame: NSRect(x: 20, y: 60, width: 260, height: 24))
        textField.placeholderString = placeholder
        textField.isEditable = true
        textField.isBezeled = true
        
        // Create buttons
        createButton = NSButton(frame: NSRect(x: 180, y: 20, width: 100, height: 24))
        createButton.title = "Create"
        createButton.bezelStyle = .rounded
        createButton.action = #selector(createButtonClicked)
        createButton.target = self
        createButton.keyEquivalent = "\r" // Enter key
        
        cancelButton = NSButton(frame: NSRect(x: 80, y: 20, width: 100, height: 24))
        cancelButton.title = "Cancel"
        cancelButton.bezelStyle = .rounded
        cancelButton.action = #selector(cancelButtonClicked)
        cancelButton.target = self
        cancelButton.keyEquivalent = "\u{1b}" // Escape key
    }
    
    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
        self.view.addSubview(textField)
        self.view.addSubview(createButton)
        self.view.addSubview(cancelButton)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        // Force focus on the text field
        self.view.window?.makeFirstResponder(textField)
    }
    
    @objc func createButtonClicked() {
        completionHandler?(textField.stringValue)
        self.view.window?.close()
    }
    
    @objc func cancelButtonClicked() {
        completionHandler?(nil)
        self.view.window?.close()
    }
}

// Main dialog controller class to replace DialogCreator
class TextInputPanelController: NSWindowController, NSWindowDelegate {
    private static var sharedInstance: TextInputPanelController?
    
    // Factory method to create a space dialog
    static func createSpaceDialog(completion: @escaping (String?) -> Void) {
        setupPanel(placeholder: "Name", title: "Create Space", completion: completion)
    }
    
    // Factory method to create a file dialog
    static func createFileDialog(completion: @escaping (String?) -> Void) {
        setupPanel(placeholder: "File name and suffix", title: "Create File", completion: completion)
    }
    
    private static func setupPanel(placeholder: String, title: String, completion: @escaping (String?) -> Void) {
        // If we already have an instance, close it
        if let existingPanel = sharedInstance {
            existingPanel.window?.close()
        }
        
        // Create panel
        let panelWidth: CGFloat = 300
        let panelHeight: CGFloat = 120
        
        var x: CGFloat = 100
        var y: CGFloat = 100
        
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            x = (screenRect.width - panelWidth) / 2 + screenRect.minX
            y = (screenRect.height - panelHeight) / 2 + screenRect.minY
        }
        
        let panel = TextInputPanel(
            contentRect: NSRect(x: x, y: y, width: panelWidth, height: panelHeight),
            styleMask: [.titled, .closable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.title = title
        
        // Create the content view controller
        let contentViewController = TextInputViewController(placeholder: placeholder, completionHandler: completion)
        panel.contentViewController = contentViewController
        
        // Create the window controller
        sharedInstance = TextInputPanelController(window: panel)
        sharedInstance?.window?.delegate = sharedInstance
        
        // Show the panel
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }
    
    // Delete space dialog
    static func deleteSpaceDialog(spaceName: String, completion: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.addButton(withTitle: "Confirm")
        alert.addButton(withTitle: "Cancel")
        alert.messageText = "Delete Space \"\(spaceName)\"?"
        
        let response = alert.runModal()
        completion(response == .alertFirstButtonReturn)
    }
    
    // Simple alert info
    static func alertInfo(info: String) {
        let alert = NSAlert()
        alert.messageText = info
        alert.runModal()
    }
    
    // Window delegate method
    func windowWillClose(_ notification: Notification) {
        // Clean up resources if needed
    }
}
