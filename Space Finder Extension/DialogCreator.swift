//
//  Dialog.swift
//  Space
//
//  Created by Yuguo Xie on 16/06/22.
//

import Cocoa

class PaddedTextFieldCell: NSTextFieldCell {

    @IBInspectable var topPadding: CGFloat = 10.0

    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        let rectInset = NSMakeRect(rect.origin.x,
                                   rect.origin.y + topPadding,
                                   rect.size.width,
                                   rect.size.height - topPadding)
        return super.drawingRect(forBounds: rectInset)
    }
}

class DialogCreator {
    static func createSpaceDialog() -> String {
        let alert = NSAlert()
        alert.addButton(withTitle: "Create".localize())
        alert.addButton(withTitle: "Cancel".localize())
        alert.messageText = ""
        
        let textField = NSTextField(
            frame: NSRect(x: 0, y: 0,
                          width: alert.window.frame.size.width * 0.6,
                          height: 24)
        )
        
        let paddedTextField = PaddedTextFieldCell(textCell: "")
        paddedTextField.accessibilityDefaultButton()
        paddedTextField.topPadding = 1
        textField.cell = paddedTextField
        textField.isBezeled = true
        textField.isEditable = true
        textField.placeholderString = "Name".localize()

        alert.accessoryView = textField
        alert.window.initialFirstResponder = textField
        
        let response: NSApplication.ModalResponse = alert.runModal()

        if (response ==
            NSApplication.ModalResponse.alertFirstButtonReturn) {
            return textField.stringValue
        }
        return ""
    }
    
    static func deleteSpaceDialog(spaceName: String) -> Bool {
        let alert = NSAlert()
        alert.addButton(withTitle: "Confirm".localize())
        alert.addButton(withTitle: "Cancel".localize())
        alert.messageText = "Delete Space".localize() + " \"\(spaceName)\"?"
        
        let response: NSApplication.ModalResponse = alert.runModal()

        if (response ==
            NSApplication.ModalResponse.alertFirstButtonReturn) {
            return true
        }
        return false
    }
    
    static func alertInfo(info: String) {
        let alert = NSAlert()
        alert.messageText = info
        alert.runModal()
    }
}
