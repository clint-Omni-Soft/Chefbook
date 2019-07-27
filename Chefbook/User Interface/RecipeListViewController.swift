//
//  RecipeListViewController.swift
//  Chefbook
//
//  Created by Clint Shank on 7/26/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit

class RecipeListViewController: UIViewController,
                                ChefbookCentralDelegate,
                                RecipeEditorViewControllerDelegate
{
    
    let     CELL_ID                     = "RecipeListViewControllerCell"
    let     CELL_TAG_LABEL_NAME         = 11
    let     CELL_TAG_IMAGE_VIEW         = 12
    let     STORYBOARD_ID_RECIPE_EDITOR = "RecipeEditorViewController"
    

    @IBOutlet weak var myTableView: UITableView!
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        logTrace()
        
        title = NSLocalizedString( "Title.RecipeList", comment: "Recipe List" )
    }
    

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear( animated )
        logTrace()


        let     chefbookCentral = ChefbookCentral.sharedInstance
        
        
        chefbookCentral.delegate = self
        
        if !chefbookCentral.didOpenDatabase
        {
            chefbookCentral.openDatabase()
        }
        else
        {
            myTableView.reloadData()
        }
        
        loadBarButtonItems()
        
        NotificationCenter.default.addObserver( self,
                                                selector: #selector( RecipeListViewController.recipesUpdated( notification: ) ),
                                                name:     NSNotification.Name( rawValue: NOTIFICATION_RECIPES_UPDATED ),
                                                object:   nil )
    }
    
    
    override func viewWillDisappear(_ animated: Bool)
    {
        logTrace()
        super.viewWillDisappear( animated )
        
        NotificationCenter.default.removeObserver( self )
    }
    
    
    override func didReceiveMemoryWarning()
    {
        logTrace( "WARNING!" )
    }
    
    
    
    // MARK: NSNotification Methods
    
    @objc func recipesUpdated( notification: NSNotification )
    {
        logTrace()
        
        // The reason we are using Notifications is because this view can be up in two different places on the iPad at the same time.
        // This approach allows a change in one to immediately be reflected in the other.
        
        myTableView.reloadData()
    }
    
    
    
    // MARK: ChefbookCentralDelegate Methods
    
    func chefbookCentral( chefbookCentral: ChefbookCentral,
                          didOpenDatabase: Bool )
    {
        logVerbose( "[ %@ ]", stringFor( didOpenDatabase ) )
        if didOpenDatabase
        {
            chefbookCentral.fetchRecipes()
        }
        else
        {
            presentAlert( title:   NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                          message: NSLocalizedString( "AlertMessage.CannotOpenDatabase", comment: "Fatal Error!  Cannot open database." ) )
        }
        
    }
    
    
    func chefbookCentralDidReloadRecipeArray( chefbookCentral: ChefbookCentral )
    {
        logVerbose( "loaded [ %d ] recipes", chefbookCentral.recipeArray.count )
        myTableView.reloadData()
    }

    
    
    // MARK: RecipeEditorViewControllerDelegate Methods
    
    func recipeEditorViewController( recipeEditorViewController: RecipeEditorViewController,
                                     didEditRecipe: Bool)
    {
        logVerbose( "didEditRecipe[ %@ ]", stringFor( didEditRecipe ) )
        recipeEditorViewController.delegate = self
        
        if didEditRecipe
        {
            myTableView.reloadData()
        }

    }
    
    
    
    // MARK: Target / Action Methods
    
    @IBAction @objc func addBarButtonItemTouched( barButtonItem: UIBarButtonItem )
    {
        logTrace()
        launchEditorForRecipeAt( index: NEW_RECIPE )
    }

    
    
    // MARK: Utility Methods
    
    private func loadBarButtonItems()
    {
        logTrace()
        let     addBarButtonItem  = UIBarButtonItem.init( barButtonSystemItem: .add,
                                                          target: self,
                                                          action: #selector( addBarButtonItemTouched ) )
        
        navigationItem.rightBarButtonItem = addBarButtonItem
    }
    
}


extension RecipeListViewController: UITableViewDataSource
{
    func tableView(_ tableView: UITableView,
                     numberOfRowsInSection section: Int) -> Int
    {
        let     numberOfRows = ChefbookCentral.sharedInstance.recipeArray.count
        
        logVerbose( "[ %d ]", numberOfRows )
        return numberOfRows
    }
    
    
    func tableView(_ tableView: UITableView,
                     cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let         cell                     = tableView.dequeueReusableCell(withIdentifier: CELL_ID, for: indexPath )
        let         imageView:   UIImageView = cell.viewWithTag( CELL_TAG_IMAGE_VIEW   ) as! UIImageView
        let         nameLabel:   UILabel     = cell.viewWithTag( CELL_TAG_LABEL_NAME   ) as! UILabel
        let         recipe:      Recipe      = ChefbookCentral.sharedInstance.recipeArray[indexPath.row]

        
        nameLabel.text  = recipe.name
        imageView.image = nil
        
        if let imageName = recipe.imageName
        {
            if !imageName.isEmpty
            {
                imageView.image = ChefbookCentral.sharedInstance.imageWith( name: imageName )
            }
            
        }
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView,
                     canEditRowAt indexPath: IndexPath) -> Bool
    {
        return true
    }
    
    
    func tableView(_ tableView: UITableView,
                     commit editingStyle: UITableViewCell.EditingStyle,
                     forRowAt indexPath: IndexPath)
    {
        if editingStyle == .delete
        {
            logVerbose( "delete recipe at row [ %d ]", indexPath.row )
            ChefbookCentral.sharedInstance.deleteRecipeAtIndex( index: indexPath.row )
        }
        
    }
    
}


extension RecipeListViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        logVerbose( "[ %d ]", indexPath.row )
        tableView.deselectRow(at: indexPath, animated: false )
        
        launchEditorForRecipeAt( index: indexPath.row )

    }
    
    
    
    
    // MARK: Utility Methods
    
    private func launchEditorForRecipeAt( index: Int )
    {
        logVerbose( "[ %d ]", index )
        if let recipeEditorVC: RecipeEditorViewController = iPhoneViewControllerWithStoryboardId( storyboardId: STORYBOARD_ID_RECIPE_EDITOR ) as? RecipeEditorViewController
        {
            recipeEditorVC.delegate                = self
            recipeEditorVC.indexOfItemBeingEdited  = index
            recipeEditorVC.launchedFromDetailView = false

            navigationController?.pushViewController( recipeEditorVC, animated: true )
        }
        else
        {
            logTrace( "ERROR: Could NOT load RecipeEditorViewController!" )
        }
        
    }
    
    
}


