//
//  ViewController.swift
//  Space
//
//  Created by Yuguo Xie on 25/07/22.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

   
    @IBAction func openExtensionPreferences(_ sender: Any) {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Extensions.prefPane"))
    }
}

