//
//  RecipeListViewController.swift
//  Chefbook
//
//  Created by Clint Shank on 7/26/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit

class RecipeListViewController: UIViewController
{
    
    @IBOutlet weak var myTableView: UITableView!
    
    private let     CELL_ID                         = "RecipeListViewControllerCell"
    private let     CELL_TAG_LABEL_NAME             = 11
    private let     CELL_TAG_IMAGE_VIEW             = 12
    private let     STORYBOARD_ID_FORMULA_EDITOR    = "FormulaEditorViewController"
    private let     STORYBOARD_ID_RECIPE_EDITOR     = "StandardRecipeEditorViewController"
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logTrace()
        
        self.navigationItem.title = NSLocalizedString( "Title.RecipeList", comment: "Recipes" )
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
        
        NotificationCenter.default.addObserver( self,
                                                selector: #selector( RecipeListViewController.recipesUpdated( notification: ) ),
                                                name:     NSNotification.Name( rawValue: NOTIFICATION_RECIPES_UPDATED ),
                                                object:   nil )
    }
    
    
    override func viewWillDisappear(_ animated: Bool ) {
        logTrace()
        super.viewWillDisappear( animated )
        
        NotificationCenter.default.removeObserver( self )
    }
    
    
    override func didReceiveMemoryWarning() {
        logTrace( "WARNING!" )
    }
    
    
    
    // MARK: NSNotification Methods
    
    @objc func recipesUpdated( notification: NSNotification ) {
        logTrace()
        
        // The reason we are using Notifications is because this view can be up in two different places on the iPad at the same time.
        // This approach allows a change in one to immediately be reflected in the other.
        
        myTableView.reloadData()
    }
    
    
    
    // MARK: Target / Action Methods
    
    @IBAction @objc func addBarButtonItemTouched( barButtonItem: UIBarButtonItem ) {
        logTrace()
        promptForRecipeType( barButtonItem : barButtonItem )
    }

    
    
    // MARK: Utility Methods
    
    private func launchFormulaEditorFor(_ index: Int ) {
        
        logVerbose( "[ %d ]", index )
        if let formulaEditorVC: FormulaEditorViewController = iPhoneViewControllerWithStoryboardId( storyboardId: STORYBOARD_ID_FORMULA_EDITOR ) as? FormulaEditorViewController {
            
            formulaEditorVC.recipeIndex = index
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                
                let detailNavigationViewController = ( ( (self.splitViewController?.viewControllers.count)! > 1 ) ? self.splitViewController?.viewControllers[1] : nil ) as? UINavigationController
                
                detailNavigationViewController?.viewControllers = [formulaEditorVC]
                
                DispatchQueue.main.asyncAfter(deadline: ( .now() + 0.2 ), execute: {
                    NotificationCenter.default.post( name: NSNotification.Name( rawValue: NOTIFICATION_RECIPE_SELECTED ), object: self )
                })

            }
            else {
                navigationController?.pushViewController( formulaEditorVC, animated: true )
            }
            
        }
        else {
            logTrace( "ERROR!  Could NOT load the FormulaEditorViewController!" )
        }
        
    }
    
    
    private func launchRecipeEditorFor(_ index: Int ) {
        logVerbose( "[ %d ]", index )
        
        if let recipeEditorVC: StandardRecipeEditorViewController = iPhoneViewControllerWithStoryboardId( storyboardId: STORYBOARD_ID_RECIPE_EDITOR ) as? StandardRecipeEditorViewController {
            
            recipeEditorVC.recipeIndex = index
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                
                let detailNavigationViewController = ( ( (self.splitViewController?.viewControllers.count)! > 1 ) ? self.splitViewController?.viewControllers[1] : nil ) as? UINavigationController
                
                detailNavigationViewController?.viewControllers = [recipeEditorVC]
                
                DispatchQueue.main.asyncAfter(deadline: ( .now() + 0.2 ), execute: {
                        NotificationCenter.default.post( name: NSNotification.Name( rawValue: NOTIFICATION_RECIPE_SELECTED ), object: self )
                })
                
            }
            else {
                navigationController?.pushViewController( recipeEditorVC, animated: true )
            }
            
        }
        else {
            logTrace( "ERROR: Could NOT load RecipeEditorViewController!" )
        }
        
    }
    
    
    private func loadBarButtonItems() {
        logTrace()
        let     addBarButtonItem  = UIBarButtonItem.init( barButtonSystemItem: .add,
                                                          target: self,
                                                          action: #selector( addBarButtonItemTouched ) )
        
        navigationItem.rightBarButtonItem = addBarButtonItem
    }
    
    
    private func promptForRecipeType( barButtonItem: UIBarButtonItem ) {
        logTrace()
        let     alert = UIAlertController.init( title: NSLocalizedString( "AlertTitle.RecipeType", comment: "Recipe Type?" ),
                                                message: nil,
                                                preferredStyle: .actionSheet )
        
        let     standardAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Standard", comment: "Standard" ), style: .default )
        { ( alertAction ) in
            logTrace( "Standard Action" )
            
            self.launchRecipeEditorFor( NEW_RECIPE )
        }
        
        let     formulaAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.BreadFormula", comment: "Bread Formula" ), style: .default )
        { ( alertAction ) in
            logTrace( "Formula Action" )
            
            self.launchFormulaEditorFor( NEW_RECIPE )
        }
        
        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel, handler: nil )
        
        alert.addAction( standardAction )
        alert.addAction( formulaAction  )
        alert.addAction( cancelAction   )
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            
            if let popoverController = alert.popoverPresentationController {
                popoverController.barButtonItem = barButtonItem
            }

        }
        
        present( alert, animated: true, completion: nil )
    }
    
    
}



// MARK: ChefbookCentralDelegate Methods

extension RecipeListViewController: ChefbookCentralDelegate {
    
    func chefbookCentral( chefbookCentral: ChefbookCentral,
                          didOpenDatabase: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didOpenDatabase ) )
        
        if didOpenDatabase {
            chefbookCentral.fetchRecipes()
        }
        else {
            presentAlert( title:   NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                          message: NSLocalizedString( "AlertMessage.CannotOpenDatabase", comment: "Fatal Error!  Cannot open database.  Please delete and re-install the app." ) )
        }
        
    }
    
    
    func chefbookCentralDidReloadProvisionArray(chefbookCentral: ChefbookCentral) {
        logVerbose( "loaded [ %d ] provisions", chefbookCentral.provisionArray.count )

        myTableView.reloadData()
    }
    
    
    func chefbookCentralDidReloadRecipeArray( chefbookCentral: ChefbookCentral ) {
        
        logVerbose( "loaded [ %d ] recipes", chefbookCentral.recipeArray.count )
        chefbookCentral.fetchProvisions()
    }
    
    
    

}



// MARK: UITableViewDataSource Methods

extension RecipeListViewController: UITableViewDataSource {
    
    func tableView(_ tableView                     : UITableView,
                     numberOfRowsInSection section : Int) -> Int {
        
        let     numberOfRows = ChefbookCentral.sharedInstance.recipeArray.count
        
//        logVerbose( "[ %d ]", numberOfRows )
        return numberOfRows
    }
    
    
    func tableView(_ tableView              : UITableView,
                     cellForRowAt indexPath : IndexPath) -> UITableViewCell {
        
        let         cell                     = tableView.dequeueReusableCell(withIdentifier: CELL_ID, for: indexPath )
        let         imageView:   UIImageView = cell.viewWithTag( CELL_TAG_IMAGE_VIEW   ) as! UIImageView
        let         nameLabel:   UILabel     = cell.viewWithTag( CELL_TAG_LABEL_NAME   ) as! UILabel
        let         recipe:      Recipe      = ChefbookCentral.sharedInstance.recipeArray[indexPath.row]

        
        nameLabel.text  = recipe.name
        imageView.image = nil
        
        if let imageName = recipe.imageName {
            
            if !imageName.isEmpty {
                imageView.image = ChefbookCentral.sharedInstance.imageWith( imageName )
            }
            
        }
        
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
            
            logVerbose( "delete recipe at row [ %d ]", indexPath.row )
            if UIDevice.current.userInterfaceIdiom == .pad {
                
                let detailNavigationViewController = ( ( (self.splitViewController?.viewControllers.count)! > 1 ) ? self.splitViewController?.viewControllers[1] : nil ) as? UINavigationController
                
                detailNavigationViewController?.viewControllers = []
            }
            
            DispatchQueue.main.asyncAfter(deadline: ( .now() + 0.2 ), execute: {
                ChefbookCentral.sharedInstance.deleteRecipeAtIndex( indexPath.row )
            })

        }
        
    }
    

}



// MARK: UITableViewDelegate Methods

extension RecipeListViewController: UITableViewDelegate
{
    func tableView(_ tableView                : UITableView,
                     didSelectRowAt indexPath : IndexPath ) {
        
        logVerbose( "[ %d ]", indexPath.row )
        tableView.deselectRow( at: indexPath, animated: false )
        
        if ChefbookCentral.sharedInstance.recipeArray[indexPath.row].isFormulaType {
            launchFormulaEditorFor( indexPath.row )
        }
        else {
            launchRecipeEditorFor( indexPath.row )
        }

    }
    
    
}


