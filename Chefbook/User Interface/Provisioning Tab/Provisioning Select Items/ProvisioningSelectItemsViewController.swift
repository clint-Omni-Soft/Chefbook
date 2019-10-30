//
//  ProvisioningSelectItemsViewController.swift
//  Chefbook
//
//  Created by Clint Shank on 10/28/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit

class ProvisioningSelectItemsViewController: UIViewController
{
    // MARK: Public Variables
    
    var     indexOfProvision = NO_SELECTION   // Set by our parent
    
    
    @IBOutlet weak var myTableView: UITableView!
    
    
    
    // MARK: Private Variables
    
    private let cellID = "ProvisioningSelectItemsCell"
    
    private let STORYBOARD_ID_PROVISION_QUANITY_EDITOR = "ProvisioningQuantityViewController"
    
    private struct CellTags {
        static let title     = 10
        static let detail    = 11
        static let checkmark = 12
    }
    
    private var dataModified = false
    private var myProvision  : Provision!
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logTrace()

        self.navigationItem.title = NSLocalizedString( "Title.ProvisioningSelectItems", comment: "Select Items" )
        loadBarButtonItems()

        dataModified = false
        myProvision  = ChefbookCentral.sharedInstance.provisionArray[indexOfProvision]
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        logTrace()
        
        if !ChefbookCentral.sharedInstance.didOpenDatabase {
            presentAlert( title   : NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                          message : NSLocalizedString( "AlertMessage.DatabaseNotOpen", comment: "Fatal Error!  Database is NOT open." ))
        }
        
    }
    

    
    // MARK: Target / Action Methods
    
    @IBAction @objc func nextBarButtonItemTouched( barButtonItem: UIBarButtonItem ) {
        logTrace()
        launchProvisionQuantityEditor()
    }

    
    
    // MARK: Utility Methods

    private func launchProvisionQuantityEditor() {
        
        logTrace()
        
        if let quantityEditorVC : ProvisioningQuantityViewController = iPhoneViewControllerWithStoryboardId( storyboardId: STORYBOARD_ID_PROVISION_QUANITY_EDITOR ) as? ProvisioningQuantityViewController {
            
            quantityEditorVC.myProvision = myProvision
            
            let backItem = UIBarButtonItem()
            
            backItem.title = NSLocalizedString( "ButtonTitle.Back", comment: "Back" )
            navigationItem.backBarButtonItem = backItem
            
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                
                let detailNavigationViewController = ( ( (self.splitViewController?.viewControllers.count)! > 1 ) ? self.splitViewController?.viewControllers[1] : nil ) as? UINavigationController
                
                detailNavigationViewController?.viewControllers = [quantityEditorVC]
                
                DispatchQueue.main.asyncAfter(deadline: ( .now() + 0.2 ), execute: {
//                    NotificationCenter.default.post( name: NSNotification.Name( rawValue: NOTIFICATION_RECIPE_SELECTED ), object: self )
                })
                
            }
            else {
                navigationController?.pushViewController( quantityEditorVC, animated: true )
            }
            
        }
        else {
            logTrace( "ERROR: Could NOT load ProvisioningSelectItemsViewController!" )
        }
        
    }

    
    
    private func loadBarButtonItems() {
        logTrace()
        let     nextBarButtonItem  = UIBarButtonItem.init( title : NSLocalizedString( "ButtonTitle.Next", comment: "Next" ),
                                                           style : .plain,
                                                           target: self,
                                                           action: #selector( nextBarButtonItemTouched ) )
        
        navigationItem.rightBarButtonItem = nextBarButtonItem
    }
    
    
}



// MARK: UITableViewDataSource Methods

extension ProvisioningSelectItemsViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let     chefbookCentral = ChefbookCentral.sharedInstance
        let     numberOfRows    = chefbookCentral.didOpenDatabase ? chefbookCentral.recipeArray.count : 0
        
        logVerbose( "[ %d ]", numberOfRows )
        return numberOfRows
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let     cell               = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        let     titleLabel         = cell.viewWithTag(CellTags.title)     as! UILabel
        let     detailLabel        = cell.viewWithTag(CellTags.detail)    as! UILabel
        let     checkmarkImageView = cell.viewWithTag(CellTags.checkmark) as! UIImageView
        let     recipe: Recipe     = ChefbookCentral.sharedInstance.recipeArray[indexPath.row]
        
        titleLabel.text  = recipe.name
        detailLabel.text = recipe.isFormulaType ? String( format: NSLocalizedString( "LabelText.ProvisioningFormulaFormat",    comment: "Quantity: %d   Item Weight: %d" ), recipe.formulaYieldQuantity, recipe.formulaYieldWeight) :
                                                  String( format: NSLocalizedString( "LabelText.ProvisioningNonFormulaFormat", comment: "Quantity: %@   Options: %@"     ), recipe.yield ?? "Unknown", recipe.yieldOptions ?? "Unknown")
        checkmarkImageView.isHidden = !provisionContains( recipe : recipe )
        
        return cell
    }
    
    
    private func provisionContains( recipe : Recipe ) -> Bool {
        let     elementArray = myProvision.elements?.allObjects as! [ProvisionElement]
        var     foundIt      = false

        for element in elementArray {
            
            if element.recipe?.guid == recipe.guid {
                foundIt = true
                break
            }
            
        }
        
        return foundIt
    }
    
    
}



// MARK: UITableViewDelegate Methods

extension ProvisioningSelectItemsViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let     cell               = tableView.cellForRow(at: indexPath)
        let     chefbookCentral    = ChefbookCentral.sharedInstance
        let     checkmarkImageView = cell?.viewWithTag(CellTags.checkmark) as! UIImageView
        let     isHidden           = !checkmarkImageView.isHidden
        let     recipe             = chefbookCentral.recipeArray[indexPath.row]

        tableView.deselectRow(at: indexPath, animated: false)
        
        if isHidden {
            let     element = elementForRecipe( guid : recipe.guid ?? "" )
            
            chefbookCentral.deleteProvisionElementFrom(provision: myProvision, with: element.guid ?? "Unknown" )
        }
        else {
            chefbookCentral.addProvisionElementTo( provision: myProvision, recipe: recipe, quantity: 1 )
        }
        
        checkmarkImageView.isHidden = isHidden
        dataModified = true
    }
    
    
    private func elementForRecipe( guid : String ) -> ProvisionElement {
        
        let     elementArray     = myProvision.elements?.allObjects as! [ProvisionElement]
        var     requestedElement : ProvisionElement!

        
        for element in elementArray {
            
            if element.recipe?.guid == guid {
                requestedElement = element
                break
            }
            
        }
        
        return requestedElement
    }
    
}


