//
//  ShareViewController.swift
//  Share-VR
//
//  Created by Lorenz Hänggi on 23.01.17.
//  Copyright © 2017 Lorenz Hänggi. All rights reserved.
//

import UIKit
import Social

class ShareViewController: SLComposeServiceViewController, LanguageSelectionViewControllerDelegate {

    private var selectedLanguage: String = "DE"
    private var configLanguage: SLComposeSheetConfigurationItem?
    
    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    func getConfigLanguage() -> SLComposeSheetConfigurationItem {
        if (self.configLanguage == nil) {
            let config: SLComposeSheetConfigurationItem = SLComposeSheetConfigurationItem()
            config.title = "Language"
            config.value = self.selectedLanguage
            config.tapHandler = self.languageSelection
            self.configLanguage = config
        }
        return self.configLanguage!
    }
    
    func languageSelection() {
        let controller = LanguageSelectionViewController(style: .plain)
        controller.selectedLanguageName = "DE"
        controller.delegate = self
        pushConfigurationViewController(controller)
    }

    func languageSelection(sender: LanguageSelectionViewController, selectedValue: String) {
        self.getConfigLanguage().value = selectedValue
        self.selectedLanguage = selectedValue
        popConfigurationViewController()
    }

    
    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return [
            self.getConfigLanguage()
        ]
    }

}

