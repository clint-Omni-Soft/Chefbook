//
//  TabBarViewController.swift
//  Chefbook
//
//  Created by Clint Shank on 8/16/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//


import UIKit



class TabBarViewController: UITabBarController,
                            ChefbookCentralDelegate
{

    override func viewDidLoad()
    {
        logTrace()
        super.viewDidLoad()

        tabBar.items![0].title = NSLocalizedString( "Title.RecipeList", comment: "Recipes"  )
        tabBar.items![1].title = NSLocalizedString( "Title.Settings",   comment: "Settings" )
        
        
        let     chefbookCentral = ChefbookCentral.sharedInstance
        
        
        if !chefbookCentral.didOpenDatabase
        {
            chefbookCentral.delegate = self
            chefbookCentral.openDatabase()
        }
        
    }
    
    
    override func viewWillAppear(_ animated: Bool)
    {
        logTrace()
        super.viewWillAppear( animated )
    }
    
    
    override func didReceiveMemoryWarning()
    {
        logTrace( "MEMORY WARNING!!!" )
        super.didReceiveMemoryWarning()
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
        
        if UIDevice.current.userInterfaceIdiom == .pad
        {
            loadExampleRecipeOnFirstTimeIn()
        }
        
    }
    
    

    // MARK: Utility Methods

    private func loadExampleRecipeOnFirstTimeIn()
    {
        let userDefaults = UserDefaults.standard
        let dirtyFlag    = userDefaults.bool( forKey: "Dirty" )
        
        logVerbose( "dirtyFlag[ %@ ]", stringFor( dirtyFlag ) )
        
        if !dirtyFlag
        {
            userDefaults.set( true, forKey: "Dirty" )
            let chefbookCentral = ChefbookCentral.sharedInstance
            
            if chefbookCentral.recipeArray.count == 0
            {
                chefbookCentral.addRecipe( name: "Example Recipe",
                                           imageName: "",
                                           ingredients: "1 lb. Bacon\n4 oz grated Parmesan",
                                           steps: "Fry until crispy\nDrain on paper towels\nSprinkle with Parmesan",
                                           yield: "12 strips",
                                           yieldOptions: "1x" )
            }
            
        }
        
    }
    

}
