//
//  ShareViewController.swift
//  Share-VR
//
//  Created by Lorenz Hänggi on 23.01.17.
//  Copyright © 2017 Lorenz Hänggi. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices
import SecondScreenShared

class ShareViewController: SLComposeServiceViewController, NamedListViewControllerDelegate {

    
    
    private var selectedLanguage: String = "DE"
    private var configLanguage: SLComposeSheetConfigurationItem?

    private var selectedMedia: String = "mp4"
    private var configMedia: SLComposeSheetConfigurationItem?

    private var selected360Type: String = "_360"
    private var config360Type: SLComposeSheetConfigurationItem?
    
    private var selectedVersion: String = "standard"
    private var configVersion: SLComposeSheetConfigurationItem?
    
    override func isContentValid() -> Bool {
        let text = self.contentText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if (text.isEmpty) {
            return false
        } else {
            if (Content.instance.getVideo(name: text) != nil) {
                return false
            }
            return true
        }
        // Do validation of contentText and/or NSExtensionContext attachments here
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.

        // This is called after the user selects Post.
        // Make sure we have a valid extension item
        if let content = extensionContext!.inputItems[0] as? NSExtensionItem {
            let contentType = "public.mpeg-4"
            
            // Verify the provider is valid
            if let contents = content.attachments as? [NSItemProvider] {
                
                // look for images
                for attachment in contents {
                    if attachment.hasItemConformingToTypeIdentifier(contentType) {
                        attachment.loadItem(forTypeIdentifier: contentType, options: nil) { data, error in
                            let url = URL(string: (data as! NSURL).absoluteString!)!
                            NSLog("add new video from URL \(url)")
                            let newVideo: Video = Video(context: managedObjectContext)
                                    .from(name: "\(self.contentText!)", mediaURL: url, mediaExt: self.selectedMedia, language: self.selectedLanguage, duratinInS: 0, sizeInBytes: 0)
                            newVideo.version = self.selectedVersion
                            Content.instance.addNewVideo(newVideo)
                            NSLog("video added - \(self.contentText!)\(self.selected360Type)")
                        }
                    }
                }
            }
        }
        
        
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    
    /* ------------------------------------------------------------------------------------ */
    /* Language code */
    func getConfigLanguage() -> SLComposeSheetConfigurationItem {
        if (self.configLanguage == nil) {
            let config: SLComposeSheetConfigurationItem = SLComposeSheetConfigurationItem()
            config.title = "Language"
            config.value = self.selectedLanguage
            config.tapHandler = self.namedListSelection
            self.configLanguage = config
        }
        return self.configLanguage!
    }
    func namedListSelection() {
        let controller = NamedListViewController(style: .plain, name: "Language", defaultValue: self.selectedLanguage, list: Video.LANGUAGES)
        controller.delegate = self
        pushConfigurationViewController(controller)
    }
    
    /* ------------------------------------------------------------------------------------ */
    /* Media code */
    func getConfigMedia() -> SLComposeSheetConfigurationItem {
        if (self.configMedia == nil) {
            let config: SLComposeSheetConfigurationItem = SLComposeSheetConfigurationItem()
            config.title = "Media"
            config.value = self.selectedMedia
            config.tapHandler = self.mediaSelection
            self.configMedia = config
        }
        return self.configMedia!
    }
    func mediaSelection() {
        let controller = NamedListViewController(style: .plain, name: "Media", defaultValue: self.selectedMedia, list: Video.MEDIA_EXT)
        controller.delegate = self
        pushConfigurationViewController(controller)
    }
    
    /* ------------------------------------------------------------------------------------ */
    /* 360 type code */
    func getConfig360Type() -> SLComposeSheetConfigurationItem {
        if (self.config360Type == nil) {
            let config: SLComposeSheetConfigurationItem = SLComposeSheetConfigurationItem()
            config.title = "360 type"
            config.value = self.selected360Type
            config.tapHandler = self._360TypeSelection
            self.config360Type = config
        }
        return self.config360Type!
    }
    func _360TypeSelection() {
        let controller = NamedListViewController(style: .plain, name: "360 type", defaultValue: self.selected360Type, list: Video._360_TYPES)
        controller.delegate = self
        pushConfigurationViewController(controller)
    }
    
    /* ------------------------------------------------------------------------------------ */
    /* version */
    func getConfigVersion() -> SLComposeSheetConfigurationItem {
        if (self.configVersion == nil) {
            let config: SLComposeSheetConfigurationItem = SLComposeSheetConfigurationItem()
            config.title = "Version"
            config.value = self.selectedVersion
            config.tapHandler = self.versionSelection
            self.configVersion = config
        }
        return self.configVersion!
    }
    func versionSelection() {
        let controller = NamedListViewController(style: .plain, name: "Version", defaultValue: self.selectedVersion, list: Video.VERSIONS)
        controller.delegate = self
        pushConfigurationViewController(controller)
    }
    
    /* ------------------------------------------------------------------------------------ */

    func namedListSelection(sender: NamedListViewController, name: String, selectedValue: String) {
        if (name == "Language") {
            self.getConfigLanguage().value = selectedValue
            self.selectedLanguage = selectedValue
        } else if (name == "Media") {
            self.getConfigMedia().value = selectedValue
            self.selectedMedia = selectedValue
        } else if (name == "360 type") {
            self.getConfig360Type().value = selectedValue
            self.selected360Type = selectedValue
        } else if (name == "Version") {
            self.getConfigVersion().value = selectedValue
            self.selectedVersion = selectedValue
        }
        popConfigurationViewController()
    }

    
    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return [
            self.getConfigLanguage(),
            self.getConfigVersion(),
            self.getConfigMedia(),
            self.getConfig360Type()
        ]
    }

}

