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
                   styleMask: [.titled, .closable, .nonactivatingPanel, .fullSizeContentView],
                   backing: backingStoreType, defer: flag)
        
        self.level = .floating
        self.isMovableByWindowBackground = true
        self.becomesKeyOnlyIfNeeded = false
        self.titlebarAppearsTransparent = true
        self.isReleasedWhenClosed = false
    }
}

class CustomTextFieldCell: NSTextFieldCell {

    private static let padding = CGSize(width: 3.0, height: 3.0)

    override func cellSize(forBounds rect: NSRect) -> NSSize {
        var size = super.cellSize(forBounds: rect)
        size.height += (CustomTextFieldCell.padding.height * 2)
        return size
    }

    override func titleRect(forBounds rect: NSRect) -> NSRect {
        return rect.insetBy(dx: CustomTextFieldCell.padding.width, dy: CustomTextFieldCell.padding.height)
    }

    override func edit(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, event: NSEvent?) {
        let insetRect = rect.insetBy(dx: CustomTextFieldCell.padding.width, dy: CustomTextFieldCell.padding.height)
        super.edit(withFrame: insetRect, in: controlView, editor: textObj, delegate: delegate, event: event)
    }

    override func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int) {
        let insetRect = rect.insetBy(dx: CustomTextFieldCell.padding.width, dy: CustomTextFieldCell.padding.height)
        super.select(withFrame: insetRect, in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength)
    }

    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        let insetRect = cellFrame.insetBy(dx: CustomTextFieldCell.padding.width, dy: CustomTextFieldCell.padding.height)
        super.drawInterior(withFrame: insetRect, in: controlView)
    }

}

// View controller for the text input panel
class TextInputViewController: NSViewController {
    private var appIconView: NSImageView!
    private var textField: NSTextField!
    private var createButton: NSButton!
    private var cancelButton: NSButton!
    private var completionHandler: ((String?) -> Void)?
    
    convenience init(placeholder: String, completionHandler: @escaping (String?) -> Void) {
        self.init(nibName: nil, bundle: nil)
        self.completionHandler = completionHandler

        // App Icon
        let appIcon = NSImage(named: NSImage.applicationIconName) ?? NSImage()
        appIconView = NSImageView(image: appIcon)
        appIconView.imageScaling = .scaleProportionallyUpOrDown
        appIconView.translatesAutoresizingMaskIntoConstraints = false
        appIconView.wantsLayer = true
        appIconView.layer?.cornerRadius = 8
        appIconView.layer?.masksToBounds = true

        // Text Field
        textField = NSTextField()
        textField.cell = CustomTextFieldCell()
        textField.stringValue = ""
        textField.placeholderString = placeholder
        textField.isEditable = true
        textField.isBezeled = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        let createButtonTitle = placeholder == "Space name"
            ? "Create & Switch"
            : "Create & Open"

        // Buttons
        createButton = NSButton(title: createButtonTitle, target: self, action: #selector(createButtonClicked))
        createButton.bezelStyle = .regularSquare
        createButton.keyEquivalent = "\r"
        createButton.translatesAutoresizingMaskIntoConstraints = false
        createButton.setContentHuggingPriority(.defaultLow, for: .horizontal)

        cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelButtonClicked))
        cancelButton.bezelStyle = .regularSquare
        cancelButton.keyEquivalent = "\u{1b}"
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setContentHuggingPriority(.defaultLow, for: .horizontal)

    }

    override func loadView() {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = .popover
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false

        self.view = visualEffectView

        view.setFrameSize(NSSize(width: 340, height: 224))

        // Horizontal Button Stack
        let buttonStack = NSStackView(views: [cancelButton, createButton])
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 20
        buttonStack.alignment = .centerY
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        // Main Vertical Stack
        let mainStack = NSStackView(views: [appIconView, textField, buttonStack])
        mainStack.orientation = .vertical
        mainStack.spacing = 20
        mainStack.alignment = .centerX
        mainStack.edgeInsets = NSEdgeInsets(top: 40, left: 20, bottom: 20, right: 20)
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        // Add to view
        view.addSubview(mainStack)

        // Constraints
        NSLayoutConstraint.activate([
            // Icon size
            appIconView.widthAnchor.constraint(equalToConstant: 64),
            appIconView.heightAnchor.constraint(equalToConstant: 64),

            // TextField width
            textField.widthAnchor.constraint(equalToConstant: 180),
            textField.heightAnchor.constraint(equalToConstant: 30),

            // Button widths to match layout rule
            createButton.widthAnchor.constraint(equalToConstant: 140),
            cancelButton.widthAnchor.constraint(equalToConstant: 140),
            createButton.heightAnchor.constraint(equalToConstant: 30),
            cancelButton.heightAnchor.constraint(equalToConstant: 30),

            // Main stack layout
            mainStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainStack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
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
        setupPanel(placeholder: "Space name", title: "Create Space", completion: completion)
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
            y = (screenRect.height + panelHeight) / 2 + screenRect.minY
        }
        
        let panel = TextInputPanel(
            contentRect: NSRect(x: x, y: y, width: panelWidth, height: panelHeight),
            styleMask: [.titled, .closable, .miniaturizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.title = title
        panel.titlebarAppearsTransparent = true
        
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
