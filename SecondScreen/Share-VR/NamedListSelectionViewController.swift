//
//  NamedListViewController.swift
//  deegeu-swift-share-extensions
//
//  Created by Daniel Spiess on 10/26/15.
//  Copyright © 2015 Daniel Spiess. All rights reserved.
//

import UIKit

@objc(NamedListViewControllerDelegate)
public protocol NamedListViewControllerDelegate {
    @objc optional func namedListSelection(
        sender: NamedListViewController,
        name: String,
        selectedValue: String)
}

public class NamedListViewController : UITableViewController {
    
    var namedListSelection: [String] = [ ]
    let tableviewCellIdentifier = "namedListSelectionCell"
    var defaultNamedListSelection : String = ""
    public var delegate: NamedListViewControllerDelegate?
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience public init(style: UITableViewStyle, name: String, defaultValue: String, list: [String]) {
        self.init(style: style)
        title = name
        namedListSelection = list
        defaultNamedListSelection = defaultValue
    }
    
    // Initialize the tableview
    override public init(style: UITableViewStyle) {
        super.init(style: style)
        tableView.register(UITableViewCell.classForCoder(),
                                forCellReuseIdentifier: tableviewCellIdentifier)
    }
    
    // We only have three choices, but there's no reason this tableview can't be populated
    // dynamically from CoreData, NSDefaults, or something else.
    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return namedListSelection.count
    }
    
    
    private func keyFrom(text: String, seperatedBy: String) -> String {
        let keyValue: [String] = text.components(separatedBy: seperatedBy)
        return keyValue.last!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

    }
    // This just populates each row in the table, and if we've selected it, we'll check it
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: tableviewCellIdentifier,
            for: indexPath as IndexPath) as UITableViewCell
        
        let text = namedListSelection[indexPath.row]
        cell.textLabel!.text = text
        
        if defaultNamedListSelection == keyFrom(text: text, seperatedBy: ":") {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    // Save the value the user picks
    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let theDelegate = delegate {
            defaultNamedListSelection = keyFrom(text: namedListSelection[indexPath.row], seperatedBy: ":")
            theDelegate.namedListSelection!(sender: self, name: title!, selectedValue: defaultNamedListSelection)
        }
    }
    
    
}
