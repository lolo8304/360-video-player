//
//  EditVideoViewController.swift
//  SecondScreen
//
//  Created by Lorenz Hänggi on 01.02.17.
//  Copyright © 2017 Lorenz Hänggi. All rights reserved.
//

import UIKit
import SecondScreenShared

class EditVideoViewController: UIViewController, UINavigationControllerDelegate, NamedListViewControllerDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate {
    
    public var video: Video?
    @IBOutlet weak var titleLabel: UITextField!
    @IBOutlet weak var mediaExtLabel: UITextField!
    @IBOutlet weak var languageLabel: UITextField!
    @IBOutlet weak var versionLabel: UITextField!
    @IBOutlet weak var typeLabel: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = self.video?.name
        titleLabel.delegate = self
        mediaExtLabel.text = self.video?.mediaExt
        mediaExtLabel.delegate = self
        languageLabel.text = self.video?.language
        languageLabel.delegate = self
        versionLabel.text = self.video?.version
        versionLabel.delegate = self
        
        //typeLabel.text = self.video?.type .... does not exists yet
        typeLabel.delegate = self

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if (textField == self.languageLabel) {
            let controller = NamedListViewController(style: .plain, name: "Language", defaultValue: (self.video?.language)!, list: Video.LANGUAGES)
            controller.delegate = self
            self.navigationController?.pushViewController(controller, animated: true)
            return false
        } else if (textField == self.mediaExtLabel) {
            let controller = NamedListViewController(style: .plain, name: "Extension", defaultValue: (self.video?.mediaExt)!, list: Video.MEDIA_EXT)
            controller.delegate = self
            self.navigationController?.pushViewController(controller, animated: true)
            return false
        } else if (textField == self.typeLabel) {
            let controller = NamedListViewController(style: .plain, name: "360 type", defaultValue: "_360", list: Video._360_TYPES)
            controller.delegate = self
            self.navigationController?.pushViewController(controller, animated: true)
            return false
        } else if (textField == self.versionLabel) {
            let controller = NamedListViewController(style: .plain, name: "Version", defaultValue: (self.video?.version)!, list: Video.VERSIONS)
            controller.delegate = self
            self.navigationController?.pushViewController(controller, animated: true)
            return false
        }
        return true
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        self.video!.name = self.titleLabel.text
        self.video!.mediaExt = self.mediaExtLabel.text
        self.video!.language = self.languageLabel.text
        self.video!.version = self.versionLabel.text
        
        if (Content.instance.updateVideo(self.video!)) {
            self.navigationController!.popViewController(animated: true)
        } else {
            let alert = UIAlertController(title: "Alert", message: "Name '\(self.video!.name!)' is already used", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }

    }
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        self.navigationController!.popViewController(animated: true)

    }
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    func namedListSelection(sender: NamedListViewController, name: String, selectedValue: String) {
        if (name == "Language") {
            self.languageLabel.text = selectedValue
        }
        if (name == "Extension") {
            self.mediaExtLabel.text = selectedValue
        }
        if (name == "360 type") {
            self.typeLabel.text = selectedValue
        }
        if (name == "Version") {
            self.versionLabel.text = selectedValue
        }
        self.navigationController!.popViewController(animated: true)
    }

}
