//
//  LanguageSelectionViewController.swift
//  deegeu-swift-share-extensions
//
//  Created by Daniel Spiess on 10/26/15.
//  Copyright © 2015 Daniel Spiess. All rights reserved.
//

import UIKit

@objc(LanguageSelectionViewControllerDelegate)
protocol LanguageSelectionViewControllerDelegate {
    @objc optional func languageSelection(
        sender: LanguageSelectionViewController,
        selectedValue: String)
}

class LanguageSelectionViewController : UITableViewController {
    
    let languageSelection = [ "DE", "EN", "FR" ]
    let tableviewCellIdentifier = "languageSelectionCell"
    var selectedLanguageName : String = "DE"
    var delegate: LanguageSelectionViewControllerDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // Initialize the tableview
    override init(style: UITableViewStyle) {
        super.init(style: style)
        tableView.register(UITableViewCell.classForCoder(),
                                forCellReuseIdentifier: tableviewCellIdentifier)
        title = "Video Language"
    }
    
    // We only have three choices, but there's no reason this tableview can't be populated
    // dynamically from CoreData, NSDefaults, or something else.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    // This just populates each row in the table, and if we've selected it, we'll check it
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: tableviewCellIdentifier,
            for: indexPath as IndexPath) as UITableViewCell
        
        let text = languageSelection[indexPath.row]
        cell.textLabel!.text = text
        
        if text == selectedLanguageName {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    // Save the value the user picks
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let theDelegate = delegate {
            selectedLanguageName = languageSelection[indexPath.row]
            theDelegate.languageSelection!(sender: self, selectedValue: selectedLanguageName)
        }
    }
    
    
}
