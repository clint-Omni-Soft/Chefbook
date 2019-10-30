//
//  ProvisioningViewController.swift
//  Chefbook
//
//  Created by Clint Shank on 10/29/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//


import UIKit


class ProvisioningViewController: UIViewController
{
    
    @IBOutlet weak var myTableView: UITableView!

    
    
    // MARK: Private Variables
    
    private let STORYBOARD_ID_PROVISION_SELECT_ITEMS = "ProvisioningSelectItemsViewController"

    private let cellID = "ProvisioningTableViewCell"

    private var addRequested            = false
    private var indexOfItemBeingEdited  = NEW_PROVISION
    
    

    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logTrace()
        
        self.navigationItem.title = NSLocalizedString( "Title.Provisioning", comment: "Provisioning" )
    }
    

    override func viewWillAppear(_ animated: Bool ) {
        
        super.viewWillAppear( animated )
        logTrace()
        
        let     chefbookCentral = ChefbookCentral.sharedInstance
        
        chefbookCentral.delegate = self
        
        if !chefbookCentral.didOpenDatabase {
            chefbookCentral.openDatabase()
        }
        else {
            myTableView.reloadData()
        }
        
        loadBarButtonItems()
    }
    
    
    override func didReceiveMemoryWarning() {
        logTrace( "WARNING!" )
    }

    

    // MARK: Target / Action Methods
    
    @IBAction @objc func addBarButtonItemTouched( barButtonItem: UIBarButtonItem ) {
        logTrace()
        promptForName( currentName : "" )
    }
    
    
    
    // MARK: Utility Methods
    
    private func loadBarButtonItems() {
        logTrace()
        let     addBarButtonItem  = UIBarButtonItem.init( barButtonSystemItem : .add,
                                                          target              : self,
                                                          action              : #selector( addBarButtonItemTouched ) )
        
        navigationItem.rightBarButtonItem = addBarButtonItem
    }
    
    
    private func promptForName( currentName : String ) {
        logTrace()
        addRequested = currentName.isEmpty
        
        let     alert = UIAlertController.init( title: NSLocalizedString( "AlertTitle.EditProvisionName", comment: "Edit provision name" ),
                                                message: nil,
                                                preferredStyle: .alert)
        
        let     saveAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Save", comment: "Save" ), style: .default )
        { ( alertAction ) in
            logTrace( "Save Action" )
            let     nameTextField = alert.textFields![0] as UITextField
            
            if var textStringName = nameTextField.text {
                
                textStringName = textStringName.trimmingCharacters( in: .whitespacesAndNewlines )
                
                if !textStringName.isEmpty {
                    logTrace( "We have a non-zero length string" )
                    
                    if textStringName == currentName {
                        logTrace( "No changes ... do nothing!" )
                        return
                    }
                    
                    if self.unique( provisionName: textStringName ) {
                        let chefbookCentral = ChefbookCentral.sharedInstance
                        
                        if self.addRequested {
                            chefbookCentral.addProvisionWith(name: textStringName )
                        }
                        else {
                            let provision = chefbookCentral.provisionArray[self.indexOfItemBeingEdited]
                            
                            provision.name = textStringName
                            chefbookCentral.saveUpdatedProvision(provision: provision)
                        }
                        
                    }
                    else {
                        logTrace( "ERROR:  Duplicate name field!" )
                        self.presentAlert( title:   NSLocalizedString( "AlertTitle.Error",                    comment: "Error!" ),
                                           message: NSLocalizedString( "AlertMessage.DuplicateProvisionName", comment: "The provision name you choose already exists.  Please try again." ) )
                    }
                    
                }
                else {
                    logTrace( "ERROR:  Name field cannot be left blank!" )
                    self.presentAlert( title:   NSLocalizedString( "AlertTitle.Error",               comment: "Error!" ),
                                       message: NSLocalizedString( "AlertMessage.NameCannotBeBlank", comment: "Name field cannot be left blank" ) )
                }
                
            }
            
        }
            
        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel, handler: nil )
        
        alert.addTextField
            { ( textField ) in
                
                if currentName.isEmpty {
                    textField.placeholder = NSLocalizedString( "LabelText.Name", comment: "Name" )
                }
                else {
                    textField.text = currentName
                }
                
                textField.autocapitalizationType = .words
        }
        
        alert.addAction( saveAction   )
        alert.addAction( cancelAction )
        
        present( alert, animated: true, completion: nil )
}
    
    
    private func unique( provisionName: String ) -> Bool {
        
        let     chefbookCentral   = ChefbookCentral.sharedInstance
        var     numberOfInstances = 0
        
        for provision in chefbookCentral.provisionArray {
            
            if ( provisionName.uppercased() == provision.name?.uppercased() ) {
                
                if indexOfItemBeingEdited == NEW_RECIPE {
                    logTrace( "Found a duplicate! [New]." )
                    numberOfInstances += 1
                }
                else {
                    let     provisionBeingEdited = chefbookCentral.provisionArray[indexOfItemBeingEdited]
                    
                    if provision.guid != provisionBeingEdited.guid
                    {
                        logTrace( "Found a duplicate! [Existing]." )
                        numberOfInstances += 1
                    }
                    
                }
                
            }
            
        }
        
        return ( numberOfInstances == 0 )
    }
    

}



// MARK: ChefbookCentralDelegate Methods

extension ProvisioningViewController : ChefbookCentralDelegate {

    func chefbookCentral(chefbookCentral: ChefbookCentral, didOpenDatabase: Bool) {
        
        logVerbose( "[ %@ ]", stringFor( didOpenDatabase ) )
        
        if didOpenDatabase {
            chefbookCentral.fetchRecipes()
        }
        else {
            presentAlert( title:   NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                          message: NSLocalizedString( "AlertMessage.CannotOpenDatabase", comment: "Fatal Error!  Cannot open database." ) )
        }
        
    }
    
    
    func chefbookCentralDidReloadProvisionArray(chefbookCentral: ChefbookCentral) {
        indexOfItemBeingEdited = chefbookCentral.selectedProvisionIndex
        myTableView.reloadData()
    }
    
    
    func chefbookCentralDidReloadRecipeArray(chefbookCentral: ChefbookCentral) {
        logVerbose( "loaded [ %d ] recipes", chefbookCentral.recipeArray.count )
        chefbookCentral.fetchProvisions()
    }

}



// MARK: ProvisioningTableViewCellDelegate Methods

extension ProvisioningViewController : ProvisioningTableViewCellDelegate {
    
    func provisioningTableViewCell( provisioningTableViewCell: ProvisioningTableViewCell,
                                    editedName               : String,
                                    forRowAt index           : Int ) {
        logVerbose( "[ %d ][ %@ ]", index, editedName )
        let chefbookCentral = ChefbookCentral.sharedInstance
        
        if addRequested {
            addRequested = false
            chefbookCentral.addProvisionWith( name: editedName )
        }
        else {
            let provision = chefbookCentral.provisionArray[index]
            
            provision.name = editedName
            chefbookCentral.saveUpdatedProvision(provision: provision)
        }
        
    }
    
    
}



// MARK: UITableViewDataSource Methods

extension ProvisioningViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let     numberOfRows = ChefbookCentral.sharedInstance.provisionArray.count
        
        return numberOfRows
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID ) as! ProvisioningTableViewCell
        let provision = ChefbookCentral.sharedInstance.provisionArray[indexPath.row]
        
        cell.initializeWith( provisionName : provision.name!,
                             rowIndex      : indexPath.row,
                             delegate      : self)
        return cell
    }
    
    
    func tableView(_ tableView              : UITableView,
                   canEditRowAt indexPath : IndexPath ) -> Bool {
        return true
    }
    
    
    func tableView(_ tableView           : UITableView,
                   commit editingStyle : UITableViewCell.EditingStyle,
                   forRowAt indexPath  : IndexPath ) {
        
        if editingStyle == .delete {
            
            logVerbose( "delete provision at row [ %d ]", indexPath.row )
//            if UIDevice.current.userInterfaceIdiom == .pad {
//
//                let detailNavigationViewController = ( ( (self.splitViewController?.viewControllers.count)! > 1 ) ? self.splitViewController?.viewControllers[1] : nil ) as? UINavigationController
//
//                detailNavigationViewController?.viewControllers = []
//            }
            
            DispatchQueue.main.asyncAfter(deadline: ( .now() + 0.2 ), execute: {
                ChefbookCentral.sharedInstance.deleteProvisionAtIndex( index: indexPath.row )
            })
            
        }
        
    }
    
    
}



// MARK: UITableViewDelegate Methods

extension ProvisioningViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        logTrace()
        indexOfItemBeingEdited = indexPath.row
        launchProvisionEditorFor(index: indexPath.row )
    }
    

    private func launchProvisionEditorFor( index: Int ) {
        logVerbose( "[ %d ]", index )
        
        if let selectItemsVC : ProvisioningSelectItemsViewController = iPhoneViewControllerWithStoryboardId( storyboardId: STORYBOARD_ID_PROVISION_SELECT_ITEMS ) as? ProvisioningSelectItemsViewController {
            
            selectItemsVC.indexOfProvision = index
            
            let backItem = UIBarButtonItem()
            
            backItem.title = NSLocalizedString( "ButtonTitle.Back", comment: "Back" )
            navigationItem.backBarButtonItem = backItem 

            
            if UIDevice.current.userInterfaceIdiom == .pad {
                
                let detailNavigationViewController = ( ( (self.splitViewController?.viewControllers.count)! > 1 ) ? self.splitViewController?.viewControllers[1] : nil ) as? UINavigationController
                
                detailNavigationViewController?.viewControllers = [selectItemsVC]
                
                DispatchQueue.main.asyncAfter(deadline: ( .now() + 0.2 ), execute: {
//                    NotificationCenter.default.post( name: NSNotification.Name( rawValue: NOTIFICATION_RECIPE_SELECTED ), object: self )
                })
                
            }
            else {
                navigationController?.pushViewController( selectItemsVC, animated: true )
            }
            
        }
        else {
            logTrace( "ERROR: Could NOT load ProvisioningSelectItemsViewController!" )
        }
        
    }
    
    
}



